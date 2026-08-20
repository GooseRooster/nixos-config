# nixos-config

Flake-based NixOS configuration for a Flatpak-first, bluefin-like GNOME desktop:

- **Desktop**: minimal [GNOME](https://www.gnome.org) (GDM, Wayland-only)
- **Apps**: declarative Flatpaks (see `modules/flatpak/`), GNOME core apps disabled
- **Shell extensions**: declaratively installed via `pkgs.gnomeExtensions`
- **Kernel**: [CachyOS](https://github.com/xddxdd/nix-cachyos-kernel) by default,
  with a per-host fallback to the plain nixpkgs kernel
- **Hardening**: moderate kernel/sudo/ssh hardening (`modules/core/hardening.nix`)
- **Maintenance**: automatic GC + store optimisation + fwupd

CLI/dev batteries live in a separate repo ([`nixos-cli`](https://github.com/GooseRooster/nixos-cli))
and are pulled in as a flake input.

## Layout

- `hosts/<name>/` — per-machine entrypoint (hostname, user, flatpaks, kernel, hardware)
- `flavors/` — high-level combos: `base`, `desktop`, `wsl` (stub)
- `modules/core/` — cross-flavor system modules (`system`, `kernel`, `perf`,
  `nix`, `users`, `hardening`, `maintenance`)
- `modules/desktop/` — GNOME + audio/portal/keyring/power modules
- `modules/flatpak/` — declarative flatpaks, split into toggle-able sets
- `modules/extras/` — optional host extras (theming)

## Host vs flavor

A **host** selects a **flavor** and adds its own machine-specific extras:

- **flavor** = reusable system shape (`base` / `desktop` / `wsl`).
- **host** = hostname + hardware + user + which extras are enabled (flatpak
  sets, theming, kernel, etc).

`hosts/vm` and `hosts/home` both use the `desktop` flavor; only `home` enables
flatpaks/theming.

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

`bazaar-integration` and `gradia-integration` are not listed there — they ship
inside the `io.github.kolunmi.Bazaar` and `be.alexandervanhee.gradia` flatpaks.

## Dotfiles via chezmoi

dconf/GSettings tweaks and GNOME shell preferences (beyond what's set
declaratively) are managed by chezmoi, not Nix.

## Apply

```sh
sudo nixos-rebuild switch --flake .#vm
sudo nixos-rebuild switch --flake .#home
```

> `hosts/home/hardware-configuration.nix` is a placeholder — generate it on the
> real machine with `nixos-generate-config` and copy the result there first.

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

### Open items (fix first)

- **Ghostty as default terminal** — `Terminal=true` .desktop entries (e.g. neovim)
  still don't pick up Ghostty despite the `default-applications.terminal`
  GSettings override in `modules/desktop/terminal.nix`. Investigate whether the
  override isn't applying (per-user dconf overriding it, or the schema override
  not taking effect).
- **Refine misbehaving** — `page.tesk.Refine` flatpak has settings greyed out.
  Suspects: managed extensions not enabled yet (e.g. `user-themes`), or missing
  dconf/D-Bus permissions (check Flatseal).

### Planned

- **CI** (`.github/workflows/`, both this repo and `nixos-cli`):
  - `check` — run `nix flake check` / `nix build` on push & PR to gate broken
    configs.
  - `update-flake-lock` — scheduled `nix flake update` that opens a PR with the
    fresh lock file.
  - Using Determinate Systems actions (`determinate-nix-action`,
    `magic-nix-cache-action`, `update-flake-lock`).
- **Secure Boot** (e.g. Lanzaboote) on the host machine.
- **`home` hardware config** — generate and commit the real
  `hosts/home/hardware-configuration.nix` (currently a placeholder; it blocks a
  full `nix flake check` until filled in).

## Adding a host (e.g. WSL)

Create `hosts/<name>/default.nix`, point it at a flavor, set
`modules.users.primary`, and add a matching `nixosConfigurations.<name>` in
`flake.nix`.
