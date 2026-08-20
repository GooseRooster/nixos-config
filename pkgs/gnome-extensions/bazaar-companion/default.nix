{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "gnome-shell-extension-bazaar-companion";
  version = "unstable-2026-04-30";

  src = fetchFromGitHub {
    owner = "bazaar-org";
    repo = "bazaar-companion";
    # Update: bump `rev`, rebuild, paste the "got sha256-..." nix reports here.
    rev = "3bb9134985343ffd1993520eb37c90e113bfb09b";
    hash = "sha256-t3lhCwbhrFivYZP1FfY304RurmfT+zb0r3Gy4F+wWGk=";
  };

  installPhase = ''
    runHook preInstall
    extdir="$out/share/gnome-shell/extensions/bazaar-integration@kolunmi.github.io"
    mkdir -p "$extdir"
    cp -r src/. "$extdir/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Bazaar Companion: use Bazaar to view app details when right-clicking Flatpak applications";
    homepage = "https://github.com/bazaar-org/bazaar-companion";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
