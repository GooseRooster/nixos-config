# Adwaita-for-Steam theming for Noctalia.
#
# Noctalia ships no Adwaita-for-Steam template (only a Millennium/Material
# community one), so we register a user template that renders the active palette
# into the stable custom-CSS path consumed by pkgs/adwaita-for-steam. Noctalia
# re-renders it on every palette change; the steam-adwaita systemd path unit
# (modules/gaming/steam.nix) then re-applies the skin automatically.
#
# output_path is deliberately not Home-Manager managed: Noctalia must be able to
# rewrite custom.css at runtime.
{ ... }:
{
  programs.noctalia.settings.theme.templates.user.adwaita_steam = {
    # Store path rather than an XDG path: the file exists at build time, so
    # Noctalia's `config validate` step (run by the HM module) can read it.
    input_path = "${./noctalia-steam-adwaita.css}";
    output_path = "$XDG_CONFIG_HOME/AdwSteamGtk/custom.css";
  };
}
