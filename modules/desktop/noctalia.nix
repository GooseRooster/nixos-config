{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  isNoctalia = config.modules.desktop.session == "noctalia";
in
{
  # Identify the stack this module provides (see session.nix). mkDefault so a
  # host can still pin it explicitly; importing both stacks surfaces the
  # conflict loudly at eval time. The compositor (Sway) lives in sway.nix.
  imports = [
    inputs.noctalia.nixosModules.default
  ];

  config = lib.mkMerge [
    { modules.desktop.session = lib.mkDefault "noctalia"; }

    (lib.mkIf isNoctalia {
      # Noctalia v5 desktop shell. NOT started via a systemd user service:
      # upstream recommends compositor autostart; Sway runs `exec noctalia`
      # (see the HM sway config). recommendedServices pulls
      # NetworkManager/Bluetooth/UPower + a power profile daemon (skipped
      # when TuneD is enabled, which hosts/home uses).
      programs.noctalia = {
        enable = true;
        systemd.enable = false;
        recommendedServices.enable = true;
      };

      # ly (display manager). ly's PAM service substacks `login`, so
      # security.pam.services.login.enableGnomeKeyring (see keyring.nix) unlocks
      # gnome-keyring at ly login exactly like GDM does. Sway's session
      # .desktop is discovered from the session packages Sway installs.
      services.displayManager.ly = {
        enable = true;
        settings = {
          # Monochrome: black background, white text, no borders. Colors are
          # 0xSSRRGGBB where SS carries termbox styling bits (01 = bold,
          # 02 = hi-black background).
          bg = "0x02000000";
          fg = "0x01FFFFFF";
          error_fg = "0x01FFFFFF";
          hide_borders = true;

          # Clock module (ly also has the user/session selector built in).
          clock = "%a %d %b  %H:%M";
          bigclock = "en";
        };
      };

      # ly is a TUI: it renders with the kernel console font, which must be a
      # PSF font (TTFs like JetBrains Mono Nerd are not usable in a TTY). Pick a
      # large terminus face for a crisp greeter + bigclock.
      console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";

      # Session plumbing that GNOME used to provide implicitly via
      # core-os-services: keyring daemon, gcr SSH agent and polkit. Noctalia v5
      # registers its own polkit agent (shell.polkit_agent in the HM settings).
      services.gnome.gnome-keyring.enable = true;
      services.gnome.gcr-ssh-agent.enable = true;
      security.polkit.enable = true;
      programs.dconf.enable = true; # gsettings persistence (Noctalia color-scheme sync)

      # Noctalia's GTK template pairs its rendered libadwaita-style
      # noctalia.css with the adw-gtk3 theme (GTK3 doesn't consume the libadwaita
      # named colors on its own; the template's apply.sh sets
      # gtk-theme=adw-gtk3-dark via dconf when the theme is present). GTK4 /
      # libadwaita apps pick the colors up from ~/.config/gtk-4.0/gtk.css
      # without it.
      environment.systemPackages = [
        pkgs.adw-gtk3

        # GTK settings editor for wlroots-style sessions (Noctalia docs'
        # recommended way to (re)apply adw-gtk3). One-time use: select
        # "adw-gtk3", Apply — and keep the GTK4 option UNCHECKED (libadwaita
        # apps are themed by Noctalia's gtk.css overlay, not a GTK4 theme).
        # If GTK4 apps keep wrong colors, Preferences -> "Clear" removes stale
        # custom GTK4 theme state (e.g. from the gnomad era), then re-apply.
        pkgs.nwg-look
      ];
    })
  ];
}
