#!/usr/bin/env python3
"""Regenera docs/api.md juntando los READMEs de docs/ en un solo archivo.

Reglas:
  - Conserva la cabecera de api.md hasta el primer heading nivel 2
    del README-lib.md (por defecto "## Núcleo gráfico").
  - Concatena los 6 READMEs, cada uno envuelto en un heading nivel 2
    con su nombre.
  - Demota un nivel los headings internos de cada README (## -> ###,
    ### -> ####, etc). No toca headings dentro de bloques de código.

Uso:
  python3 tools/update-api-docs.py
"""

import os
import re
import sys

DOCS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs")
DOCS = os.path.normpath(DOCS)

READMES = [
    "README-lib.md",
    "README-widgets.md",
    "README-bar.md",
    "README-data.md",
    "README-tabs.md",
    "README-helpers.md",
]

CUT_MARKER = "## Núcleo gráfico"


def demote(md):
    out = []
    in_code = False
    for line in md.splitlines():
        if line.startswith("```"):
            in_code = not in_code
            out.append(line)
            continue
        if not in_code:
            m = re.match(r"^(#{1,5}) (.*)$", line)
            if m:
                line = "#" + m.group(1) + " " + m.group(2)
        out.append(line)
    return "\n".join(out)


def main():
    api_path = os.path.join(DOCS, "api.md")

    with open(api_path, "r") as f:
        api = f.read()

    cut = api.find(CUT_MARKER)
    if cut < 0:
        print("update-api-docs: no encontre '%s' en api.md" % CUT_MARKER,
              file=sys.stderr)
        return 1

    header = api[:cut].rstrip() + "\n\n"

    parts = [header]
    for name in READMES:
        path = os.path.join(DOCS, name)
        if not os.path.isfile(path):
            print("update-api-docs: falta %s" % path, file=sys.stderr)
            return 1
        with open(path, "r") as f:
            content = f.read()
        parts.append("## " + name + "\n\n" + demote(content).rstrip() + "\n\n")

    result = "".join(parts).rstrip() + "\n"

    with open(api_path, "w") as f:
        f.write(result)

    print("update-api-docs: api.md regenerado (%d bytes)" % len(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
