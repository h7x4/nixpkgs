{ lib, stdenvNoCC, fetchFromGitHub }:
stdenvNoCC.mkDerivation {
  pname = "wireshark-packet-simplemessage";
  version = "unstable-23-02-23";
  src = fetchFromGitHub {
    owner = "ros-industrial";
    repo = "packet-simplemessage";
    rev = "b3a655b227a76e29912b8148020908202fc9d4cb";
    hash = "sha256-U06U8GbFVHhyFpTMgIoRG61Hr2cmdmcOWxgDtjkFIjw=";
  };

  installPhase = ''
    runHook preInstall

    find . -type f -name '*.lua' -exec install -Dm444 \{} $out/lib/wireshark/plugins/\{} \;

    runHook postInstall
  '';

  meta = {
    description = "Wireshark Lua dissector for the ROS-Industrial SimpleMessage protocol.";
    homepage = "https://github.com/ros-industrial/packet-simplemessage";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ h7x4 ];
    platforms = lib.platforms.all;
  };
}
