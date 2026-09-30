{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  isNoctalia = config.modules.desktop.session == "noctalia";

  # Not in nixpkgs, so built from source. Pinned as a flake input
  # (flake = false), see pkgs/hatter. The GNOME stack installs it from
  # gnome-settings.nix; the noctalia session needs it here.
  hatter = pkgs.callPackage ../../pkgs/hatter { src = inputs.hatter; };
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
      # security.pam.services.login.oo7.enable (set by services.oo7 below)
      # unlocks the oo7 keyring at ly login exactly like GDM does. Sway's
      # session .desktop is discovered from the session packages Sway installs.
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
      #
      # Secret Service: oo7, the gnome-keyring replacement GNOME moved to in 51.
      # services.oo7 installs oo7-daemon + the PAM login auto-unlock hook
      # (pam_oo7) + oo7-portal, and auto-migrates an existing gnome-keyring.
      # gnome-keyring stays disabled so the two don't compete for
      # org.freedesktop.secrets. The SSH agent (gcr-ssh-agent) is separate and
      # lives in keyring.nix.
      services.oo7.enable = true;
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

        # Hatter icon theme (icons for the shell + GTK apps; the icon-theme
        # name is set in the dotfiles' gtk module).
        hatter

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
