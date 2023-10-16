{ lib, stdenvNoCC, fetchFromGitHub }:
stdenvNoCC.mkDerivation {
  pname = "wireshark-ffxiv-packet-dissector";
  version = "unstable-22-05-27";
  src = fetchFromGitHub {
    owner = "zhyupe";
    repo = "FFXIV-Packet-Dissector";
    rev = "4a998e94fcb770092d9985e197fe88205e472da3";
    hash = "sha256-PWadpySJIaaOIlwrBF9+C8rFjEc4ry1Nw4QAAjx7cjw=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/wireshark/plugins
    cp src/*.lua $out/lib/wireshark/plugins
    chmod 444 $out/lib/wireshark/plugins/*.lua

    runHook postInstall
  '';

  meta = {
    description = "Wireshark plugins for dissecting FFXIV packets.";
    homepage = "https://github.com/ros-industrial/packet-simplemessage";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ h7x4 ];
    platforms = lib.platforms.all;
  };
}
