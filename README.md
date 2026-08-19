# nixos-config

Flake-based NixOS configuration for a lightweight, Bluefin-like desktop:

- **Compositor**: [Scroll](https://github.com/dawsers/scroll) (sway fork, scrolling tiling)
- **Session manager**: [UWSM](https://github.com/Vladimir-csp/uwsm)
- **Shell**: [Noctalia v5](https://github.com/noctalia-dev/noctalia) (bar/launcher/notifications/lockscreen/idle)
- **Greeter**: [Noctalia Greeter](https://github.com/noctalia-dev/noctalia-greeter) (greetd)
- Portals (wlr/gtk), gnome-keyring, pipewire, power-profiles-daemon, upower,
  latest kernel + system76-scheduler.

CLI/dev batteries live in a separate repo ([`nixos-cli`](https://github.com/GooseRooster/nixos-cli))
and are pulled in as a flake input.

## Layout

- `hosts/<name>/` — per-machine entrypoint (hostname, user, flatpaks, hardware)
- `flavors/` — high-level combos: `base`, `desktop`, `wsl` (stub)
- `modules/core/` — cross-flavor system modules (incl. `users.nix`)
- `modules/desktop/` — desktop-specific modules
- `modules/flatpak/` — declarative flatpaks, split into toggle-able sets
- `modules/extras/` — optional host extras (theming)

## Host vs flavor

A **host** selects a **flavor** and adds its own machine-specific extras:

- **flavor** = reusable system shape (`base` / `desktop` / `wsl`).
- **host** = hostname + hardware + user + which extras are enabled (flatpak
  sets, theming, etc).

`hosts/vm` and `hosts/home` both use the `desktop` flavor; only `home` enables
flatpaks/theming.

## Users are declarative

Users are declared per host via `modules/users.nix`. Set
`modules.users.primary = "gooze"` (or a per-host name) and the module creates a
normal user with the groups supplied by the flavor.

No password is declared — with `users.mutableUsers = true` (the default) set it
imperatively after first boot:

```sh
sudo passwd gooze
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

## Dotfiles via chezmoi

Noctalia (`~/.config/noctalia/config.toml`) and Scroll
(`~/.config/scroll/config`) are managed by chezmoi, not Nix. The Scroll config
should autostart Noctalia (or rely on its systemd user service).

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

# Sanity-check the flake before committing
nix flake check

# Regenerate hardware config after disk/hardware changes, then copy it in
sudo nixos-generate-config
#   cp /etc/nixos/hardware-configuration.nix hosts/<name>/hardware-configuration.nix

# Garbage-collect old generations (keep some for rollback safety)
sudo nix-collect-garbage -d
sudo nix-collect-garbage --delete-older-than 30d

# Set the declarative user's password (first boot)
sudo passwd gooze
```

## Adding a host (e.g. WSL)

Create `hosts/<name>/default.nix`, point it at a flavor, set
`modules.users.primary`, and add a matching `nixosConfigurations.<name>` in
`flake.nix`.
