{ lib
, python3Packages
, fetchFromGitHub
}:
python3Packages.buildPythonApplication rec {
  pname = "rsactftool";
  version = "unstable-2023-11-01";
  src = fetchFromGitHub {
    owner = "RsaCtfTool";
    repo = "RsaCtfTool";
    rev = "3c01e8e805590e995d059641bc4fce2390651f8a";
    hash = "sha256-NZapUiawt/hZt26xAA3TTh0d4JlHymssjJ4hZ1wXtrw=";
  };

  propagatedBuildInputs = with python3Packages; [
    six
    cryptography
    urllib3
    requests
    gmpy2
    pycryptodome
    tqdm
    z3
    bitarray
    psutil
    # factordb-pycli
  ];

  meta = with lib; {
    homepage = "https://github.com/RsaCtfTool/RsaCtfTool";
    description = "RSA attack tool, mainly for ctf";
    license = licenses.beerware;
    maintainers = with maintainers; [ h7x4 ];
  };
}
