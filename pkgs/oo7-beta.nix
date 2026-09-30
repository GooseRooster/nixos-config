# Overlay: oo7 0.7.0.beta (same packaging as nixpkgs, newer source).
#
# nixpkgs pins oo7 0.6.0, whose daemon deadlocks on ~50% of startups: it
# registers collections on D-Bus while still holding the collections lock, so an
# incoming call during init deadlocks. 0.7.0.beta fixes exactly that
# ("register on D-Bus after releasing it to avoid deadlocks with incoming
# calls") and also starts the PAM listener early (buffering secrets), which
# fixes the gnome-keyring->oo7 migration race. Consumed via `nixpkgs.overlays`
# so `services.oo7` (modules/desktop/noctalia.nix) picks these up.
final: prev:

let
  version = "0.7.0.beta";

  src = prev.fetchFromGitHub {
    owner = "linux-credentials";
    repo = "oo7";
    tag = version;
    hash = "sha256-HdKWP+4A7pJpGRMTIm6ST1H5PZLdbPz2sbTZv5+2LaA=";
  };

  oo7 = prev.rustPlatform.buildRustPackage {
    pname = "oo7";
    inherit version src;
    buildAndTestSubdir = "cli";
    cargoHash = "sha256-X+yNxuVqfOo9uSPx3FZ9RlIg7sQJTK6xNiLgsxENWac=";
    nativeBuildInputs = [ prev.pkg-config ];

    meta = {
      description = "James Bond went on a new mission as a Secret Service provider";
      homepage = "https://github.com/linux-credentials/oo7";
      license = prev.lib.licenses.mit;
      platforms = prev.lib.platforms.linux;
      mainProgram = "oo7-cli";
    };
  };

  component =
    pname: subdir: extra:
    prev.stdenv.mkDerivation (
      finalAttrs:
      {
        inherit pname;
        inherit (oo7) version src cargoDeps;

        sourceRoot = "${finalAttrs.src.name}/${subdir}";
        cargoRoot = "../";

        nativeBuildInputs = with prev; [
          pkg-config
          meson
          ninja
          rustPlatform.cargoSetupHook
          rustc
          cargo
        ];

        buildInputs = [ prev.systemdLibs ];

        meta = {
          inherit (oo7.meta) homepage license platforms;
          description = "${oo7.meta.description} (${pname})";
        };
      }
      // extra
    );
in
{
  oo7 = oo7;

  oo7-server = component "oo7-server" "server" {
    postFixup = ''
      substituteInPlace "$out/share/systemd/user/oo7-daemon.service" \
        --replace-fail "$out/libexec/oo7-daemon" "/run/wrappers/bin/oo7-daemon"
    '';
  };

  oo7-portal = component "oo7-portal" "portal" { };

  oo7-pam = component "oo7-pam" "pam" {
    strictDeps = true;
    separateDebugInfo = true;
    # 0.7's pam module links against libpam (0.6 did not).
    buildInputs = [
      prev.systemdLibs
      prev.pam
    ];
  };
}
