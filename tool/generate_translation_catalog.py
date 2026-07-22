#!/usr/bin/env python3
"""Generate the Dart runtime catalog from the reviewed offline JSON source."""

import json
import pathlib
import re

ROOT = pathlib.Path(__file__).parents[1]
SOURCE = ROOT / "tool" / "translations_en.json"
OUTPUT = ROOT / "lib" / "l10n" / "translations.g.dart"
PLACEHOLDER = re.compile(r"\$\{[^}]+\}|\$[A-Za-z_]\w*")

catalog = json.loads(SOURCE.read_text(encoding="utf-8"))
if not isinstance(catalog, dict) or not catalog:
    raise SystemExit("translation catalog must be a non-empty JSON object")

for source, target in catalog.items():
    if not isinstance(source, str) or not isinstance(target, str):
        raise SystemExit("translation keys and values must be strings")
    if not source or not target:
        raise SystemExit(f"empty translation: {source!r}")
    source_placeholders = PLACEHOLDER.findall(source)
    target_placeholders = PLACEHOLDER.findall(target)
    missing = set(source_placeholders) - set(target_placeholders)
    if missing:
        raise SystemExit(
            f"translation drops placeholders {sorted(missing)!r}: {source!r}"
        )

payload = json.dumps(
    catalog,
    ensure_ascii=False,
    separators=(",", ":"),
    sort_keys=True,
)
OUTPUT.write_text(
    "// Generated from tool/translations_en.json. Do not edit by hand.\n"
    "import 'dart:convert';\n\n"
    "final Map<String, String> englishCatalog =\n"
    "    (jsonDecode(_catalogJson) as Map<String, dynamic>).cast<String, String>();\n\n"
    "const _catalogJson =\n"
    "    r'''" + payload + "''';\n",
    encoding="utf-8",
)
print(f"Generated {len(catalog)} reviewed translations.")
