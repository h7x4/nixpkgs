{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "github-exporter";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "githubexporter";
    repo = "github-exporter";
    rev = version;
    sha256 = "sha256-/3SyHFCXPmRpZ42JLqFvgAYTth4BIuGnXQmYsj1K23I=";
  };

  vendorSha256 = "sha256-ZO9Dq9tuNP+262eEwBzptBMNtGIxkc7y4MCwMnRSTnE=";

  meta = with lib; {
    description = "Prometheus exporter for GitHub metrics ";
    homepage = "https://github.com/githubexporter/github-exporter";
    license = licenses.mit;
    maintainers = with maintainers; [ h7x4 ];
  };
}
