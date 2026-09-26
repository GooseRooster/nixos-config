{
  lib,
  stdenv,
  src,
  glib,
}:

stdenv.mkDerivation {
  pname = "gnome-shell-extension-nowplaying";
  version = "unstable";

  inherit src;

  nativeBuildInputs = [ glib ];

  buildPhase = ''
    runHook preBuild
    # NOTE: operate on the unpacked source tree, not $src
    glib-compile-schemas --targetdir=schemas ./schemas
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    extdir="$out/share/gnome-shell/extensions/nowplaying@epogonii.github.io"
    mkdir -p "$extdir"
    cp ./*.js ./*.css ./metadata.json ./LICENSE "$extdir/"
    cp -r ./icons ./schemas "$extdir/"
    runHook postInstall
  '';

  passthru = {
    extensionUuid = "nowplaying@epogonii.github.io";
    extensionPortalSlug = "now-playing-card";
  };

  meta = with lib; {
    description = "Animated Now Playing indicator with a compact media card for any MPRIS player";
    homepage = "https://github.com/epogonii/nowplaying-card";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
