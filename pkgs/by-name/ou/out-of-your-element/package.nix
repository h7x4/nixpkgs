{ lib
, nodejs
, buildNpmPackage
, fetchNpmDeps
, fetchFromGitea
, makeWrapper
}:
buildNpmPackage rec {
  pname = "out-of-your-element";
  version = "2.3";
  src = fetchFromGitea {
    domain = "gitdab.com";
    owner = "cadence";
    repo = "out-of-your-element";
    rev = "v${version}";
    hash = "sha256-zKJAgbCiHRPeuGFo7vcJeNJYGyOde/dqALzd8W3L2bU=";
  };

  dontPatchELF = true;
  dontNpmBuild = true;
  npmDepsHash = "sha256-RtE1P/qTYyvb1setxOd2N5efPF0X0GIkVoaLgLxPuk8=";

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    startjs="$out/lib/node_modules/out-of-your-element/start.js"
    echo "$(echo '#!${lib.getExe nodejs}'; cat "$startjs")" > "$startjs"
    chmod +x "$startjs"
    makeWrapper "$startjs" "$out/bin/ooye"

    for script in "$out"/lib/node_modules/out-of-your-element/scripts/*.js; do
      echo "$(echo '#!${lib.getExe nodejs}'; cat "$script")" > "$script"
      chmod +x "$script"
      basename=$(basename "$script")
      makeWrapper "$script" "$out/bin/ooye-''${basename%.*}"
    done
  '';

  meta = with lib; {
    homepage = "https://gitdab.com/cadence/out-of-your-element";
    description = "Modern Matrix-to-Discord appservice bridge";
    changelog = "https://gitdab.com/cadence/out-of-your-element/releases/tag/${src.rev}";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ h7x4 dandellion ];
    mainProgram = "ooye";
  };
}
