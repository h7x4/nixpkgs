{ lib, stdenvNoCC, fetchurl }:
stdenvNoCC.mkDerivation {
  pname = "wireshark-delta-distance";
  version = "unstable-21-08-01";
  src = fetchurl {
    url = "https://gitlab.com/-/snippets/2156053/raw/main/delta_distance.lua";
    hash = "sha256-S0bkbK6ubyvmkkM9qoqjVDT0/g+mvPc9tdw9YMASbDQ=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm444 $src $out/lib/wireshark/plugins/delta_distance.lua

    runHook postInstall
  '';

  meta = {
    description = "Wireshark plugin to calculate the speed of light distance between packets.";
    homepage = "https://gitlab.com/-/snippets/2156053";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ h7x4 ];
    platforms = lib.platforms.all;
  };
}
