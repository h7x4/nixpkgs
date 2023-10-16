{ lib, stdenvNoCC, fetchFromGitHub }:
stdenvNoCC.mkDerivation {
  pname = "wireshark-h264extractor";
  version = "unstable-23-07-13";
  src = fetchFromGitHub {
    owner = "volvet";
    repo = "h264extractor";
    rev = "4e74464dddb175c140335f4e0df0da9703e6402c";
    hash = "sha256-4MXbpfe50LUkQRJsWdF9RKsHfqYtfxp/N4wenw/MtT4=";
  };

  installPhase = ''
    runHook preInstall

    find . -type f -name '*.lua' -exec install -Dm444 \{} $out/lib/wireshark/plugins/\{} \;

    runHook postInstall
  '';

  meta = {
    description = "Wireshark plugin to extract h264 or opus stream from rtp packets.";
    homepage = "https://github.com/volvet/h264extractor";
    license = lib.licenses.lgpl21;
    maintainers = with lib.maintainers; [ h7x4 ];
    platforms = lib.platforms.all;
  };
}
