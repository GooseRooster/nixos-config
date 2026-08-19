{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.noctalia.nixosModules.default ];

  programs.noctalia = {
    enable = true;

    # Run Noctalia as a systemd user service bound to graphical-session.target
    # (the module default). Under UWSM, graphical-session.target is only reached
    # after the compositor signals readiness (uwsm finalize, see scroll.nix), so
    # noctalia starts with WAYLAND_DISPLAY in its environment and stops when the
    # session ends.
    systemd.enable = true;

    # Noctalia's TOML config lives in chezmoi: ~/.config/noctalia/
    # recommendedServices is left off; services are enabled explicitly below.
  };
}
