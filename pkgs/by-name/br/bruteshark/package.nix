{ lib
, buildDotnetModule
, fetchFromGitHub
, dotnetCorePackages
}:

buildDotnetModule rec {
  pname = "bruteshark-cli";
  version = "1.2.5";

  src = fetchFromGitHub {
    owner = "odedshimon";
    repo = "BruteSHark";
    rev = "v${version}";
    hash = "sha256-dZ1PGZwRUH7uUDUEMxuAN+Xwt6CrcsYua+2yRHAZr18=";
  };

  dotnet-sdk = dotnetCorePackages.sdk_7_0;
  dotnet-runtime = dotnetCorePackages.runtime_7_0;

  projectFile = "BruteShark/BruteSharkCli/BruteSharkCli.csproj";
  nugetDeps = ./deps.nix;
  executables = "BruteSharkCli";

  meta = with lib; {
    description = "Network Forensic Analysis Tool for deep packet inspection";
    homepage = "https://github.com/odedshimon/BruteShark";
    license = licenses.gpl3Only;
    changelog = "https://github.com/odedshimon/BruteShark/releases/tag/${version}";
    maintainers = with maintainers; [ h7x4 ];
    platforms = with platforms; linux ++ windows;
    # mainProgram = "NickvisionMoney.GNOME";
  };
}
