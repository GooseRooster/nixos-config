{ config, lib, pkgs, ... }:

let
  cfg = config.modules.gamePerformance;
  primary = config.modules.users.primary;
  homeDir = config.users.users.${primary}.home;

  script = pkgs.writeScriptBin "game-performance"
    (builtins.replaceStrings
      [ "@tunedAdm@" "@gsettings@" "@notifySend@" "@perfProfile@" ]
      [
        "${pkgs.tuned}/bin/tuned-adm"
        "${pkgs.glib}/bin/gsettings"
        "${pkgs.libnotify}/bin/notify-send"
        cfg.perfProfile
      ]
      (builtins.readFile ./game-performance.sh));
in
{
  options.modules.gamePerformance = {
    enable = lib.mkEnableOption "game-performance helper (TuneD profile + Night Light)";

    perfProfile = lib.mkOption {
      type = lib.types.str;
      default = "gaming";
      description = "TuneD profile to switch to while a game is running.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ script ];

    # A real copy (not a symlink) for Flatpak Steam: store symlinks don't
    # resolve inside the sandbox, so Steam's launch options need a plain file
    # under ~/.local/bin (already exposed via `--filesystem=~/.local/bin:ro`).
    system.activationScripts.gamePerformance = lib.stringAfter [ "users" ] ''
      install -d -m 0755 -o ${primary} -g "$(id -gn ${primary})" ${homeDir}/.local/bin
      install -m 0755 -o ${primary} -g "$(id -gn ${primary})" ${script}/bin/game-performance ${homeDir}/.local/bin/game-performance
    '';
  };
}
