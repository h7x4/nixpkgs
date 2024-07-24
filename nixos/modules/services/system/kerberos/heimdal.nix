{
  pkgs,
  config,
  lib,
  ...
}:

let
  inherit (lib) mapAttrs;
  cfg = config.services.kerberos_server;
  package = config.security.krb5.package;

  aclConfigs = lib.pipe cfg.settings.realms [
    (mapAttrs (
      name:
      { acl, ... }:
      lib.concatMapStringsSep "\n" (
        {
          principal,
          access,
          target,
          ...
        }:
        "${principal}\t${lib.concatStringsSep "," (lib.toList access)}"
        # "${principal}\t${lib.concatStringsSep "," (lib.toList access)}\t${target}"
      ) acl
    ))
    (lib.mapAttrsToList (
      name: text: {
        dbname = "/var/lib/heimdal/heimdal";
        acl_file = pkgs.writeText "${name}.acl" text;
      }
    ))
  ];

  # kadmind-acl = lib.pipe cfg.settings.realms [
  #   (lib.mapAttrsToList (name: { acl, ... }: lib.concatMapStringsSep "\n" (
  #     { principal, access, target, ... }:
  #     "${principal}\t${lib.concatStringsSep "," (lib.toList access)}\t${target}"
  #   ) acl))
  #   (lib.concatStringsSep "\n")
  #   (pkgs.writeText "kadmind.acl")
  # ];

  finalConfig = cfg.settings // {
    realms = mapAttrs (_: v: removeAttrs v [ "acl" ]) (cfg.settings.realms or { });
    kdc = (cfg.settings.kdc or { }) // {
      database = aclConfigs;
    };
  };

  format = import ../../../security/krb5/krb5-conf-format.nix { inherit pkgs lib; } {
    enableKdcACLEntries = true;
  };

  kdcConfFile = format.generate "kdc.conf" finalConfig;
in

{
  config = lib.mkIf (cfg.enable && package.passthru.implementation == "heimdal") {
    environment.etc."heimdal-kdc/kdc.conf".source = kdcConfFile;
    # environment.etc."heimdal-kdc/kadmind.acl".source = kadmind-acl;

    # systemd.tmpfiles.settings."10-heimdal" = let
    #   databases = lib.pipe finalConfig.kdc.database [
    #     (map (dbAttrs: dbAttrs.dbname or null))
    #     (lib.filter (x: x != null))
    #     (lib.)
    #     lib.unique
    #   ];
    # in lib.genAttrs databases (_: {
    #   d = {
    #     user = "root";
    #     group = "root";
    #     mode = "0700";
    #   };
    # });
    # // {
    #   "/var/lib/heimdal/kadmind.acl"."L+" = {
    #     argument = toString kadmind-acl;
    #   };
    # };

    systemd.services.kadmind = {
      description = "Kerberos Administration Daemon";
      partOf = [ "kerberos-server.target" ];
      wantedBy = [ "kerberos-server.target" ];
      documentation = [
        "man:kadmind(8)"
        "info:heimdal"
      ];
      serviceConfig = {
        ExecStart = "${package}/libexec/kadmind --config-file=/etc/heimdal-kdc/kdc.conf";
        Slice = "system-kerberos-server.slice";
        StateDirectory = "heimdal";
      };
      restartTriggers = [ kdcConfFile ];
    };

    # systemd.sockets.kdc = {
    #   listenStreams = [ "0.0.0.0:88" ];
    #   wantedBy = [ "sockets.target" ];
    #   socketConfig.Accept = "yes";
    # };

    systemd.services.kdc = {
      description = "Key Distribution Center daemon";
      partOf = [ "kerberos-server.target" ];
      wantedBy = [ "kerberos-server.target" ];
      # requires = [ "kdc.socket" ];
      documentation = [
        "man:kdc(8)"
        "info:heimdal"
      ];
      serviceConfig = {
        ExecStart = "${package}/libexec/kdc --config-file=/etc/heimdal-kdc/kdc.conf";
        Slice = "system-kerberos-server.slice";
        StateDirectory = "heimdal";
        # StandardInput = "socket";
        # StandardError = "journal";
      };
      restartTriggers = [ kdcConfFile ];
    };

    # systemd.sockets.kpasswdd = {
    #   listenStreams = [ "0.0.0.0:464" ];
    #   wantedBy = [ "sockets.target" ];
    #   socketConfig.Accept = "yes";
    # };

    systemd.services.kpasswdd = {
      description = "Kerberos Password Changing daemon";
      partOf = [ "kerberos-server.target" ];
      wantedBy = [ "kerberos-server.target" ];
      # requires = [ "kpasswdd.socket" ];
      documentation = [
        "man:kpasswdd(8)"
        "info:heimdal"
      ];
      serviceConfig = {
        ExecStart = "${package}/libexec/kpasswdd --addresses=0.0.0.0";
        Slice = "system-kerberos-server.slice";
        StateDirectory = "heimdal";
        # StandardInput = "socket";
        # StandardError = "journal";
      };
      restartTriggers = [ kdcConfFile ];
    };
  };
}
