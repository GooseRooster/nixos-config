{ lib, pkgs, ... }:

# Apps + fonts shared by every session stack (GNOME and noctalia alike).
# GNOME-specific tooling (refine, dconf-editor, ...) stays in the gnome module.

{
  # Nautilus (Files) — the org.gnome.Nautilus flatpak is deprecated, so it
  # comes from nixpkgs instead. Sushi (previewer) likewise.
  environment.systemPackages = [
    pkgs.nautilus
  ];

  services.gnome.sushi.enable = true;
  xdg.mime.defaultApplications."inode/directory" = "org.gnome.Nautilus.desktop";

  # Firefox is native, not Flatpak (the org.mozilla.firefox flatpak was dropped).
  programs.firefox.enable = true;

  # Emoji + general fallback fonts. CJK users may also want:
  # noto-fonts-cjk-sans, noto-fonts-cjk-serif.
  fonts.packages = with pkgs; [
    noto-fonts-color-emoji
    noto-fonts
    nerd-fonts.jetbrains-mono
  ];
}
