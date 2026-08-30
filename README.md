# nixos-config

Flake-based NixOS configuration for a Flatpak-first, bluefin-like GNOME desktop:

- **Desktop**: minimal [GNOME](https://www.gnome.org) (GDM, Wayland-only)
- **Apps**: declarative Flatpaks (see `modules/flatpak/`), GNOME core apps disabled; Firefox is native (`programs.firefox`, not a Flatpak)
- **Shell extensions**: declaratively installed via `pkgs.gnomeExtensions`
- **Kernel**: nixpkgs kernel by default (`linuxPackages_latest`),
  with a per-host `latest` | `lts` fallback
- **Hardening**: moderate kernel/sudo/ssh hardening (`modules/core/hardening.nix`)
- **Maintenance**: automatic GC + store optimisation + fwupd

CLI/dev batteries live in a separate repo ([`nix-cli`](https://github.com/GooseRooster/nix-cli))
and are pulled in as a flake input.

## Layout

- `hosts/<name>/` — per-machine entrypoint (hostname, user, session stack, flatpaks, kernel, hardware)
- `modules/base.nix` — shared core every host imports (core modules + defaults)
- `modules/core/` — cross-host system modules (`system`, `kernel`, `perf`,
  `nix`, `users`, `hardening`, `maintenance`, `podman`, `secure-boot`)
- `modules/desktop/` — shared desktop plumbing (`modules/desktop/default.nix`)
  plus the session stack modules: `gnome*.nix` and `noctalia.nix`
- `modules/flatpak/` — declarative flatpaks, split into toggle-able sets
- `modules/extras/` — optional host extras (theming)
- `quadlets/` — example podman quadlet files (system + rootless user templates)

## Host composition

There is no flavor layer: each host imports what it needs, explicitly.

- `modules/base.nix` — core modules + perf/hardening/maintenance defaults,
  imported by every host.
- `modules/desktop/default.nix` — desktop plumbing shared by every session
  stack (audio, portals, keyring, power, ...).
- Session stack: a host imports exactly one of `modules/desktop/gnome.nix`
  (+ `gnome-settings.nix`, `gnome-devtools.nix`, `gnome-extensions.nix`) or
  `modules/desktop/noctalia.nix`. Each stack sets `modules.desktop.session`
  via `mkDefault`, which gates its own config and mirrors into Home Manager.

So `hosts/home` imports base + desktop + `noctalia.nix`; `hosts/vm` imports
base + desktop + the `gnome-*.nix` modules. Per-host extras (flatpak sets,
gaming, theming, secure-boot, ...) are imported and enabled directly in the
host file.

## Kernel selection

`modules/core/kernel.nix` exposes `modules.kernel.variant` (`latest` | `lts`),
defaulting to `latest`. Set per-host:

```nix
modules.kernel.variant = "lts";   # plain nixpkgs LTS kernel
```

`latest` maps to `pkgs.linuxPackages_latest`; `lts` maps to
`pkgs.linuxPackages`. Nothing else needs configuring.

## Users are declarative

Users are declared per host via `modules/users.nix`. Set
`modules.users.primary = "gooze"` (or a per-host name) and the module creates a
normal user with the groups listed in `modules/users.nix` (extended by
`modules/desktop/default.nix` on desktop hosts).

Use the **same name** for the account you create in the graphical installer, so
the flake reuses that account (same uid, same `/home`, same keyring) instead of
creating a second one. Pin the uid to make that explicit and to turn a future
rename into a loud conflict rather than silent uid drift:

```nix
modules.users.primary = "gooze";
modules.users.uid = 1000;   # first normal user from the installer
```

By default no password is declared — with `users.mutableUsers = true` (the
default) the installer-set password is left untouched and keeps working after
the rebuild.


For the VM, where you need to log in before you can `passwd`, set a throwaway
password that only applies while the account has none:

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
in `modules/desktop/gnome.nix`, not as a Flatpak. (Sandboxing reasons)

## GNOME Shell extensions

Extensions are installed declaratively in `modules/desktop/gnome-extensions.nix`
via `pkgs.gnomeExtensions`. 

Some extensions are pulled in as custom flakes if they are not available on EGO.


## Apply

Use `boot` option instead of switch when applying for the first time.

```sh
sudo nixos-rebuild boot --flake .#home
```

## Installing on the host (graphical installer)

The disk is set up by the **graphical** NixOS installer (GNOME ISO): a single
NVMe with an ESP at `/boot`, a LUKS-encrypted btrfs root with `home` and `nix`
subvolumes, and a separate encrypted swap partition. The flake's
`modules/core/snapper.nix` snapshots `/` and `/home` (skipping `/nix`), which
matches that layout.

### 1. Install with the graphical installer

Boot the ISO and run the graphical installer:

- Choose **Any DE, does not matter** and, when prompted, **btrfs** as the filesystem (with LUKS
  encryption — recommended). Use *erase disk* (or manual partitioning); the
  installer creates `home` and `nix` subvolumes plus an encrypted swap
  partition.
- Create a normal user **named the same as your host's `modules.users.primary`**
  (e.g. `gooze`) and set its password — the flake declares the same user with no
  password, so `users.mutableUsers` (the default) leaves the installer password
  untouched and reuses the account as-is.
  **Still set a root password** during the install.
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

Confirm `system.stateVersion` in `hosts/<yourhost>/default.nix` matches the value in
`/etc/nixos/configuration.nix`

### 4. Verify the btrfs layout matches the snapshot config

```sh
sudo btrfs subvolume list /
```

Expect `home` and `nix` subvolumes (mounted at `/home` and `/nix`); the root
filesystem is the top-level subvolume. The snapper module snapshots `/` and
`/home` (skipping `/nix`), which this layout satisfies.

### 5. Switch to the flake

```sh
sudo nixos-rebuild boot --flake .#<yourhost>
```

After this, log in as the declarative user (e.g. `gooze`) with the password you
set during the install — the flake reused the same account, so nothing needs
migrating.

### 6. Run the one-time bootstrap

Home Manager activation runs **once at boot** as a system service
(`home-manager-<user>.service`), not on login. Network-dependent state (LazyVim
clone, `tinty sync`, television channels) is *not* done there — it's done by a
single idempotent `bootstrap` command instead, since activation runs before
networking is up. Once you're logged in and online, run it once:

```sh
bootstrap
```

It's safe to re-run (each step skips itself once done; a failed offline step
retries cleanly next time). See the home-manager README's **Bootstrap** section
for details.



## Secure Boot (Lanzaboote)

The plumbing lives in `modules/core/secure-boot.nix`, behind
`modules.secureBoot.enable` (default `false`). It is intentionally disabled
during install — `lzbt` can't sign UKIs until `sbctl` keys exist.

After the first successful boot:

```sh
# 1) generate the Secure Boot keys
sudo sbctl create-keys
```

Then set `modules.secureBoot.enable = true;` in `hosts/<yourhost>/default.nix`, rebuild,
and verify:

```sh
sudo nixos-rebuild switch --flake .#<yourhost>
sudo sbctl verify
```

Next, reboot into firmware, enter Secure Boot **Setup Mode** (or erase the
Platform Key), boot back, and enroll:

```sh
sudo sbctl enroll-keys --microsoft   # --firmware-builtin on some boards (e.g. Framework)
```

Reboot — Secure Boot is now enforced (`bootctl status` shows `enabled (user)`).
You need a BIOS password or equivalent to protect the SB policy (out of scope).

#### ASUS motherboards

ASUS firmware has no explicit "enter Setup Mode" button and names its Secure
Boot toggle misleadingly. The settings that matter:

- **OS Type** (`Boot → Secure Boot`): set to **"Windows UEFI Mode"**. Despite the
  name this is what *enables* Secure Boot; **"Other OS"** disables it (that's the
  factory default, and why `sbctl status` reports `Secure Boot: Disabled` even
  after enrolling keys).
- **Secure Boot Mode**: set to **"Custom"** (not "Standard"). Standard ignores
  your keys and uses the factory ASUS/Microsoft ones.
- To enroll, put the firmware in Setup Mode by deleting the **Platform Key (PK)**
  in **Key Management** (this is the "erase the Platform Key" step above). Don't
  use "Clear All Secure Boot Keys" — it also drops the dbx forbidden list.
- **Administrator password**: set one and disable **Fast Boot** — some ASUS
  boards won't expose or accept Secure Boot key enrollment without it.
- Enroll with `--microsoft`, **not** `--firmware-builtin` (the latter breaks
  enrollment on ASUS). If enrollment fails with
  `File is immutable: /sys/firmware/efi/efivars/...`, the firmware marked
  `KEK`/`db` immutable in `efivarfs` — pass `--ignore-immutable`:

  ```sh
  sudo sbctl enroll-keys --microsoft --ignore-immutable
  ```

  (`chattr` is not needed; `--ignore-immutable` un-sets the flag itself.)
- After enrolling, leave OS Type = "Windows UEFI Mode" and Secure Boot Mode =
  "Custom". Switching Secure Boot Mode back to "Standard" silently restores the
  factory keys and undoes your enrollment.

Sanity-check after enrollment — your keys should appear, not `ASUSTeK MotherBoard`:

```sh
sudo sbctl list-enrolled-keys
```

> **Unsigned kernels are expected.** Lanzaboote v1.x boots via a signed
> `systemd-boot` + `lanzastub`; the firmware only verifies those two UEFI apps,
> and the kernel is loaded by the stub (TPM-measured, not firmware-signed). So
> `sbctl verify` showing kernels as unsigned is *not* why the BIOS blocks boot —
> a blocked boot means the firmware is enforcing a key that doesn't match the
> one Lanzaboote signed with (i.e. your keys were never actually enrolled).





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



### Done

- **CI** (`.github/workflows/`):
  - `check` — `nix flake check` (builds both hosts) on push & PR.
  - `update-flake-lock` — Sundays 09:17 UTC: updates all inputs and opens a PR
    gated on building both hosts. Runs last in the update chain (after
    `nix-cli` and `home-manager`), so the merged PRs from those repos are what
    `cli`/`dotfiles` get pinned to. Lands before the Monday 00:00 local
    `system.autoUpgrade`. Merging the weekly PRs also keeps the schedules
    alive — GitHub disables cron workflows after 60 days of repo inactivity.


## Adding a host (e.g. WSL)

Create `hosts/<name>/default.nix` importing `modules/base.nix` plus the
desktop/session stack modules it needs, set
`modules.users.primary`, and add a matching `nixosConfigurations.<name>` in
`flake.nix`.
