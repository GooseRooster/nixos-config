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

    # Source dirs are read-only; make the copy writable so we can prune files.
    chmod -R u+w "$out/share/icons"

    # Keep Adwaita's stock "Show Applications" glyph: drop Hatter's override so
    # the Inherits= chain (Hatter-* -> Hatter -> Adwaita) resolves it.
    find "$out/share/icons" -name 'view-app-grid-symbolic.svg' -delete

    # Remove shipped caches so GTK/NixOS regenerates them from the patched tree
    # (a stale cache would otherwise keep serving the removed icon).
    find "$out/share/icons" \( -name 'icon-theme.cache' -o -name '.icon-theme.cache' \) -delete
    runHook postInstall
  '';

  meta = with lib; {
    description = "Rounded square icon theme that integrates with GNOME aesthetics";
    homepage = "https://github.com/Mibea/Hatter";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
