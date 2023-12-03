{ config, lib, pkgs, ... }:
let
  inherit (lib) boolToString concatMapStringsSep concatStringsSep isAttrs
    isBool isList mapAttrsToList mdDoc mkEnableOption mkIf mkOption mkOrder
    mkPackageOption mkRemovedOptionModule;
  inherit (lib.types) attrsOf bool either int lines listOf oneOf str;

  indent = str: concatMapStringsSep "\n" (line: "  " + line) (lib.splitString "\n" str);

  toplevel = attrsOf section;
  section = attrsOf relation;
  relation = either (attrsOf value) value;
  value = either (listOf atom) atom;
  atom = oneOf [int str bool];

  formatToplevel = toplevel: concatStringsSep "\n" (mapAttrsToList formatSection toplevel);
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

  mkRemovedOptionModule' = name: reason: mkRemovedOptionModule ["krb5" name] reason;
  mkRemovedOptionModuleCfg = name: mkRemovedOptionModule' name ''
    The option `krb5.${name}' has been removed. Use
    `security.krb5.settings.${name}' for structured configuration or
    `security.krb5.extraConfig' for plain-text configuration.
  '';
  mkMovedOptionModule = name: mkRemovedOptionModule' name ''
    The option `krb5.${name}' has been moved to `security.krb5.${name}'.
  '';

  cfg = config.security.krb5;
in {
  imports = [
    (mkRemovedOptionModuleCfg "libdefaults")
    (mkRemovedOptionModuleCfg "realms")
    (mkRemovedOptionModuleCfg "domain_realm")
    (mkRemovedOptionModuleCfg "capaths")
    (mkRemovedOptionModuleCfg "appdefaults")
    (mkRemovedOptionModuleCfg "plugins")
    (mkRemovedOptionModule' "config" ''
      The option `krb5.config' has been removed. Use `security.krb5.settings'
      for structured configuration or `security.krb5.extraConfig' for
      plain-text configuration.
    '')
    (mkMovedOptionModule "extraConfig")
    (mkMovedOptionModule "kerberos")
  ];

  options = {
    security.krb5 = {
      enable = mkEnableOption (mdDoc "building krb5.conf, configuration file for Kerberos V");

      kerberos = mkPackageOption pkgs "krb5" {
        example = "heimdal";
      };

      settings = mkOption {
        default = {};
        description = mdDoc ''
          Structured contents of the {file}`krb5.conf` file. See
          {manpage}`krb5.conf(5)` for details about configuration.
        '';
        example = {
          libdefaults = {
            default_realm = "ATHENA.MIT.EDU";
          };

          realms = {
            "ATHENA.MIT.EDU" = {
              admin_server = "athena.mit.edu";
              kdc = [
                "athena01.mit.edu"
                "athena02.mit.edu"
              ];
            };
          };

          domain_realm = {
            "mit.edu" = "ATHENA.MIT.EDU";
          };

          logging = {
            kdc = "SYSLOG:NOTICE";
            admin_server = "SYSLOG:NOTICE";
            default = "SYSLOG:NOTICE";
          };
        };
        type = toplevel;
      };

      extraConfig = mkOption {
        type = lines;
        default = "";
        example = ''
          includedir /etc/krb5.conf.d
        '';
        description = mdDoc ''
          The verbatim contents of {file}`/etc/krb5.conf`. {file}`krb5.conf`
          may include any of the relations that are valid for {file}`kdc.conf`
          (see {manpage}`kdc.conf(5)`), but it is not a recommended practice.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = [ cfg.kerberos ];
      etc."krb5.conf".text = cfg.extraConfig;
    };

    # Put between mkBefore and default priority
    security.krb5.extraConfig = mkOrder 750 (formatToplevel cfg.settings);
  };

  meta.maintainers = [ lib.maintainers.dblsaiko ];
}
