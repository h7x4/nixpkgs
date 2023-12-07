{ lib
, stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hash-library";
  version = "8";
  src = fetchFromGitHub {
    owner = "stbrumme";
    repo = "hash-library";
    rev = "hash_library_v${finalAttrs.version}";
    hash = "sha256-z4JzmggZnNfsTD8OzBiX4egJax4qJXGYr2Q8GPrInRI=";
  };

  meta = with lib; {
    homepage = "https://create.stephan-brumme.com/hash-library";
    maintainers = with maintainers; [ h7x4 ];
    platforms = platforms.linux ++ platforms.windows;
    license = licenses.zlib;
  };
})
