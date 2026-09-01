# Security Policy

*[Leer esto en español](SECURITY.md)*

## Project scope

`AMSTRAD_OhMummy` is a reverse engineering, documentation and
preservation project — not a production service. There is no server,
no user accounts, no database, and no personal data is processed. The
repository's content falls into three categories:

- **Z80 assembler source** (`src/*.asm`, not yet created), meant to be
  compiled with `sjasmplus` and run in an Amstrad CPC emulator (or a
  real CPC) — never on the computer that compiles it.
- **Python tools** (`tools/*.py`) that read/generate local binary
  files (`.bin`, `.dsk`) from other local files in the repository
  itself.
- **Self-contained HTML pages** (`recursos/*.html`, not yet created)
  that open directly in the browser, with no backend or network
  calls — all the data they display is embedded in the file itself.

Given this scope, most classic web vulnerability categories (SQL
injection, XSS with remote data, session management, etc.) do not
apply. What does make sense to report:

- A script in `tools/` that, when processing a deliberately
  manipulated input file (a corrupted or malicious `.dsk`/`.bin`),
  writes outside the expected directory, overwrites arbitrary files,
  or has any other unsafe behavior beyond failing with a controlled
  error.
- Any HTML file in `recursos/` that, against its current design
  (self-contained, no network), ends up loading or executing content
  from an untrusted external source.
- Any credential, token, or sensitive data that appears by mistake in
  the repository's history.

## What is NOT a vulnerability in this project

Given the project's own goal (byte-for-byte reconstruction of the
original 1984 disk binary, see `README.md`/`src/README.md`), the
assembler code will **deliberately** reproduce the original game's
behavior, including its historical bugs if any. A "weird" behavior in
the reconstructed game that matches the original **is not a security
issue**, it's historical fidelity. If in doubt whether something fits
this category, report it anyway and it will be clarified.

## Supported version

There are no published releases with differentiated support: only the
`main` branch is maintained, always with the latest state.

| Branch | Supported |
| --- | --- |
| `main` | :white_check_mark: |
| any fork/old branch | :x: |

## How to report an issue

- **For most cases** (the most likely scenario: a bug in a `tools/`
  script): open a normal Issue in this project's GitHub repository,
  just like any other bug — no need to treat it as something special,
  there are no users at risk here.
- **If you really prefer to report it privately** (for example, if you
  found a leaked credential in the history), write to
  <raemca@hotmail.com> with the details.

This is a personal project maintained by a single person in their
spare time: there is no SLA or bug bounty program, but every report is
reviewed and appreciated — especially from someone who took the time
to look at the code carefully.
