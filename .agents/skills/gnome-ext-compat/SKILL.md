---
name: gnome-ext-compat
description: Check GNOME Shell extension compatibility when a GNOME update or nix flake update is coming. Runs scripts/ext-status.sh to report, per installed extension, whether its declared shell-version covers the running shell AND the gnome-shell version pinned in flake.lock (nixpkgs), plus EGO and upstream-GitHub update availability. Use when the user mentions gnome updates, extension compatibility, flake update, "will my extensions break", or shell version checks.
---

# GNOME extension compatibility

Report which installed GNOME Shell extensions survive the next GNOME update
*before* rebuilding.

## How to run

```bash
bash scripts/ext-status.sh [path/to/flake.lock]
```

(Default `$HOME/.config/nixos-config/flake.lock`. Needs `jq`, `curl`,
`gnome-shell`; `nix eval` for the target version — degrades gracefully without.)

## What it reports

- **running** — `gnome-shell --version` of the live session
- **target** — gnome-shell version of the nixpkgs rev pinned in flake.lock,
  via `nix eval --raw github:nixos/nixpkgs/<rev>#gnome-shell.version`. This is
  what the next `nixos-rebuild switch` will ship, so results are valid
  immediately after `nix flake update`, before any rebuild.
- Per extension:
  - **NOW** — installed `metadata.json` `shell-version` vs. running major
  - **POST-REBUILD** — same list vs. target major (the critical column)
  - **EGO(update)** — published version supporting the target, from
    `extensions.gnome.org/extension-query/`:
    `vN` = a version supports the target, `none` = on EGO but nothing supports
    the target yet, `-` = not on EGO, `off` = offline
  - **GIT** — whether upstream `metadata.json` on the default branch (fetched
    via raw.githubusercontent.com using the extension's `url`) declares target
    support: `yes` / `no` / `-` (no GitHub URL, or the repo generates
    metadata.json at build time). Covers source-built extensions (paperwm,
    gradia-capture, bazaar-companion) that have no EGO entry.

Exit code 1 when any extension is BROKEN now or post-rebuild.

## Interpreting results

- `POST-REBUILD: BROKEN` + `EGO: vN` or `GIT: yes` → an update exists that
  supports the target: bump the extension (flake input or nixpkgs) before
  rebuilding.
- `POST-REBUILD: BROKEN` + `EGO: none` + `GIT: no/-` → nothing published
  supports the new shell yet. This config sets
  `org.gnome.shell disable-extension-version-validation = true` (dconf default
  in `modules/desktop/gnome-extensions.nix`), so the shell will load it anyway
  if it actually works — flag it for manual testing after the rebuild.
- `EGO: -` with `GIT: yes` on a non-custom extension → upstream fixed it but
  nixpkgs hasn't; mention the git state.
- Offline runs: local NOW/POST columns still work; EGO/GIT show `off`.

Present results as the script's table, then a short per-problem-extension
action list. Do not rebuild anything — this is a read-only report.
