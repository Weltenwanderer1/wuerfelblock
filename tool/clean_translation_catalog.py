#!/usr/bin/env python3
"""Remove conservative, provably internal entries from the runtime catalog."""

import json
import pathlib
import re

ROOT = pathlib.Path(__file__).parents[1]
SOURCE = ROOT / "tool" / "translations_en.json"
catalog = json.loads(SOURCE.read_text(encoding="utf-8"))
darts = list((ROOT / "lib").rglob("*.dart"))
darts += list((ROOT / "test").rglob("*.dart"))
texts = [path.read_text(encoding="utf-8") for path in darts]

internal: set[str] = set()
quoted = r"""(['"])(.*?)\1"""

for text in texts:
    pattern = (
        r"\b(?:Key|ValueKey|PageStorageKey)"
        r"\s*(?:<[^>]+>)?\s*\(\s*(?:r)?" + quoted
    )
    internal.update(match.group(2) for match in re.finditer(pattern, text, re.S))

    internal.update(
        match.group(2)
        for match in re.finditer(
            r"""\bjson\s*\[\s*(['"])(.*?)\1\s*\]""", text
        )
    )

    for match in re.finditer(
        r"\b_requireExactKeys\s*\(\s*json\s*,\s*const\s*\{(.*?)\}\s*\)",
        text,
        re.S,
    ):
        internal.update(
            item.group(2) for item in re.finditer(quoted, match.group(1))
        )

    internal.update(
        match.group(2)
        for match in re.finditer(
            r"""\b(?:key|preferenceKey)\s*=\s*(['"])(.*?)\1""", text
        )
    )
    internal.update(
        match.group(3)
        for match in re.finditer(
            r"""(['"])type\1\s*:\s*(['"])(.*?)\2""", text
        )
    )

    for match in re.finditer(r"\benum\s+\w+\s*\{([^}]*)\}", text, re.S):
        body = re.sub(r"//.*|/\*.*?\*/", "", match.group(1), flags=re.S)
        internal.update(
            re.findall(r"(?:^|,)\s*([a-z]\w*)\s*(?=\(|,|$)", body)
        )

placeholder = re.compile(r"\$\{[^}]+\}|\$[A-Za-z_]\w*")
remove: set[str] = set()
for key in catalog:
    if key in internal or ".dart" in key or key.startswith("package:"):
        remove.add(key)
        continue
    if "$" in key and len(placeholder.sub("", key)) < 3:
        remove.add(key)
        continue
    broken = "$" in key and key.count("${") != key.count("}")
    broken |= bool(
        "\n" in key
        and re.search(r"\?|\b(?:if|catch|setState)\b|[;{}]", key)
    )
    broken |= bool(re.match(r"^\s*[})].*(?:;|\$)", key, re.S))
    if broken:
        remove.add(key)

cleaned = {key: catalog[key] for key in sorted(catalog) if key not in remove}
SOURCE.write_text(
    json.dumps(cleaned, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
print(f"Removed {len(remove)} internal catalog entries.")
