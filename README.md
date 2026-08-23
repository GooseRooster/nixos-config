# nixos-config

Flake-based NixOS configuration for a Flatpak-first, bluefin-like GNOME desktop:

- **Desktop**: minimal [GNOME](https://www.gnome.org) (GDM, Wayland-only)
- **Apps**: declarative Flatpaks (see `modules/flatpak/`), GNOME core apps disabled
- **Shell extensions**: declaratively installed via `pkgs.gnomeExtensions`
- **Kernel**: [CachyOS](https://github.com/xddxdd/nix-cachyos-kernel) by default,
  with a per-host fallback to the plain nixpkgs kernel
- **Hardening**: moderate kernel/sudo/ssh hardening (`modules/core/hardening.nix`)
- **Maintenance**: automatic GC + store optimisation + fwupd

CLI/dev batteries live in a separate repo ([`nix-cli`](https://github.com/GooseRooster/nix-cli))
and are pulled in as a flake input.

## Layout

- `hosts/<name>/` — per-machine entrypoint (hostname, user, flatpaks, kernel, hardware)
- `flavors/` — high-level combos: `base`, `desktop`, `wsl` (stub)
- `modules/core/` — cross-flavor system modules (`system`, `kernel`, `perf`,
  `nix`, `users`, `hardening`, `maintenance`, `podman`, `secure-boot`)
- `modules/desktop/` — GNOME + audio/portal/keyring/power modules
- `modules/flatpak/` — declarative flatpaks, split into toggle-able sets
- `modules/extras/` — optional host extras (theming)
- `quadlets/` — example podman quadlet files (system + rootless user templates)

## Host vs flavor

A **host** selects a **flavor** and adds its own machine-specific extras:

- **flavor** = reusable system shape (`base` / `desktop` / `wsl`).
- **host** = hostname + hardware + user + which extras are enabled (flatpak
  sets, theming, kernel, etc).

`hosts/vm` and `hosts/home` both use the `desktop` flavor; only `home` enables
theming.

## Kernel selection

`modules/core/kernel.nix` exposes `modules.kernel.variant` (`cachyos` |
`latest` | `lts`) and `modules.kernel.cachyosFlavor`. Set per-host:

```nix
modules.kernel.variant = "latest";                      # plain nixpkgs kernel
modules.kernel.cachyosFlavor = "linuxPackages-cachyos-latest-zen4"; # tuned build
```

The CachyOS kernel comes from the `nix-cachyos-kernel` flake input (binary
cache configured in `modules/core/nix.nix`). When first enabling CachyOS on a
host, run a rebuild twice so the new substituter takes effect before the kernel
is fetched.

## Users are declarative

Users are declared per host via `modules/users.nix`. Set
`modules.users.primary = "gooze"` (or a per-host name) and the module creates a
normal user with the groups supplied by the flavor.

By default no password is declared — with `users.mutableUsers = true` (the
default) set it imperatively after first boot:

```sh
sudo passwd gooze
```

For testing (e.g. the VM, where you need to log in before you can `passwd`),
set a throwaway password that only applies while the account has none:

```nix
modules.users.initialPassword = "changeme";
```

## Flatpaks

Flatpaks are declarative and split into sets, so a host can include exactly what
it needs:

```nix
modules.flatpak.enable = true;
modules.flatpak.base.enable = true;        # essential desktop apps
modules.flatpak.gaming.enable = true;      # Steam, emulators, ...
modules.flatpak.multimedia.enable = true;  # Stremio, mpv
```

The sets live in `modules/flatpak/{base,gaming,multimedia}.nix`. To skip gaming
on a workstation host, just don't import `gaming.nix` (or set
`modules.flatpak.gaming.enable = false`).

Declarative installs are handled by [nix-flatpak](https://github.com/gmodena/nix-flatpak)
(nixpkgs removed its own `services.flatpak.packages` option). Application IDs
are installed from Flathub by default.

## GNOME Shell extensions

Extensions are installed declaratively in `modules/desktop/gnome-extensions.nix`
via `pkgs.gnomeExtensions`. They are *enabled* manually with the
`com.mattjakeman.ExtensionManager` flatpak (or `gnome-extensions enable <uuid>`).

Some extensions are pulled in as custom flakes if they are not available on EGO.


## Apply

```sh
sudo nixos-rebuild switch --flake .#vm
sudo nixos-rebuild switch --flake .#home
```

## Installing on the host (disko)

The disk layout is declarative (`hosts/home/disko.nix`): a single NVMe with an
ESP at `/boot` and a LUKS-encrypted btrfs root split into `@` (→ `/`), `@home`
(→ `/home`) and `@nix` (→ `/nix`) subvolumes, matching
`modules/core/snapper.nix`. Swap is `zramSwap`, so there's no swap partition.
The LUKS container is auto-unlocked by the TPM2 with a passphrase fallback (see
[Secure Boot & LUKS](#secure-boot--luks-tpm2) below).

### First install (host never installed before)

Boot the **graphical** NixOS ISO (GNOME — you want the browser for the GitHub
step below), connect to Wi-Fi, then enable flakes if the ISO doesn't:
`nix --extra-experimental-features 'nix-command flakes'`.

```sh
# 1) generate a hardware config (hardware only — disko supplies fileSystems),
#    and read the state version from the generated configuration.nix
nixos-generate-config --no-filesystems
#    → system.stateVersion in /etc/nixos/configuration.nix (e.g. "26.05")

# 2) create an ephemeral SSH key (dies with the live ISO — that's fine) and
#    add it to GitHub via the browser (Settings → SSH keys). No long PAT needed.
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub   # copy into github.com → add key
eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519

# 3) clone over SSH (the origin is already SSH)
git clone git@github.com:GooseRooster/nixos-config.git
cd nixos-config

# 4) find your disk's stable /dev/disk/by-id path
lsblk -o PATH,MODEL,SERIAL,SIZE

# 5) copy the hardware config in, set the disk device, confirm the state
#    version, then commit and push (SSH key auth — nothing to type)
cp /etc/nixos/hardware-configuration.nix hosts/home/hardware-configuration.nix
#    → set `device` in hosts/home/disko.nix
#    → set `system.stateVersion` in hosts/home/default.nix
git commit -am "home: hardware config + disk device"
git push

# 6) one-shot install: partition + format + mount + nixos-install + bootloader,
#    from the pushed flake (NOT the local clone). LUKS prompts for its passphrase.
sudo nix run github:nix-community/disko/latest#disko-install -- \
  --flake github:GooseRooster/nixos-config#home
```

`disko-install` replaces the manual partitioning from the minimal-install
instructions — it runs `disko` (destroy/format/mount) and then `nixos-install`
and the bootloader install, all in one. You don't need to run any other
installer steps first.

Notes:

- If `git` isn't on the ISO: `nix-shell -p git`.
- The installer SSH key is ephemeral — you can remove it from GitHub afterward
  (or leave it; it dies with the live ISO). Prefer a normal account key over a
  long-lived PAT.
- Don't want to push from the installer at all? Install off the local clone
  (`--flake .#home`) and push from the installed system afterward — auto-upgrade
  is weekly, so there's plenty of time before the GitHub URL is exercised.
- `--disk <name> <device>` is an *optional* override that sets
  `disko.devices.disk.<name>.device` from the command line (e.g.
  `--disk main /dev/nvme0n1`) instead of editing `disko.nix`; prefer putting the
  real `by-id` path in `disko.nix` so later `nixos-rebuild` uses the same device.
- Install from the **GitHub URL**, not the local clone — it guarantees a clean,
  committed config and matches the `autoUpgrade` flake.
- On first boot the LUKS container still asks for the passphrase (the TPM2
  token isn't enrolled yet) — that's expected.

To partition/format *without* installing (e.g. to re-image a borked disk), run:

```sh
sudo nix run github:nix-community/disko/latest -- \
  --mode disko --flake github:GooseRooster/nixos-config#home
```

## Secure Boot & LUKS/TPM2

These two are *post-install* steps and should be done in order.

### Secure Boot (Lanzaboote)

The plumbing lives in `modules/core/secure-boot.nix`, behind
`modules.secureBoot.enable` (default `false`). It is intentionally disabled
during install — `lzbt` can't sign UKIs until `sbctl` keys exist.

After the first successful boot:

```sh
# 1) generate the Secure Boot keys
sudo sbctl create-keys
```

Then set `modules.secureBoot.enable = true;` in `hosts/home/default.nix`, rebuild,
and verify:

```sh
sudo nixos-rebuild switch --flake .#home
sudo sbctl verify
```

Next, reboot into firmware, enter Secure Boot **Setup Mode** (or erase the
Platform Key), boot back, and enroll:

```sh
sudo sbctl enroll-keys --microsoft   # --firmware-builtin on some boards (e.g. Framework)
```

Reboot — Secure Boot is now enforced (`bootctl status` shows `enabled (user)`).
You need a BIOS password or equivalent to protect the SB policy (out of scope).

### LUKS TPM2 auto-unlock

Enroll the TPM2 token **after** Secure Boot is on, because PCR 7 seals against
the Secure Boot state:

```sh
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 \
  /dev/disk/by-partlabel/disk-main-luks
```

Reboot and the disk should unlock without a passphrase. The passphrase remains
as a fallback (and is required after any BIOS/Secure Boot change, which
invalidates PCR 7 — re-enroll with the same command). `boot.initrd.systemd.enable`
is set in `modules/core/system.nix`, which TPM2 unlock requires.

## Power management

- **Sleep / suspend-to-RAM** works out of the box via GNOME + systemd-logind —
  no config needed.
- **Hibernation** is *not* currently enabled: it requires a persistent on-disk
  swap target, and this host uses `zramSwap` only. If you want it later, add a
  LUKS-encrypted swap partition (or a `nodatacow` btrfs swapfile) sized ≥ RAM
  and wire `boot.resumeDevice` (+ `resume_offset` for a swapfile).



## Cheatsheet

```sh
# Apply changes (activate + add to boot menu)
sudo nixos-rebuild switch --flake .#vm
sudo nixos-rebuild switch --flake .#home

# Dry-run: build without touching the running system
nixos-rebuild dry-build --flake .#vm
nixos-rebuild dry-activate --flake .#vm

# Activate only for this boot (reverts on reboot) — useful for risky changes
sudo nixos-rebuild test --flake .#vm

# Build and add to boot menu, activate on next reboot
sudo nixos-rebuild boot --flake .#vm

# Roll back to the previous generation
sudo nixos-rebuild switch --rollback
sudo nixos-rebuild list-generations

# Update flake inputs (all)
nix flake update

# Update a single input
nix flake update nixpkgs
nix flake update cli
nix flake update nix-cachyos-kernel

# Sanity-check the flake before committing
nix flake check

# Regenerate hardware config after disk/hardware changes, then copy it in
sudo nixos-generate-config
#   cp /etc/nixos/hardware-configuration.nix hosts/<name>/hardware-configuration.nix

# Garbage-collect old generations (also runs weekly via modules.core.maintenance)
sudo nix-collect-garbage -d
sudo nix-collect-garbage --delete-older-than 30d

# Check for / apply firmware updates (services.fwupd)
fwupdmgr get-updates

# Set the declarative user's password (first boot)
sudo passwd gooze
```

## Roadmap


### Planned

- **CI** (`.github/workflows/`, both this repo and `nix-cli`):
  - `check` — run `nix flake check` / `nix build` on push & PR to gate broken
    configs.
  - `update-flake-lock` — scheduled `nix flake update` that opens a PR with the
    fresh lock file.
  - Using Determinate Systems actions (`determinate-nix-action`,
    `magic-nix-cache-action`, `update-flake-lock`).
- **Hibernation** — add an encrypted on-disk swap target and `boot.resumeDevice`
  (see [Power management](#power-management)).
- **`home` hardware config** — generate and commit the real
  `hosts/home/hardware-configuration.nix` (currently a placeholder; it blocks a
  full `nix flake check` until filled in). Disko already supplies the
  `fileSystems`, so generate with `--no-filesystems`.


## Adding a host (e.g. WSL)

Create `hosts/<name>/default.nix`, point it at a flavor, set
`modules.users.primary`, and add a matching `nixosConfigurations.<name>` in
`flake.nix`.
