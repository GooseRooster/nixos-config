{ lib, stdenv, src }:

stdenv.mkDerivation {
  pname = "hatter-icon-theme";
  version = "unstable";

  inherit src;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/icons"
    # All GNOME variants; the Hatter-kde* dirs are KDE-only flavours.
    for theme in "$src"/Hatter*; do
      case "$(basename "$theme")" in
        Hatter-kde*) ;;
        *) cp -r "$theme" "$out/share/icons/" ;;
      esac
    done
    runHook postInstall
  '';

  meta = with lib; {
    description = "Rounded square icon theme that integrates with GNOME aesthetics";
    homepage = "https://github.com/Mibea/Hatter";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
