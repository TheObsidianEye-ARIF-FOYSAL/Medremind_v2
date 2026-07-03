const {onCall, HttpsError} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const bcrypt = require('bcryptjs');

admin.initializeApp();
const db = admin.firestore();

// Mirrors AuthService._normalize in lib/features/auth/services/auth_service.dart
// so the phone doc ID is consistent between the BDApps OTP step and Firestore.
function normalizePhone(phone) {
  const digits = String(phone || '').replace(/[^0-9]/g, '');
  if (digits.startsWith('880') && digits.length > 10) return digits.slice(3);
  if (digits.startsWith('88') && digits.length > 11) return digits.slice(2);
  return digits;
}

function requirePhone(phone) {
  const normalized = normalizePhone(phone);
  if (normalized.length !== 11) {
    throw new HttpsError('invalid-argument', 'Enter a valid 11-digit phone number');
  }
  return normalized;
}

exports.checkPhoneExists = onCall(async (request) => {
  const phone = requirePhone(request.data?.phone);
  const doc = await db.collection('users').doc(phone).get();
  return {exists: doc.exists};
});

exports.registerUser = onCall(async (request) => {
  const phone = requirePhone(request.data?.phone);
  const name = String(request.data?.name || '').trim();
  const password = String(request.data?.password || '');

  if (!name) throw new HttpsError('invalid-argument', 'Name is required');
  if (password.length < 6) {
    throw new HttpsError('invalid-argument', 'Password must be at least 6 characters');
  }

  const ref = db.collection('users').doc(phone);
  const existing = await ref.get();
  if (existing.exists) {
    throw new HttpsError('already-exists', 'This phone number is already registered');
  }

  const passwordHash = await bcrypt.hash(password, 10);
  await ref.set({
    phone,
    name,
    passwordHash,
    subscriptionStatus: 'inactive',
    subscriptionExpiry: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const token = await admin.auth().createCustomToken(phone);
  return {token};
});

exports.loginUser = onCall(async (request) => {
  const phone = requirePhone(request.data?.phone);
  const password = String(request.data?.password || '');

  const ref = db.collection('users').doc(phone);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError('not-found', 'No account found for this phone number');
  }

  const data = snap.data();
  const match = await bcrypt.compare(password, data.passwordHash || '');
  if (!match) {
    throw new HttpsError('permission-denied', 'Incorrect password');
  }

  const token = await admin.auth().createCustomToken(phone);
  return {token};
});
