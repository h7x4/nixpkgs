{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.powerdns;
in {
  options = {
    services.powerdns = {
      enable = mkEnableOption "PowerDNS domain name server";

      extraConfig = mkOption {
        type = types.lines;
        default = "launch=bind";
        description = ''
          PowerDNS configuration. Refer to
          <https://doc.powerdns.com/authoritative/settings.html>
          for details on supported values.
        '';
      };

      secretFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/keys/powerdns.env";
        description = ''
          Environment variables from this file will be interpolated into the
          final config file using envsubst with this syntax: `$ENVIRONMENT`
          or `''${VARIABLE}`.
          The file should contain lines formatted as `SECRET_VAR=SECRET_VALUE`.
          This is useful to avoid putting secrets into the nix store.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    environment.etc.pdns.source = finalConfigDir;

    systemd.packages = [ pkgs.pdns ];

    systemd.services.pdns = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "mysql.service" "postgresql.service" "openldap.service" ];

      preStart = let
        configDir = pkgs.writeTextDir "pdns.conf" cfg.extraConfig;
      in ''
        umask 077
        ${pkgs.envsubst}/bin/envsubst -i "${configDir}/pdns.conf" -o /run/pdns/pdns.conf
      '';
      serviceConfig = {
        EnvironmentFile = lib.optional (cfg.secretFile != null) cfg.secretFile;
        ExecStart = [ "" "${pkgs.pdns}/bin/pdns_server --config-dir=/run/pdns --guardian=no --daemon=no --disable-syslog --log-timestamp=no --write-pid=no" ];
      };
    };

    users.users.pdns = {
      isSystemUser = true;
      group = "pdns";
      description = "PowerDNS";
    };

    users.groups.pdns = {};

  };
}
