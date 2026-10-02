{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Not in nixpkgs, so built from source. Pinned as a flake input
  # (flake = false), see pkgs/hatter.
  hatter = pkgs.callPackage ../../pkgs/hatter { src = inputs.hatter; };
in
{
  imports = [
    inputs.noctalia.nixosModules.default
  ];

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
  # security.pam.services.login.enableGnomeKeyring (set by
  # services.gnome.gnome-keyring below) unlocks the login keyring at ly
  # login exactly like GDM does. Sway's session .desktop is discovered from
  # the session packages Sway installs.
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

  # Session plumbing that a desktop environment would otherwise provide:
  # keyring daemon, gcr SSH agent and polkit. Noctalia v5 registers its own
  # polkit agent (shell.polkit_agent in the HM settings).
  #
  # Secret Service: gnome-keyring. The nixpkgs module installs the daemon,
  # the gcr prompter and the Secret portal, and wires PAM login auto-unlock
  # (security.pam.services.login.enableGnomeKeyring). The SSH agent
  # (gcr-ssh-agent) is separate and lives in keyring.nix.
  services.gnome.gnome-keyring.enable = true;

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
    # custom GTK4 theme state, then re-apply.
    pkgs.nwg-look
  ];
}
