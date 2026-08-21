{ lib, stdenv, src, glib }:

stdenv.mkDerivation {
  pname = "gnome-shell-extension-paperwm";
  version = "unstable";

  inherit src;

  nativeBuildInputs = [ glib ];

  buildPhase = ''
    runHook preBuild
    glib-compile-schemas --targetdir=schemas "$src/schemas"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    extdir="$out/share/gnome-shell/extensions/paperwm@paperwm.github.com"
    mkdir -p "$extdir"
    cp "$src"/*.js "$src"/*.ui "$src"/stylesheet.css "$src"/metadata.json "$src"/LICENSE "$extdir/"
    cp -r "$src"/resources "$src"/config "$extdir/"
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
