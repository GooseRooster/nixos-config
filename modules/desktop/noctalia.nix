{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.noctalia.nixosModules.default ];

  programs.noctalia = {
    enable = true;

    # Run Noctalia as a systemd user service (fits UWSM's app-slice model).
    systemd.enable = true;

    # Noctalia's TOML config lives in chezmoi: ~/.config/noctalia/
    # recommendedServices is left off; services are enabled explicitly below.
  };
}
