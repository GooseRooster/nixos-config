# nixos-config

Flake-based NixOS configuration for a lightweight, Bluefin-like desktop:

- **Compositor**: [Scroll](https://github.com/dawsers/scroll) (sway fork, scrolling tiling)
- **Session manager**: [UWSM](https://github.com/Vladimir-csp/uwsm)
- **Shell**: [Noctalia v5](https://github.com/noctalia-dev/noctalia) (bar/launcher/notifications/lockscreen/idle)
- **Greeter**: [Noctalia Greeter](https://github.com/noctalia-dev/noctalia-greeter) (greetd)
- Portals (wlr/gtk), gnome-keyring, pipewire, power-profiles-daemon, upower,
  latest kernel + system76-scheduler.

CLI/dev batteries live in a separate repo (`nixos-cli`) and are pulled in as a
flake input.

## Layout

- `hosts/<name>/` — per-machine entrypoint (hostname, flavor selection, hardware)
- `flavors/` — high-level combos: `base`, `desktop`, `wsl` (stub)
- `modules/core/` — cross-flavor system modules
- `modules/desktop/` — desktop-specific modules

## Users are imperative

Users are **not** declared in Nix. Create them and add groups by hand:

```sh
sudo usermod -aG wheel,networkmanager,video,render,input,audio <user>
```

## Dotfiles via chezmoi

Noctalia (`~/.config/noctalia/config.toml`) and Scroll
(`~/.config/scroll/config`) are managed by chezmoi, not Nix. The Scroll config
should autostart Noctalia (or rely on its systemd user service).

## Apply

```sh
sudo nixos-rebuild switch --flake .#vm
```

## Adding a flavor (e.g. WSL)

Create `hosts/<name>/default.nix`, point it at a flavor, and add a matching
`nixosConfigurations.<name>` in `flake.nix`.
