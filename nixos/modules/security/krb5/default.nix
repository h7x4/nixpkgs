{ config, lib, pkgs, ... }:
let
  inherit (lib) mdDoc mkEnableOption mkIf mkOption mkOrder
    mkPackageOption mkRemovedOptionModule types;

  mkRemovedOptionModule' = name: reason: mkRemovedOptionModule ["krb5" name] reason;
  mkRemovedOptionModuleCfg = name: mkRemovedOptionModule' name ''
    The option `krb5.${name}' has been removed. Use
    `security.krb5.settings.${name}' for structured configuration.
  '';
  mkMovedOptionModule = name: mkRemovedOptionModule' name ''
    The option `krb5.${name}' has been moved to `security.krb5.${name}'.
  '';

  cfg = config.security.krb5;
  format = import ./krb5-conf-format.nix { inherit pkgs lib; } { };
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
      for structured configuration.
    '')
    (mkRemovedOptionModule' "extraConfig" ''
      The option `krb5.extraConfig' has been removed. Use `security.krb5.settings'
      for structured configuration.
    '')
    (mkMovedOptionModule "kerberos")
  ];

  options = {
    security.krb5 = {
      enable = mkEnableOption (mdDoc "building krb5.conf, configuration file for Kerberos V");

      kerberos = mkPackageOption pkgs "krb5" {
        example = "heimdal";
      };

      settings = mkOption {
        default = { };
        type = format.type;
        description = mdDoc ''
          Structured contents of the {file}`krb5.conf` file. See
          {manpage}`krb5.conf(5)` for details about configuration.
        '';
        example = {
          modules = [ "" ];
          includes = [ "/run/secrets/secret-krb5.conf" ];
          includedirs = [ "/run/secrets/secret-krb5.conf.d" ];
          sections = {
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
        };
      };
    };
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = [ cfg.kerberos ];
      etc."krb5.conf".source = format.generate "krb5.conf" cfg.settings;
    };
  };

  meta.maintainers = [ lib.maintainers.dblsaiko ];
}
