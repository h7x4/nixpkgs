{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "github-exporter";
  version = "2.3.0";

  src = fetchFromGitHub {
    owner = "promhippie";
    repo = "github_exporter";
    rev = "v${version}";
    sha256 = "sha256-51/V5neiqQTqafQ2AYhUxTTiKpzioCkaq3noYy8qRFg=";
  };

  vendorHash = "sha256-CdT4noTYbax+enN81AQTUDjlJ+M4pvoiPR6iUzYURMI=";

  ldflags = let t = "github.com/${src.owner}/${src.repo}/pkg/version"; in [
    "-s" "-w"
    "-X ${t}.String=${version}"
    "-X ${t}.Revision=${src.rev}"
    "-X ${t}.Date=unknown"
  ];

  meta = with lib; {
    description = "Prometheus exporter for GitHub";
    homepage = "https://github.com/promhippie/github_exporter";
    license = licenses.asl20;
    maintainers = with maintainers; [ h7x4 ];
  };
}
