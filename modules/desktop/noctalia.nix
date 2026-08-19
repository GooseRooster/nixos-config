{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.noctalia.nixosModules.default ];

  programs.noctalia = {
    enable = true;

    # Run Noctalia as a systemd user service (fits UWSM's app-slice model).
    systemd.enable = true;

    # Bind the service to scroll-session.target rather than the default
    # graphical-session.target. scroll-session.target is started by scroll only
    # *after* it has imported the Wayland/DBus env (see the scroll module's
    # nixos.conf), so noctalia starts with WAYLAND_DISPLAY set and stops when
    # the compositor exits — the UWSM-compatible "app in the compositor slice"
    # launch pattern.
    systemd.target = "scroll-session.target";

    # Noctalia's TOML config lives in chezmoi: ~/.config/noctalia/
    # recommendedServices is left off; services are enabled explicitly below.
  };
}
