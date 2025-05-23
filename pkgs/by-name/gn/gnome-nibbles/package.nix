{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  gnome,
  gtk4,
  wrapGAppsHook4,
  librsvg,
  gsound,
  gettext,
  itstool,
  vala,
  libxml2,
  libadwaita,
  libgee,
  libgnome-games-support_2_0,
  meson,
  ninja,
  desktop-file-utils,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gnome-nibbles";
  version = "4.1.0";

  src = fetchurl {
    url = "mirror://gnome/sources/gnome-nibbles/${lib.versions.majorMinor finalAttrs.version}/gnome-nibbles-${finalAttrs.version}.tar.xz";
    hash = "sha256-YyQb2KFfWRgKYYEgQeLo85hiJn3J5lLz0XNULFUNkpI=";
  };

  nativeBuildInputs = [
    meson
    ninja
    vala
    pkg-config
    wrapGAppsHook4
    gettext
    itstool
    libxml2
    desktop-file-utils
  ];

  buildInputs = [
    gtk4
    librsvg
    gsound
    libadwaita
    libgee
    libgnome-games-support_2_0
  ];

  passthru = {
    updateScript = gnome.updateScript { packageName = "gnome-nibbles"; };
  };

  meta = with lib; {
    description = "Guide a worm around a maze";
    mainProgram = "gnome-nibbles";
    homepage = "https://gitlab.gnome.org/GNOME/gnome-nibbles";
    changelog = "https://gitlab.gnome.org/GNOME/gnome-nibbles/-/blob/${finalAttrs.version}/NEWS?ref_type=tags";
    license = licenses.gpl2Plus;
    teams = [ teams.gnome ];
    platforms = platforms.linux;
  };
})
