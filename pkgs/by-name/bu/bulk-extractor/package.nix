{ lib
, stdenv
, fetchFromGitHub
, autoconf
, automake
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "bulk-extractor";
  version = "2.0.3";
  src = fetchFromGitHub {
    owner = "simsong";
    repo = "bulk_extractor";
    rev = "v${finalAttrs.version}";
    hash = "sha256-T1EOa+HehmCytD9ZQx/F6TNEXt7mMNWu7tqYPZII3N0=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ autoconf automake ];

  preConfigure = ''
    ./bootstrap.sh
  '';

  meta = with lib; {
    homepage = "https://github.com/simsong/bulk_extractor";
    description = "A high-performance digital forensics exploitation tool";
    changelog = "https://github.com/simsong/bulk_extractor/releases/tag/${finalAttrs.src.rev}";
    platforms = platforms.linux;
    license = with licenses; [
      mit
      cpl10
      gpl3Plus
      lgpl21Only
      lgpl3Plus
    ];
    maintainers = with maintainers; [ h7x4 ];
  };
})
