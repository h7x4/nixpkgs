{
  stdenv,
  lib,
  fetchurl,
  gzip,
  autoPatchelfHook,
  versionCheckHook,
}:
let

  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  plat =
    {
      x86_64-linux = "linux_x64";
      aarch64-linux = "linux_arm";
      x86_64-darwin = "macos_x64";
      aarch64-darwin = "macos_arm";

    }
    .${system} or throwSystem;

  hash =
    {
      x86_64-linux = "sha256-AwUOA9U8Bdm+eyxt77i6qW6XXbWkZ7Gvf8IpCXT0/MY=";
      aarch64-linux = "sha256-og6sHzUsh8zo5r5TBAp1prTN9YeldV3jQVlEwVqfTCQ=";
      x86_64-darwin = "sha256-aaa/CVXFb8iE8oKABwJOzSBA1aV8X7camfXsHNonh6M=";
      aarch64-darwin = "sha256-oDOhtTb0TdHFXOsJD/XPO4aso6Gk1ngvBWKKkNy21RE=";
    }
    .${system} or throwSystem;

  bin = "$out/bin/codeium_language_server";

in
stdenv.mkDerivation (finalAttrs: {
  pname = "codeium";
  version = "1.38.0";
  src = fetchurl {
    name = "${finalAttrs.pname}-${finalAttrs.version}.gz";
    url = "https://github.com/Exafunction/codeium/releases/download/language-server-v${finalAttrs.version}/language_server_${plat}.gz";
    inherit hash;
  };

  nativeBuildInputs = [ gzip ] ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    gzip -dc $src > ${bin}
    chmod +x ${bin}
    runHook postInstall
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  versionCheckProgram = "${placeholder "out"}/bin/codeium_language_server";
  versionCheckProgramArg = [ "--version" ];
  doInstallCheck = true;

  passthru.updateScript = ./update.sh;

  meta = rec {
    description = "Codeium language server";
    longDescription = ''
      Codeium proprietary language server, patched for Nix(OS) compatibility.
      bin/language_server_x must be symlinked into the plugin directory, replacing the existing binary.
      For example:
      ```shell
      ln -s "$(which codeium_language_server)" /home/a/.local/share/JetBrains/Rider2023.1/codeium/662505c9b23342478d971f66a530cd102ae35df7/language_server_linux_x64
      ```
    '';
    homepage = "https://codeium.com/";
    downloadPage = homepage;
    changelog = homepage;
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ anpin ];
    mainProgram = "codeium_language_server";
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
      "x86_64-darwin"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
