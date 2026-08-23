{ config, lib, pkgs, ... }:

let
  cfg = config.modules.hardening;
in
{
  options.modules.hardening.enable =
    lib.mkEnableOption "moderate system hardening (kernel, sudo, ssh)";

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl = {
      # Hide kernel pointers from unprivileged users and restrict dmesg.
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;

      # Harden symlink/hardlink following in world-writable dirs.
      "fs.protected_hardlinks" = 1;
      "fs.protected_symlinks" = 1;

      # TCP/IP hardening.
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
    };

    boot.kernelParams = [
      "slab_nomerge"        # prevent merging of slab caches of similar objects
      "init_on_alloc=1"     # zero out newly allocated memory
      "init_on_free=1"      # zero out freed memory
      "page_alloc.shuffle=1" # randomize page allocator freelists
    ];

    # Prevent loading kernel modules post-boot and protect the kernel image.
    security.lockKernelModules = true;
    security.protectKernelImage = true;

    # Flatpak (bwrap) and the nix sandbox both need user namespaces.
    security.allowUserNamespaces = lib.mkDefault true;

    # Restrict sudo to the wheel group, requiring a password.
    security.sudo = {
      execWheelOnly = true;
      wheelNeedsPassword = true;
    };

    # SSH: key-only, no root login. NOTE: this means the VM's initial
    # `ssh goose@<vm-ip>` with a password no longer works — provision an SSH
    # key first, or comment this block out while testing.
    services.openssh.settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
