{ lib, stdenvNoCC, fetchFromGitHub }:
stdenvNoCC.mkDerivation {
  pname = "wireshark-nix-dissector";
  version = "unstable-2023-09-15";
  src = fetchFromGitHub {
    owner = "picnoir";
    repo = "nix-dissector";
    rev = "a3e4418ebd776ffafdd2c4c364c60a348a9b19db";
    hash = "";
  };

  installPhase = ''
    runHook preInstall

    install -Dm444 nix-packet.lua -t $out/lib/wireshark/plugins

    runHook postInstall
  '';

  meta = with lib; {
    description = "Wireshark dissector for the Nix daemon protocol";
    homepage = "https://github.com/picnoir/nix-dissector";
    license = licenses.unfree;
    maintainers = with maintainers; [ h7x4 ];
    platforms = platforms.all;
  };
}
