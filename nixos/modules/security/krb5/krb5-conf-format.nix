{ pkgs, lib, ... }:

# Based on
# - https://web.mit.edu/kerberos/krb5-1.12/doc/admin/conf_files/krb5_conf.html
# - https://manpages.debian.org/unstable/heimdal-docs/krb5.conf.5heimdal.en.html

let
  inherit (lib) boolToString concatMapStringsSep concatStringsSep filter
    isAttrs isBool isList mapAttrsToList mkOption;
  inherit (lib.types) attrsOf bool either int listOf oneOf path str submodule;
in
{ }: {
  type = let
    section = attrsOf relation;
    relation = either (attrsOf value) value;
    value = either (listOf atom) atom;
    atom = oneOf [int str bool];
  in submodule {
    options = {
      sections = mkOption {
        type = attrsOf section;
        default = { };
      };
      includes = mkOption {
        type = listOf path;
        default = [ ];
      };
      includedirs = mkOption {
        type = listOf path;
        default = [ ];
      };
      modules = mkOption {
        type = listOf str;
        default = [ ];
      };
    };
  };

  generate = let
    indent = str: concatMapStringsSep "\n" (line: "  " + line) (lib.splitString "\n" str);

    formatToplevel = {
      sections ? { }
    , includes ? [ ]
    , includedirs ? [ ]
    , modules ? [ ]
    }:
    concatStringsSep "\n" (filter (x: x != "") [
      (concatMapStringsSep "\n" (m: "module " + m) modules)
      (concatMapStringsSep "\n" (i: "include " + i) includes)
      (concatMapStringsSep "\n" (i: "includedir " + i) includedirs)
      (concatStringsSep "\n" (mapAttrsToList formatSection sections))
    ]);

    formatSection = name: section: ''
      [${name}]
      ${indent (concatStringsSep "\n" (mapAttrsToList formatRelation section))}
    '';

    formatRelation = name: relation:
      if isAttrs relation
      then ''
        ${name} = {
        ${indent (concatStringsSep "\n" (mapAttrsToList formatValue relation))}
        }''
      else formatValue name relation;

    formatValue = name: value:
      if isList value
      then concatMapStringsSep "\n" (formatAtom name) value
      else formatAtom name value;

    formatAtom = name: atom: let
      v = if isBool atom then boolToString atom else toString atom;
    in "${name} = ${v}";
  in
    name: value: pkgs.writeText name (formatToplevel value);
}
