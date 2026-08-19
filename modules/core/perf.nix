{ config, lib, pkgs, ... }:

let
  cfg = config.modules.perf;
in
{
  options.modules.perf.enable =
    lib.mkEnableOption "performance tuning (system76-scheduler, I/O scheduler, sysctls)";

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl = {
      "vm.swappiness" = 10;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };

    # I/O scheduler: mq-deadline for SSD/NVMe, bfq for rotational disks.
    # No-op on the virtio disks of this VM; applies on real hardware.
    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      ACTION=="add|change", KERNEL=="sd[a-z]*|nvme[0-9]*n[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    '';

    environment.systemPackages = [ pkgs.system76-scheduler ];

    # System D-Bus policy shipped by the package.
    services.dbus.packages = [ pkgs.system76-scheduler ];

    environment.etc = {
      # Distribution config straight from the package.
      "system76-scheduler/config.kdl".source = "${pkgs.system76-scheduler}/data/config.kdl";

      # NixOS puts binaries in the store, not /usr/bin, so match by name.
      "system76-scheduler/process-scheduler/01-fix-pipewire-paths.kdl".text = ''
        assignments {
          sound-server {
            pipewire
            pipewire-pulse
            jackd
          }
        }
      '';
    };

    systemd.services.system76-scheduler = {
      description = "System76 CPU scheduler daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "dbus.service" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.system76-scheduler} daemon";
        ExecReload = "${lib.getExe pkgs.system76-scheduler} daemon reload";
        Restart = "on-failure";
      };
    };
  };
}
