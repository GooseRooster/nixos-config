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
  imports = [
    inputs.noctalia.nixosModules.default
    inputs.umbriel.nixosModules.default
  ];

  config = lib.mkIf isNoctalia {
    # Umbriel (Wayland compositor). The flake's NixOS module installs the
    # package, the Umbriel session .desktop (what ly lists), the
    # xdg-desktop-portal-umbriel backend (screen sharing/capture portals) and
    # the wayland-session environment plumbing.
    programs.umbriel.enable = true;

    # Noctalia v5 desktop shell. NOT started via a systemd user service:
    # upstream deprecates that path; instead Umbriel's [general].autostart
    # launches it (see the HM settings in hosts/home). recommendedServices
    # pulls NetworkManager/Bluetooth/UPower + a power profile daemon (skipped
    # when TuneD is enabled, which hosts/home uses).
    programs.noctalia = {
      enable = true;
      systemd.enable = false;
      recommendedServices.enable = true;
    };

    # ly (display manager). ly's PAM service substacks `login`, so
    # security.pam.services.login.enableGnomeKeyring (see keyring.nix) unlocks
    # gnome-keyring at ly login exactly like GDM does.
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

        # Clock module (ly also has the user/session selector built in; the
        # Umbriel session is discovered from the session .desktop file).
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

    # gtk portal as generic fallback; the umbriel portal module already sets
    # config.umbriel.default = [ "umbriel" "gtk" ].
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
