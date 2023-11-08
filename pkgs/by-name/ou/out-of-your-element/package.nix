{ lib
, buildNpmPackage
, fetchNpmDeps
, fetchFromGitea
, git
, cacert
}:
# fetchNpmDeps {
#   name = "out-of-your-element-deps";
#   src = fetchFromGitea {
#     domain = "gitdab.com";
#     owner = "cadence";
#     repo = "out-of-your-element";
#     rev = "v1.3";
#     hash = "sha256-dLDm3xOMoprkGU7D9IFX1hjMfCR3YjVgXb3c5IEuUTQ";
#   };

#   patches = [ ./add-discord-markdown-dep-integrity.patch ];

  # npmDepsHash = "sha256-k2MeejRWteIzY1Q+iNLCLDLnE1z9+cBaAGYAIlQHa/4=";
# };
buildNpmPackage rec {
  pname = "out-of-your-element";
  version = "1.3";
  src = fetchFromGitea {
    domain = "gitdab.com";
    owner = "cadence";
    repo = "out-of-your-element";
    rev = "v${version}";
    hash = "sha256-dLDm3xOMoprkGU7D9IFX1hjMfCR3YjVgXb3c5IEuUTQ";
  };

  patches = [ ./add-discord-markdown-dep-integrity.patch ];

  # makeCacheWritable = true;

  # outputHashAlgo = "sha256";
  # outputHashMode = "recursive";
  # outputHash = "";

  # npmBuildScript = "build:prod";
  dontNpmBuild = true;
  # forceGitDeps = true;
  npmDepsHash = "sha256-fPTFyX2GYSdMeIzVKXBacZxhTTj8fvlMFEGOxN0/cm8=";

  # nativeBuildInputs = [ git cacert ];
  # nativeBuildInputs = [ makeWrapper ];

  # postInstall = ''
  #   makeWrapper ${electron}/bin/electron $out/bin/uivonim \
  #     --add-flags $out/lib/node_modules/uivonim/build/main/main.js
  # '';

  meta = with lib; {
    homepage = "https://gitdab.com/cadence/out-of-your-element";
    description = "Modern Matrix-to-Discord appservice bridge";
    changelog = "https://gitdab.com/cadence/out-of-your-element/releases/tag/${src.rev}";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ h7x4 dandellion ];
    mainProgram = "start.js";
  };
}
