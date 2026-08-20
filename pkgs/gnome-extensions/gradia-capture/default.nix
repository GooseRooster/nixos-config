{ lib, stdenv, fetchFromGitHub, glib }:

stdenv.mkDerivation {
  pname = "gnome-shell-extension-gradia-capture";
  version = "unstable-2026-04-30";

  src = fetchFromGitHub {
    owner = "AlexanderVanhee";
    repo = "gradia-capture";
    # Update: bump `rev`, rebuild, paste the "got sha256-..." nix reports here.
    rev = "9e441493a132e9f38d3a7fdf5d7f0d55a0a36369";
    hash = "sha256-AEcVobmzcCS8CxsZ4nHnSB464v43/gnvs0S082jn8C0=";
  };

  nativeBuildInputs = [ glib ];

  buildPhase = ''
    runHook preBuild
    glib-compile-schemas --targetdir=schemas schemas
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    extdir="$out/share/gnome-shell/extensions/gradia-integration@alexandervanhee.github.io"
    mkdir -p "$extdir"
    cp -r src/. "$extdir/"
    cp -r icons "$extdir/"
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
