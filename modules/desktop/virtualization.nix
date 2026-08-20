{ config, lib, pkgs, ... }:

{
  # libvirtd + QEMU/KVM. Needed by GNOME Boxes (flatpak) and virt-manager to
  # actually run VMs — the Boxes flatpak talks to the system libvirt daemon.
  virtualisation.libvirtd.enable = true;
}
