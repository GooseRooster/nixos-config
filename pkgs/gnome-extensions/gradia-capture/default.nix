{ lib, stdenv, src, glib }:

stdenv.mkDerivation {
  pname = "gnome-shell-extension-gradia-capture";
  version = "unstable";

  inherit src;

  nativeBuildInputs = [ glib ];

  buildPhase = ''
    runHook preBuild
    mkdir -p schemas
    glib-compile-schemas --targetdir=schemas "$src/schemas"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    extdir="$out/share/gnome-shell/extensions/gradia-integration@alexandervanhee.github.io"
    mkdir -p "$extdir"
    cp -r "$src/src/." "$extdir/"
    cp -r "$src/icons" "$extdir/"
    cp -r schemas "$extdir/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Gradia Capture: enhances GNOME's built-in screenshot tool with annotation features";
    homepage = "https://github.com/AlexanderVanhee/gradia-capture";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
