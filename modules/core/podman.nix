{ config, lib, pkgs, ... }:

let
  cfg = config.modules.podman;
in
{
  options.modules.podman = {
    linger = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable lingering for the primary user so rootless user quadlets keep
        running when no session is logged in. Needed for always-on services
        (e.g. searxng); not needed for interactive `podman run`.
      '';
    };
  };

  config = {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    environment.systemPackages = with pkgs; [
      podman-compose
    ];

    # Rootless podman needs subordinate UID/GID ranges. nixpkgs auto-allocates
    # these for normal users today (autoSubUidGidRange), but we pin explicit
    # ranges so the mapping is deterministic and survives nixpkgs default
    # changes. 100000:65536 is the conventional single-user podman range.
    users.users.${config.modules.users.primary} = {
      subUidRanges = [ { startUid = 100000; count = 65536; } ];
      subGidRanges = [ { startGid = 100000; count = 65536; } ];
      linger = lib.mkIf cfg.linger true;
    };

    # Declarative *system* quadlets live in /etc/containers/systemd/.
    # For an example, see quadlets/example.container. Declare one like this:
    #
    #   environment.etc."containers/systemd/example.container".source =
    #     ../../quadlets/example.container;
    #
    # Rootless *user* quadlets live in ~/.config/containers/systemd/
    # and are typically managed with chezmoi or Home Manager.
  };
}
