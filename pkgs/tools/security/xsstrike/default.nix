{ lib,

  buildPythonPackage,
  fetchFromGitHub,

  python,
  tld,
  fuzzywuzzy,
  requests,
}:
buildPythonPackage rec {
  name = "xsstrike";
  version = "3.1.5";
  src = fetchFromGitHub {
    owner = "s0md3v";
    repo = "XSStrike";
    rev = version;
    hash = "sha256-4eMoQdW7TAb7DDfqtuzCk6gas5ragx2OkfPpc/DbixY=";
  };

  # format = "other";

    preBuild = ''
    cat > setup.py << EOF
from setuptools import setup

with open('requirements.txt') as f:
    install_requires = f.read().splitlines()

setup(
  name='${name}',
  #packages = ['someprogram'],
  packages = [
    'core',
    'db',
    'modes',
    'plugins',
  ],
  version = '${version}',
  author = 's0md3v',
  #description = '...',
  install_requires = install_requires,
  scripts = [
    'xsstrike.py',
  ],
  entry_points = {
    # example: file some_module.py -> function main
    #'console_scripts': ['someprogram=some_module:main']
  },
)
EOF
  '';

  # installPhase = ''
  #   runHook preInstall

  #   # mkdir -p $out/lib/${python.libPrefix}/site-packages/
  #   # cp -r core db modes plugins $out/lib/${python.libPrefix}/site-packages/
  #   # install -Dm555 xsstrike.py $out/bin/xsstrike

  #   runHook postInstall
  # '';

  propagatedBuildInputs = [
    tld
    fuzzywuzzy
    requests
  ];

  meta = with lib; {
    description = "Cross Site Scripting detection suite";
    homepage = "https://github.com/s0md3v/XSStrike";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ h7x4 ];
    platforms = platforms.all;
  };
}
