{ lib, stdenvNoCC, fetchFromGitHub }:
stdenvNoCC.mkDerivation {
  pname = "wireshark-usb-keyboard-dissector";
  version = "unstable-21-08-24";
  src = fetchFromGitHub {
    owner = "hawkfeather";
    repo = "wireshark-usb_keyboard_dissector";
    rev = "48aa3a9f8933a78a4e308547489ff74c1efbed20";
    hash = "sha256-Mk66IEp9WqiW7vX3BPd/4wq0KATsD3eE8o/vRIgKRqY=";
  };

  installPhase = ''
    runHook preInstall

    install -Dm444 usb_keyboard_dissector.lua $out/lib/wireshark/plugins/usb_keyboard_dissector.lua

    runHook postInstall
  '';

  meta = {
    description = "Wireshark plugin to extract h264 or opus stream from rtp packets.";
    homepage = "https://github.com/hawkfeather/wireshark-usb_keyboard_dissector";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ h7x4 ];
    platforms = lib.platforms.all;
  };
}
