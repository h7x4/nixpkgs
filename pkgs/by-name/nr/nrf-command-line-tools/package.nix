{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  udev,
  libusb1,
  segger-jlink-headless,
}:

let
  supported = {
    x86_64-linux = {
      name = "linux-amd64";
      hash = "sha256-nWWw2A/MtWdmj6QVhckmGUexdA9S66jTo2jPb4/Xt5M=";
    };
    aarch64-linux = {
      name = "linux-arm64";
      hash = "sha256-Vo0be6w1+8qgMg71DfxPqU1nJEFjYoSrUyoF10vGA9Q=";
    };
    armv7l-linux = {
      name = "linux-armhf";
      hash = "sha256-J3b0edvncvTVyLZCAdXohBoPZiqO7yCPi9r1mSjP88Q=";
    };
  };

  platform = supported.${stdenv.system} or (throw "unsupported platform ${stdenv.system}");

  version = "10.24.2";

  url =
    let
      versionWithDashes = builtins.replaceStrings [ "." ] [ "-" ] version;
    in
    "https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-${lib.versions.major version}-x-x/${versionWithDashes}/nrf-command-line-tools-${version}_${platform.name}.tar.gz";

in
stdenv.mkDerivation {
  pname = "nrf-command-line-tools";
  inherit version;

  src = fetchurl {
    inherit url;
    inherit (platform) hash;
  };

  runtimeDependencies = [
    segger-jlink-headless
  ];

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    udev
    libusb1
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    rm -rf ./python
    mkdir -p $out
    cp -r * $out

    runHook postInstall
  '';

  meta = with lib; {
    description = "Nordic Semiconductor nRF Command Line Tools";
    homepage = "https://www.nordicsemi.com/Products/Development-tools/nRF-Command-Line-Tools";
    license = licenses.unfree;
    platforms = attrNames supported;
    maintainers = with maintainers; [ stargate01 ];
  };
}
