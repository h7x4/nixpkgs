{
  lib
, rustPlatform
, fetchFromGitHub
, nix-update-script
}:

rustPlatform.buildRustPackage rec {
  pname = "data-surgeon";
  version = "1.2.7";

  src = fetchFromGitHub {
    owner = "Drew-Alleman";
    repo = "DataSurgeon";
    rev = version;
    hash = "sha256-mqD8pxLFeFPvetE7M4NOAhoDiekDmBnUUO1SaO34bqo=";
  };

  cargoHash = "sha256-01nVGhau1s7DnU2QwTRnWcp8rjqr/btXEO24GQkSLyM=";

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Data extractor, designed for cyber security";
    homepage = "https://github.com/Drew-Alleman/DataSurgeon";
    license = licenses.asl20;
    maintainers = with maintainers; [ h7x4 ];
    platforms = platforms.unix;
    mainProgram = "ds";
  };
}
