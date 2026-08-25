{ config, lib, pkgs, ... }:

let
  cfg = config.modules.perf;
in
{
  options.modules.perf.enable =
    lib.mkEnableOption "performance tuning (system76-scheduler, I/O scheduler, sysctls)";

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl = {
      # zram-only swap (no disk swap): prefer compressing anonymous pages over
      # evicting page cache, and read single pages (compressed pages aren't
      # sequential on disk). Values inspired by CachyOS zram settings.
      "vm.swappiness" = 150;
      "vm.page-cluster" = 0;

      # Reclaim the VFS cache (directory/inode objects) less aggressively.
      "vm.vfs_cache_pressure" = 50;

      # SSD writeback: start background writeout at 64 MiB, throttle writers at
      # 256 MiB, and wake flushers less often (fewer disk wakeups).
      "vm.dirty_background_bytes" = 67108864;
      "vm.dirty_bytes" = 268435456;
      "vm.dirty_writeback_centisecs" = 1500;

      # Network + fs limits (inspired by CachyOS values).
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.netdev_max_backlog" = 4096;
      "fs.file-max" = 2097152;
    };

    # I/O scheduler: bfq for rotational disks, mq-deadline for SATA SSDs/eMMC,
    # kyber for NVMe (assignment inspired by CachyOS). No-op on the virtio disks of VMs.
    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"

      # SATA link power management: max_performance for responsiveness.
      ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_supported}=="1", ATTR{link_power_management_policy}=="*", ATTR{link_power_management_policy}="max_performance"
    '';

    # Transparent Huge Pages: defer defrag (helps tcmalloc-using applications).
    systemd.tmpfiles.rules = [
      "w! /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
    ];

    # Delegate CPU/memory/IO/pids control to user services (so user-managed
    # processes and containers can be scheduled properly), and raise the
    # per-process fd limit (Wine/Proton, browsers, dev tools).
    systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";
    systemd.settings.Manager.DefaultLimitNOFILE = "2048:2097152";

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
