{ lib, ... }:

{
  options.modules.desktop.session = lib.mkOption {
    type = lib.types.enum [ "gnome" "noctalia" ];
    default = "gnome";
    description = ''
      Which desktop session stack the host runs:

      - "gnome":     GDM + GNOME Shell (the original Flatpak-first setup).
      - "noctalia":  ly (display manager) + Umbriel (Wayland compositor) +
                     Noctalia v5 (desktop shell) — the lightweight DE.

      Every session-specific module (GNOME stack and noctalia stack) gates
      its config on this option, so exactly one stack is active per host.
    '';
  };
}
