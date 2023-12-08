{ lib
, fetchzip
, type ? "cwj"
, full ? true
}:

assert lib.elem type [ "cwj" "csj" ];

let
  version = "3.1.0";

  hash = {
    cwj.plain = "sha256-AkYlUJAgkIAlJLdeSQKesv3/2XXfA+4hmcXi14OdvKM=";
    cwj.full = "sha256-UrGeSjhlqP94WkppqDi1V777FF310pPNWKI5IZ2Zjo8=";
    csj.plain = "sha256-rePxqhIU8EX00FXEqg6YVVzCgxJfjf2YEiK+iw60G+A=";
    csj.full = " sha256-YRWTRC6s+ZyUhwruZt8g5Lm1hjxI4urbhVhNcxFYOss=";
  }.${type}.${if full then "full" else "plain"};
in

fetchzip rec {
  pname = "unidic-${type}${lib.optionalString full "-full"}";
  url = "https://clrd.ninjal.ac.jp/unidic_archive/${type}/${version}/unidic-${type}-${version}${lib.optionalString full "-full"}.zip";
  inherit hash version;

  postFetch = ''
    shopt -s extglob

    mkdir -p $out/share/dicdir/unidic-cwj
    mv $out/!(share) $out/share/dicdir/unidic-cwj

    echo "unidic-${version}" > $out/share/dicdir/unidic-cwj/version
    touch $out/share/dicdir/unidic-cwj/mecabrc

    find $out/ -type d -exec chmod 555 {} \;
    find $out/ -type f -exec chmod 444 {} \;

    shopt -u extglob
  '';
  meta = with lib; {
    homepage = "https://clrd.ninjal.ac.jp/unidic/en/";
    description = "Annotated japanese dictionary for morphological analysis";
    platforms = platforms.all;
    maintainers = with maintainers; [ h7x4 ];
    license = with licenses; [ gpl2Only lgpl21 bsd3 ];
  };
}
