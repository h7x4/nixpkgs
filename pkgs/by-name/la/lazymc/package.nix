{ lib
, rustPlatform
, fetchFromGitHub
, nix-update-script

, writeShellScriptBin

, formats

, minecraft-server
, lazymcConfig ? { }
}:

let
  unwrapped = rustPlatform.buildRustPackage rec {
    pname = "lazymc";
    version = "0.2.10";

    src = fetchFromGitHub {
      owner = "timvisee";
      repo = "lazymc";
      rev = "v${version}";
      hash = "sha256-IObLjxuMJDjZ3M6M1DaPvmoRqAydbLKdpTQ3Vs+B9Oo=";
    };

    cargoLock = {
      lockFile = ./Cargo.lock;
      outputHashes = {
        "minecraft-protocol-0.1.0" = "sha256-vSFS1yVxTBSpx/ZhzA3EjcZyOWHbmoGARl0eMn1fJ+4=";
      };
    };

    passthru.updateScript = nix-update-script { };

    meta = with lib; {
      description = "Remote wake-up daemon for minecraft servers";
      homepage = "https://github.com/timvisee/lazymc";
      license = licenses.gpl3Only;
      maintainers = with maintainers; [ h7x4 dandellion ];
      platforms = platforms.unix;
      mainProgram = "lazymc";
    };  
  };

  startCommand = writeShellScriptBin "lazymc-launch" ''
    trap 'kill -TERM $PID' TERM INT
    ${minecraft-server} &

    PID=$!
    wait $PID
    trap - TERM INT
    wait $PID
  '';

  defaultConfig = {
    server = {
      directory = "/var/lib/minecraft";
      command = startCommand;
    };
  };

  mergedConfig = lib.attrsets.recursiveUpdate defaultConfig lazymcConfig;

  configFile = (formats.toml { }).generate "lazymc-config.toml" mergedConfig;
  
in writeShellScriptBin "minecraft-server" ''
  exec ${lib.getExe unwrapped} -c ${configFile}
''
