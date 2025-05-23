{
  lib,
  appdirs,
  build,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  hatch-vcs,
  magicgui,
  napari, # reverse dependency, for tests
  pydantic,
  pythonOlder,
  pytomlpp,
  pyyaml,
  rich,
  typer,
  tomli-w,
}:

buildPythonPackage rec {
  pname = "napari-npe2";
  version = "0.7.8";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "napari";
    repo = "npe2";
    tag = "v${version}";
    hash = "sha256-J15CmJ1L173M54fCo4oTV9XP7946c0aHzLqKjTvzG0g=";
  };

  build-system = [
    hatchling
    hatch-vcs
  ];

  dependencies = [
    appdirs
    build
    magicgui
    pydantic
    pytomlpp
    pyyaml
    rich
    typer
    tomli-w
  ];

  pythonImportsCheck = [ "npe2" ];

  passthru.tests = {
    inherit napari;
  };

  meta = with lib; {
    description = "Plugin system for napari (the image visualizer)";
    homepage = "https://github.com/napari/npe2";
    license = licenses.bsd3;
    maintainers = with maintainers; [ SomeoneSerge ];
    mainProgram = "npe2";
  };
}
