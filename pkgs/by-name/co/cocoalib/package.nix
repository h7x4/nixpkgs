{ lib
, stdenv
, fetchzip
# , autoconf
, which
, gmp
, boost
}:

stdenv.mkDerivation {
  pname = "cocoalib";
  version = "5.4.0";
  src = fetchzip {
    url = "https://cocoa.dima.unige.it/cocoa/cocoalib/tgz/CoCoALib-0.99800.tgz";
    hash = "sha256-HKphJKSYXXyYlrP8ZfEs5rXmB7K4DYD0qJo8nLQvuyQ=";
  };

  preConfigure = ''
    mkdir $out
    sed -i "s|/bin/||g" ./configure
    patchShebangs .
  '';

  nativeBuildInputs = [
    # autoconf
    which
  ];
  buildInputs = [
    gmp
    boost
  ];

  meta = with lib; {
    homepage = "https://cocoa.dima.unige.it/cocoa";
    description = "Library for comptutations in commutative algebra";
    maintainers = with maintainers; [ h7x4 ];
    platforms = with platforms; linux ++ darwin ++ cygwin;
  };
}
