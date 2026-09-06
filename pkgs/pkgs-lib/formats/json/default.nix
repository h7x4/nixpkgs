{
  lib,
  pkgs,
  mkFormat,
}:

mkFormat {
  name = "json";
  type = lib.types.json;
  nativeBuildInputs = [
    pkgs.jq
  ];
  # NIX_ATTRS_JSON_FILE won't have `value` if it's null, but jq returns null for missing properties anyway
  # jsonNull test keeps this in check
  buildPhase = ''
    jq .value "$NIX_ATTRS_JSON_FILE" > output
  '';
}
