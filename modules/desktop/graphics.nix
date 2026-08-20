{ config, lib, pkgs, ... }:

let
  cfg = config.modules.graphics;
in
{
  options.modules.graphics = {
    enable = lib.mkEnableOption "GPU acceleration (OpenGL/Vulkan)";
    gaming = lib.mkEnableOption "gaming GPU extras (32-bit GL, VA-API/VDPAU)";
  };

  config = lib.mkIf cfg.enable {
    # GNOME does NOT enable this by itself; without it there is no hardware
    # GL/Vulkan, no /run/opengl-driver, and flatpak GPU apps can't accel.
    hardware.graphics.enable = true;

    # 32-bit drivers for Steam/Wine/older games (x86_64 only).
    hardware.graphics.enable32Bit = lib.mkIf cfg.gaming true;

    # VA-API <-> VDPAU interop (hardware video decode for some apps).
    # AMD ROCm OpenCL (e.g. for compute/blender) is huge — uncomment if wanted:
    #   rocmPackages.clr.icd
    hardware.graphics.extraPackages = lib.optionals cfg.gaming (with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
    ]);
  };
}
