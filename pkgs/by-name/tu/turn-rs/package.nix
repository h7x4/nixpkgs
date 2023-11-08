{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, openssl
}:
rustPlatform.buildRustPackage rec {
  pname = "turn-rs";
  version = "1.1.2";
  src = fetchFromGitHub {
    owner = "mycrl";
    repo = "turn-rs";
    rev = version;
    hash = "sha256-3EGJ9R28cHEKxUSPDOtAQ3gox7n/mWNv6uDYIrbNV2Y=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  cargoPatches = [ ./Cargo.lock.patch ];
  cargoSha256 = "sha256-Ykx37mWTTTCps488J68QOtBG4kOW5G/r39efPvRdg7A=";

  postInstall = ''
    install -Dm444 $src/turn-server.service -t $out/lib/systemd/system
  '';

  meta = with lib; {
    homepage = "https://github.com/mycrl/turn-rs";
    description = "A pure rust-implemented turn server";
    license = licenses.mit;
    maintainers = with maintainers; [ h7x4 ];
    mainProgram = "turn-server";
  };
}
