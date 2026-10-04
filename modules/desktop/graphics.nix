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
    # Without this there is no hardware GL/Vulkan, no /run/opengl-driver, and
    # flatpak GPU apps can't accel.
    hardware.graphics.enable = true;

    # 32-bit drivers for Steam/Wine/older games (x86_64 only).
    hardware.graphics.enable32Bit = lib.mkIf cfg.gaming true;

    # Intel iGPUs need intel-media-driver (iHD) to expose a VA-API
    # *_drv_video.so. Mesa ships none for Intel, so without this
    # gpu-screen-recorder's vaInitialize fails and no h264/hevc encoder is
    # found (screenshots still work since they need no encoder). Harmless on
    # the AMD host, which gets its VA-API driver from mesa's radeonsi.
    #
    # VA-API <-> VDPAU interop (hardware video decode for some apps).
    # AMD ROCm OpenCL (e.g. for compute/blender) is huge — uncomment if wanted:
    #   rocmPackages.clr.icd
    hardware.graphics.extraPackages = (with pkgs; [ intel-media-driver ])
      ++ lib.optionals cfg.gaming (with pkgs; [
        libva-vdpau-driver
        libvdpau-va-gl
      ]);
  };
}
