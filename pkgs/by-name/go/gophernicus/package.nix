{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gophernicus";
  version = "3.1.1";

  src = fetchFromGitHub {
    owner = "gophernicus";
    repo = "gophernicus";
    tag = finalAttrs.version;
    hash = "sha256-pweiUiMmLXiyF9NMxvcWfJPH6JiGRlpT4chJiRGh9vg=";
  };

  postPatch = ''
    substituteInPlace README.md \
      --replace-warn 'DEVEL' '${finalAttrs.version}'

    substituteInPlace src/gophernicus.h \
      --replace-fail 'SAFE_PATH    "/usr/bin:/bin"' 'SAFE_PATH    "/usr/bin:/bin:/run/gophernicus/bin"'
  '';

  configureFlags = [
    "--gopherroot=${placeholder "out"}/share/gophernicus/gopher"
    "--systemd=${placeholder "out"}/lib/systemd/system"
    "--sysconfig=${placeholder "out"}/etc/default"
    "--default=${placeholder "out"}/etc/default"
    "--listener=systemd"
  ];

  installTargets = [
    "install"
    "install-systemd"
  ];

  postInstall = ''
    sed -i '/User=nobody/d' "$out"/lib/systemd/system/gophernicus@.service
  '';

  meta = {
    description = "A modern full-featured (and hopefully) secure gopher daemon";
    homepage = "https://gophernicus.org/";
    changelog = "https://github.com/gophernicus/gophernicus/blob/${finalAttrs.src.tag}/changelog";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
    maintainers = [ lib.maintainers.h7x4 ];
    mainProgram = "gophernicus";
  };
})

