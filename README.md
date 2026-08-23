# nixos-config

Flake-based NixOS configuration for a Flatpak-first, bluefin-like GNOME desktop:

- **Desktop**: minimal [GNOME](https://www.gnome.org) (GDM, Wayland-only)
- **Apps**: declarative Flatpaks (see `modules/flatpak/`), GNOME core apps disabled; Firefox is native (`programs.firefox`, not a Flatpak)
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

Firefox is the exception: it is installed natively via `programs.firefox.enable`
in `modules/desktop/gnome.nix`, not as a Flatpak.

## GNOME Shell extensions

Extensions are installed declaratively in `modules/desktop/gnome-extensions.nix`
via `pkgs.gnomeExtensions`. 

Some extensions are pulled in as custom flakes if they are not available on EGO.


## Apply

```sh
sudo nixos-rebuild switch --flake .#vm
sudo nixos-rebuild switch --flake .#home
```

## Installing on the host (graphical installer)

The disk is set up by the **graphical** NixOS installer (GNOME ISO): a single
NVMe with an ESP at `/boot`, a LUKS-encrypted btrfs root with `home` and `nix`
subvolumes, and a separate encrypted swap partition. The flake's
`modules/core/snapper.nix` snapshots `/` and `/home` (skipping `/nix`), which
matches that layout.

### 1. Install with the graphical installer

Boot the GNOME ISO and run the graphical installer:

- Choose **GNOME** and, when prompted, **btrfs** as the filesystem (with LUKS
  encryption — recommended). Use *erase disk* (or manual partitioning); the
  installer creates `home` and `nix` subvolumes plus an encrypted swap
  partition.
- Create a normal user named **`gooze`** and set its password. This password
  becomes the login + `sudo` password and is **reused as-is** by the flake — the
  flake declares the user with no password option, so `users.mutableUsers`
  (the default) leaves the installer password untouched.
- Finish and reboot into the installed system.

### 2. Clone the flake

```sh
git clone git@github.com:GooseRooster/nixos-config.git ~/.config/nixos-config
cd ~/.config/nixos-config
```

If the ISO/shell has flakes disabled: `nix --extra-experimental-features 'nix-command flakes'`.

### 3. Copy the hardware configuration

```sh
sudo cp /etc/nixos/hardware-configuration.nix hosts/home/hardware-configuration.nix
```

Then carry over the **swap** LUKS unlock entry — the installer writes it to
`/etc/nixos/configuration.nix` (not the hardware config), so without it the
encrypted swap partition won't unlock at boot. Add to `hosts/home/default.nix`:

```nix
boot.initrd.luks.devices."luks-cef99b37-a347-4432-be60-8d04312cf661".device =
  "/dev/disk/by-uuid/cef99b37-a347-4432-be60-8d04312cf661";
```

Confirm `system.stateVersion` in `hosts/home/default.nix` matches the value in
`/etc/nixos/configuration.nix` (it is already `"26.05"`).

### 4. Verify the btrfs layout matches the snapshot config

```sh
sudo btrfs subvolume list /
```

Expect `home` and `nix` subvolumes (mounted at `/home` and `/nix`); the root
filesystem is the top-level subvolume. The snapper module snapshots `/` and
`/home` (skipping `/nix`), which this layout satisfies.

### 5. Switch to the flake

```sh
sudo nixos-rebuild switch --flake .#home
```

The first rebuild may need to run **twice** so the CachyOS binary cache
(substituter) takes effect before the kernel is fetched (see
[Kernel selection](#kernel-selection)).

After this, the installer-set password still works and `/home/gooze` is
unchanged — the flake reuses the same account and home directory.

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
  /dev/disk/by-uuid/0aa5735d-f6a5-48b4-81f3-26ad5630837f
```

Reboot and the disk should unlock without a passphrase. The passphrase remains
as a fallback (and is required after any BIOS/Secure Boot change, which
invalidates PCR 7 — re-enroll with the same command). `boot.initrd.systemd.enable`
is set in `modules/core/system.nix`, which TPM2 unlock requires.

Safety check before any of this: the passphrase you set at install is LUKS
keyslot 0 and is never touched by TPM enrollment, so you can't be locked out as
long as you remember it. Verify it independently after install:

```sh
sudo cryptsetup open --test-passphrase /dev/disk/by-uuid/0aa5735d-f6a5-48b4-81f3-26ad5630837f
# → "Key slot 0 unlocked." confirms the passphrase works
```

## Power management

- **Sleep / suspend-to-RAM** works out of the box via GNOME + systemd-logind —
  no config needed.
- **Hibernation** is *not* currently enabled: it needs `boot.resumeDevice`
  (+ `resume_offset`). The graphical installer already created an encrypted
  on-disk swap partition, so only the resume wiring is missing — `zramSwap`
  remains the preferred (higher-priority) swap target.



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
  (see [Power management](#power-management)). The graphical-installer swap
  partition is already on disk, so this only needs `boot.resumeDevice` +
  `resume_offset` wiring.


## Adding a host (e.g. WSL)

Create `hosts/<name>/default.nix`, point it at a flavor, set
`modules.users.primary`, and add a matching `nixosConfigurations.<name>` in
`flake.nix`.
