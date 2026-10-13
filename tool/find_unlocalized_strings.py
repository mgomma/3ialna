"""Finds user-facing English string literals that are not localized.

Skips strings passed to the local _text('English', 'Arabic') helper, which is
already bilingual, plus imports, asset paths, and map keys.
"""
import re
import pathlib
import sys

ROOT = pathlib.Path("lib/presentation")
# Literals that are identifiers, keys, or plumbing rather than visible copy.
IGNORE_EXACT = {
    "cancel", "manual", "google", "facebook", "apple", "ar", "en",
}
IGNORE_SUBSTR = (
    "package:", "assets/", "dart:", "http", "/", ".dart", "_", "{", "}",
)

literal = re.compile(r"'((?:[^'\\]|\\.)*)'")
# _text('...', '...') and text('...', '...') are the bilingual helpers.
bilingual = re.compile(r"\b_?text\(\s*'(?:[^'\\]|\\.)*'\s*,\s*'(?:[^'\\]|\\.)*'\s*\)")
# isArabic ? 'عربي' : 'English' is also bilingual, and may span lines.
ternary = re.compile(
    r"\?\s*'((?:[^'\\]|\\.)*)'\s*:\s*'((?:[^'\\]|\\.)*)'", re.DOTALL
)
has_words = re.compile(r"[A-Za-z]{3,}")
arabic = re.compile(r"[\u0600-\u06FF]")


def mask(match):
    """Blank a bilingual pair so its English half is not reported."""
    text = match.group(0)
    if arabic.search(text):
        return "".join(" " if c != "\n" else "\n" for c in text)
    return text


findings = []
for path in sorted(ROOT.rglob("*.dart")):
    src = path.read_text(encoding="utf-8")
    masked = bilingual.sub(lambda m: mask(m) if arabic.search(m.group(0)) else m.group(0), src)
    masked = bilingual.sub(lambda m: "".join(" " if c != "\n" else "\n" for c in m.group(0)), masked)
    masked = ternary.sub(mask, masked)
    for lineno, line in enumerate(masked.splitlines(), 1):
        stripped = line.strip()
        if stripped.startswith(("import ", "export ", "//", "///")):
            continue
        for match in literal.finditer(line):
            value = match.group(1)
            if not has_words.search(value):
                continue
            if arabic.search(value):
                continue
            if value.lower() in IGNORE_EXACT:
                continue
            if any(tok in value for tok in IGNORE_SUBSTR):
                continue
            if len(value) < 4:
                continue
            findings.append((str(path), lineno, value))

for path, lineno, value in findings:
    print(f"{path}:{lineno}: {value!r}")
print(f"\nTOTAL: {len(findings)}")

# A file with English copy but no Arabic anywhere and no l10n lookup is
# definitely unlocalized, rather than using one of the inline bilingual styles.
print("\n=== FILES WITH NO ARABIC AND NO l10n (definitely unlocalized) ===")
definite = 0
by_file = {}
for path, lineno, value in findings:
    by_file.setdefault(path, []).append((lineno, value))
for path, items in sorted(by_file.items()):
    src = pathlib.Path(path).read_text(encoding="utf-8")
    if arabic.search(src) or "l10n" in src:
        continue
    definite += len(items)
    print(f"\n{path}  ({len(items)} strings)")
    for lineno, value in items[:8]:
        print(f"  {lineno}: {value!r}")
print(f"\nDEFINITELY UNLOCALIZED: {definite}")
sys.exit(1 if definite else 0)
