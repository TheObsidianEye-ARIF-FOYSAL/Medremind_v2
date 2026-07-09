# BDApps Server Integration

This is a language-agnostic writeup of how MedRemind's server talks to
BDApps (Robi/Airtel's direct-carrier-billing + SMS platform at
`developer.bdapps.com`). Read this and you can rebuild the server side in
any language — Node, Python, Go, whatever — without needing to read the PHP.

The current implementation is PHP (`server/medremind_*.php`), one file per
endpoint, plain `curl`/JSON, no framework. That choice isn't load-bearing —
none of what follows depends on PHP specifically.

---

## 1. Credentials

Every BDApps call sends the same two fields, application-wide:

```json
{
  "applicationId": "APP_138840",
  "password": "REDACTED_BDAPPS_API_KEY"
}
```

- `applicationId` identifies which registered BDApps application is calling.
- `password` is the API key BDApps issues when they approve that application.
- These are **not per-user** — every request to BDApps (OTP, subscribe,
  unsubscribe, SMS) includes the same pair.
- BDApps approves applications in two stages:
  1. **Testing** — the app can only interact with a handful of phone numbers
     BDApps has explicitly whitelisted for you. Any other number is rejected
     outright (independent of anything in your code).
  2. **Active Production** — request this via email to `support@bdapps.com`
     once testing looks good; after that, any real number works.
- A subscriber's registration/subscription state is tracked by BDApps
  **per `applicationId`**. The same phone number can simultaneously be
  "subscribed" under one `applicationId` and "not registered" under another —
  switching which app id you send doesn't carry state over.

---

## 2. Phone number format

BDApps wants Bangladeshi numbers as `tel:88XXXXXXXXXXX` — i.e. the local
11-digit number (`01897776680`), prefixed with `tel:88`.

Two normalization rules to keep numbers consistent through the whole system:

- **To BDApps**: always `"tel:88" + elevenDigitLocalNumber"`.
- **Internally** (your own DB primary key, session lookups, etc.): store the
  bare 11-digit local number (`01897776680`), stripped of any `88`/`880`/`tel:`
  prefix. Every endpoint that accepts a phone number from the client should
  run it through the same normalize function before touching the DB or
  calling BDApps, or lookups will silently miss.

```
normalize("+8801897776680") -> "01897776680"
normalize("8801897776680")  -> "01897776680"
normalize("01897776680")    -> "01897776680"
```

---

## 3. Endpoints used

All requests are `POST` with `Content-Type: application/json`, body is the
JSON object shown, response is JSON. Base host: `https://developer.bdapps.com`.

### 3.1 `POST /subscription/otp/request` — send an OTP

Used during registration to prove the user owns the phone number (and, as a
side effect, subscribes them to your BDApps app for carrier billing).

Request:
```json
{
  "applicationId": "APP_138840",
  "password": "...",
  "subscriberId": "tel:8801897776680",
  "applicationHash": "MedRee",
  "applicationMetaData": {
    "client": "MOBILEAPP",
    "device": "Android",
    "os": "android",
    "appCode": "MedRee"
  }
}
```

Success response includes a `referenceNo` — hold onto it, you send it back
in the verify call:
```json
{ "referenceNo": "123456789", "statusCode": "S1000", "statusDetail": "..." }
```

Failure response (no `referenceNo`, or a non-success `statusCode`):
```json
{ "statusCode": "E1351", "statusDetail": "Already Registered" }
```

**Important status codes:**
| Code | Meaning |
|---|---|
| `S1000` | Success — OTP sent, or the accompanying action succeeded |
| `E1351` | subscriberId is **already subscribed** to this `applicationId` — BDApps will not send a new OTP. This is the normal outcome for a whitelisted test number that's already gone through a subscribe cycle. Your server should treat this as "already verified" and skip straight past the OTP step rather than surfacing it as an error. |
| (others) | Treat as a genuine failure; surface `statusDetail` to the user/logs |

### 3.2 `POST /subscription/otp/verify` — verify the OTP the user typed

```json
{
  "applicationId": "APP_138840",
  "password": "...",
  "referenceNo": "123456789",
  "otp": "482913"
}
```

Response:
```json
{ "subscriptionStatus": "REGISTERED", "statusCode": "S1000" }
```

Accept as "verified" if `subscriptionStatus` (uppercased, underscores→spaces)
is one of: `REGISTERED`, `SUBSCRIBED`, `ACTIVE`, `S1000`,
`INITIAL CHARGING PENDING`, `PENDING INITIAL CHARGING` — or if `statusCode`
is `S1000`. Anything else = invalid/expired OTP, let the user retry.

### 3.3 `POST /subscription/send` — subscribe / unsubscribe

Same endpoint for both directions, distinguished by `action`:

```json
{
  "applicationId": "APP_138840",
  "password": "...",
  "version": "1.0",
  "action": "0",
  "subscriberId": "tel:8801897776680"
}
```

- `action: "1"` = subscribe
- `action: "0"` = unsubscribe (opt-out)

Response on success: `statusCode: "S1000"`, and usually
`subscriptionStatus: "UNREGISTERED"` for an unsubscribe.

**Important status codes:**
| Code | Meaning |
|---|---|
| `S1000` | Success |
| `E1356` | subscriberId is **not registered** under this `applicationId` — you tried to unsubscribe someone who was never (or no longer) subscribed under that app id. Check you're using the right `applicationId` for this subscriber before assuming this is a bug. |
| (no code, `statusDetail` contains "Format of the address is invalid or User Already UnRegistered") | An ambiguous message BDApps returns for `action: "0"` when the subscriberId is **already unregistered**. In practice this means the end state you wanted is already true — treat it as success (delete the local row / clear the session) rather than surfacing it as a failure. |

### 3.4 `POST /sms/send` — send a plain SMS

Used both for a one-off welcome message and (in principle) for any
custom-text SMS you want to send outside the OTP flow.

```json
{
  "applicationId": "APP_138840",
  "password": "...",
  "message": "Thanks for subscribing!",
  "destinationAddresses": ["tel:8801897776680"]
}
```

`destinationAddresses` is always an array, even for one recipient.

### 3.5 `GET/POST /subscription/getstatus` — check subscription status

```json
{
  "applicationId": "APP_138840",
  "password": "...",
  "subscriberId": "tel:8801897776680"
}
```

Response includes `subscriptionStatus` (e.g. `REGISTERED`, `UNREGISTERED`).
Not currently wired into any MedRemind endpoint, but useful for diagnosing
"is this number actually subscribed under this app id right now" without
side effects.

### 3.6 Inbound webhook: subscription status callback

BDApps calls **your** server (not the other way around) when a subscriber's
status changes — e.g. after a successful OTP subscribe completes billing
setup. Your endpoint receives:

```json
{
  "status": "REGISTERED",
  "subscriberId": "tel:8801897776680",
  "applicationId": "APP_138840",
  "timeStamp": "..."
}
```

Typical handling: if `status == "REGISTERED"`, send a welcome SMS via 3.4.
This URL has to be registered with BDApps when the app is set up (not
something your code controls at request time).

---

## 4. Server-side pieces that are NOT BDApps calls

These live entirely in your own database and never touch BDApps directly:

- **Phone existence check** — does a row for this phone already exist.
- **Register** — after OTP verify succeeds client-side, create the user row
  (hashed password, initial subscription bookkeeping, issue a session token).
- **Login** — verify password hash, issue a fresh session token.
- **Session-gated endpoints** (profile fetch, change password, unsubscribe,
  ...) — require `phone` + `token` matching the stored `session_token` for
  that phone. Simple opaque random token (32 bytes, hex), no JWT/expiry
  logic beyond "rotate on password change".
- **Unsubscribe flow** specifically: call BDApps `action:"0"` (3.3) *first*;
  only delete the local user row if BDApps confirms (`S1000` or
  `subscriptionStatus: UNREGISTERED`). Never delete locally on a BDApps
  failure — that would desync your DB from the carrier's billing state.

---

## 5. Minimal request/response flow for registration (P1)

```
Client                         Your Server                      BDApps
  │  POST /send_otp {phone}       │                                │
  ├───────────────────────────────>│                                │
  │                                │  POST /subscription/otp/request│
  │                                ├───────────────────────────────>│
  │                                │<───────────────────────────────┤
  │                                │  { referenceNo } or E1351      │
  │  { referenceNo } or             │                                │
  │  { alreadyRegistered: true }   │                                │
  │<───────────────────────────────┤                                │
  │                                │                                │
  │  [user types OTP]              │                                │
  │  POST /verify_otp {otp, ref}   │                                │
  ├───────────────────────────────>│                                │
  │                                │  POST /subscription/otp/verify │
  │                                ├───────────────────────────────>│
  │                                │<───────────────────────────────┤
  │                                │  { subscriptionStatus }        │
  │  { verified: true/false }      │                                │
  │<───────────────────────────────┤                                │
  │                                │                                │
  │  POST /register {phone,name,pw}│                                │
  ├───────────────────────────────>│  (no BDApps call — local DB    │
  │  { token, ...user }            │   insert + session token)      │
  │<───────────────────────────────┤                                │
```

If the first response carries `alreadyRegistered: true` (E1351), the client
skips the OTP-entry step entirely and calls `/register` directly.

---

## 6. Gotchas worth remembering

- **`applicationId` scoping**: switching credentials on an existing,
  already-registered user's phone number does not carry their subscription
  state over. If you rotate which BDApps app id you use, treat every
  existing subscriber as unknown to the new app id until they go through
  subscribe/unsubscribe again under it.
- **E1351 is not a bug** — for testing-phase apps, BDApps pre-subscribes
  their whitelisted numbers, so `otp/request` will never issue a fresh code
  for them. This is expected, not something to "fix" by retrying.
- **Testing-phase numbers only** — until "Active Production" is granted,
  only BDApps' whitelisted numbers will get any response other than a
  rejection, regardless of what the code does.
- **Silent failure trap**: don't discard BDApps' `statusCode`/`statusDetail`
  on error paths — always propagate them (at least into your own logs, ideally
  to the client) so failures are diagnosable instead of showing a generic
  "unable to process" message.
