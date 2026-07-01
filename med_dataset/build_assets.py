"""
One-time preprocessing script: converts the raw Kaggle CSV dataset
(medicine.csv, generic.csv) into compact JSON assets bundled with the app,
so the app can look up medicine info fully offline without any network call.

Run with: python build_assets.py
Outputs into ../assets/med_dataset/
"""
import csv
import html
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "..", "assets", "med_dataset")
os.makedirs(OUT_DIR, exist_ok=True)

TAG_RE = re.compile(r"<[^>]+>")
WS_RE = re.compile(r"[ \t\r\f\v]+")
NL_RE = re.compile(r"\n{3,}")


def clean_html(raw: str) -> str:
    if not raw:
        return ""
    text = raw.replace("<br>", "\n").replace("<br/>", "\n").replace("<br />", "\n")
    text = text.replace("</li>", "\n").replace("</p>", "\n\n").replace("</div>", "\n")
    text = TAG_RE.sub("", text)
    text = html.unescape(text)
    text = WS_RE.sub(" ", text)
    text = NL_RE.sub("\n\n", text)
    return text.strip()


def truncate(text: str, limit: int = 1200) -> str:
    if len(text) <= limit:
        return text
    cut = text[:limit].rsplit(" ", 1)[0]
    return cut + "…"


# ── 1. Load medicine.csv → brands.json ────────────────────────────────────────

brands = []
med_generics = set()
with open(os.path.join(HERE, "medicine.csv"), encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        brand = row["brand name"].strip()
        generic = row["generic"].strip()
        if not brand or not generic:
            continue
        med_generics.add(generic)
        brands.append([
            brand,
            generic,
            row.get("strength", "").strip(),
            row.get("dosage form", "").strip(),
            row.get("manufacturer", "").strip(),
        ])

with open(os.path.join(OUT_DIR, "brands.json"), "w", encoding="utf-8") as f:
    json.dump(brands, f, ensure_ascii=False, separators=(",", ":"))

print(f"brands.json: {len(brands)} brands, referencing {len(med_generics)} generics")

# ── 2. Load generic.csv → generics.json (only generics referenced by brands) ──

generics = {}
with open(os.path.join(HERE, "generic.csv"), encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        name = row["generic name"].strip()
        if name not in med_generics:
            continue
        generics[name] = {
            "c": row.get("drug class", "").strip(),
            "i": row.get("indication", "").strip(),
            "id": truncate(clean_html(row.get("indication description", ""))),
            "ph": truncate(clean_html(row.get("pharmacology description", ""))),
            "do": truncate(clean_html(row.get("dosage description", ""))),
            "se": truncate(clean_html(row.get("side effects description", ""))),
            "pr": truncate(clean_html(row.get("precautions description", ""))),
            "co": truncate(clean_html(row.get("contraindications description", ""))),
        }

with open(os.path.join(OUT_DIR, "generics.json"), "w", encoding="utf-8") as f:
    json.dump(generics, f, ensure_ascii=False, separators=(",", ":"))

print(f"generics.json: {len(generics)} generics")

missing = med_generics - set(generics.keys())
if missing:
    print(f"Generics referenced by brands but with no info found ({len(missing)}):")
    for m in sorted(missing)[:30]:
        print(" -", m)

sizes = {
    fn: os.path.getsize(os.path.join(OUT_DIR, fn))
    for fn in ("brands.json", "generics.json")
}
for fn, sz in sizes.items():
    print(f"{fn}: {sz / 1024:.1f} KB")
