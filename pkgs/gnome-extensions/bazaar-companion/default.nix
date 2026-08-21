{ lib, stdenv, src }:

stdenv.mkDerivation {
  pname = "gnome-shell-extension-bazaar-companion";
  version = "unstable";

  inherit src;

  installPhase = ''
    runHook preInstall
    extdir="$out/share/gnome-shell/extensions/bazaar-integration@kolunmi.github.io"
    mkdir -p "$extdir"
    cp -r "$src/src/." "$extdir/"
    runHook postInstall
  '';

  passthru = {
    extensionUuid = "bazaar-integration@kolunmi.github.io";
  };

  meta = with lib; {
    description = "Bazaar Companion: use Bazaar to view app details when right-clicking Flatpak applications";
    homepage = "https://github.com/bazaar-org/bazaar-companion";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
