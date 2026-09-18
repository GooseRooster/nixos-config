{ lib, stdenv, src, glib }:

stdenv.mkDerivation {
  pname = "gnome-shell-extension-paperwm";
  version = "unstable";

  # Mitigations for gnome-shell SIGSEGV in meta_window_update_monitor() during
  # workspace switches (windows unmanaging while PaperWM's async callbacks run).
  # Remove together with the upstream PR.
  patches = [ ./stale-window-guards.patch ];

  inherit src;

  nativeBuildInputs = [ glib ];

  buildPhase = ''
    runHook preBuild
    # NOTE: operate on the unpacked (and patched) source tree, not $src
    glib-compile-schemas --targetdir=schemas ./schemas
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    extdir="$out/share/gnome-shell/extensions/paperwm@paperwm.github.com"
    mkdir -p "$extdir"
    cp ./*.js ./*.ui ./stylesheet.css ./metadata.json ./LICENSE "$extdir/"
    cp -r ./resources ./config "$extdir/"
    cp -r schemas "$extdir/"
    runHook postInstall
  '';

  passthru = {
    extensionUuid = "paperwm@paperwm.github.com";
    extensionPortalSlug = "paperwm";
  };

  meta = with lib; {
    description = "Tiled scrollable window management for GNOME Shell";
    homepage = "https://github.com/paperwm/PaperWM";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
