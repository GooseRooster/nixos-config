{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  primary = config.modules.users.primary;
  homeDir = config.users.users.${primary}.home;

  # Adwaita-for-Steam
  adwaita-skin = pkgs.callPackage ../../pkgs/adwaita-for-steam {
    src = inputs.adwaita-for-steam;
  };

  # Stable custom-CSS path; AdwSteamGtk writes here and the installer loads
  # it after the theme, so theme-tool edits need no rebuild. Missing file =
  # installer just skips it (no --custom-css output in the generated CSS).
  customCss = "${homeDir}/.config/AdwSteamGtk/custom.css";

  adwaita-refresh = pkgs.writeShellScriptBin "steam-adwaita-refresh" ''
    exec ${adwaita-skin}/bin/steam-adwaita-install \
      -t ~/.steam/steam \
      --custom-css ${customCss} \
      "$@"
  '';

  # Watcher entry point: theme tools can write custom.css several times in
  # quick succession, and path-unit events landing while the oneshot service
  # is running are dropped — so settle on a stable hash first, then install.
  adwaita-watched-refresh = pkgs.writeShellScript "steam-adwaita-watched-refresh" ''
    prev=""
    for i in 1 2 3 4 5 6 7 8 9 10; do
      cur="$(sha256sum ${customCss} 2>/dev/null | cut -d' ' -f1 || true)"
      if [ -n "$cur" ] && [ "$cur" = "$prev" ]; then
        break
      fi
      prev="$cur"
      sleep 1
    done
    exec ${adwaita-refresh}/bin/steam-adwaita-refresh
  '';
in
{
  options.modules.steam.enable = lib.mkEnableOption ''
    native Steam (Adwaita-for-Steam skinned) instead of the Flatpak Steam.
    32-bit GL / VA-API extras come from modules.graphics.gaming.
  '';

  config = lib.mkIf config.modules.steam.enable {
    programs.steam = {
      enable = true;
      protontricks.enable = true;
    };

    environment.systemPackages = [
      adwaita-skin
      adwaita-refresh
    ];

    # Runs install.py at login (and via `systemctl --user start
    # steam-adwaita`): Steam client updates can reset the patched steamui
    # CSS, the skin thereby also survives Steam's own reinstalls/verifies.
    # No RemainAfterExit — the watcher below must be able to re-trigger it.
    systemd.user.services.steam-adwaita = {
      description = "Re-apply the Adwaita-for-Steam skin to the native Steam install";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${adwaita-watched-refresh}";
      };
    };

    # Re-run the installer whenever the theming tool rewrites custom.css.
    # We watch the parent directory (not the file) so atomic
    # write-temp-rename edits and delete-and-recreate cycles don't lose the
    # inotify watch; extra triggers are harmless thanks to the debounce.
    systemd.user.paths.steam-adwaita = {
      description = "Watch ~/.config/AdwSteamGtk/custom.css for theming-tool edits";
      wantedBy = [ "default.target" ];
      pathConfig = {
        PathChanged = "${homeDir}/.config/AdwSteamGtk";
        Unit = "steam-adwaita.service";
      };
    };

    # The path unit needs the watched directory to exist at boot, even on
    # hosts where the theming tool hasn't run yet.
    systemd.tmpfiles.rules = [
      "d ${homeDir}/.config/AdwSteamGtk 0755 ${primary} users - -"
    ];
  };
}
