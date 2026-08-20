{ config, lib, pkgs, ... }:

let
  cfg = config.modules.tuned;
in
{
  options.modules.tuned.enable =
    lib.mkEnableOption "TuneD performance profiles (replaces power-profiles-daemon)";

  config = lib.mkIf cfg.enable {
    # TuneD conflicts with power-profiles-daemon; its ppdSupport mode exposes a
    # compatible dbus interface so GNOME's power settings keep working.
    services.power-profiles-daemon.enable = false;

    services.tuned = {
      enable = true;

      # Map GNOME's three power profiles onto richer TuneD profiles.
      ppdSettings.profiles.performance = "gaming";

      # Custom "gaming" profile: latency-performance is tuned for low-latency
      # interactive/gaming workloads.
      profiles.gaming.main.include = "latency-performance";
    };
  };
}
