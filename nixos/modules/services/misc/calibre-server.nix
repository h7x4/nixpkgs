{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.calibre-server;

  documentationLinkRoot = "https://manual.calibre-ebook.com";
  serverCliDocumentationLink = documentationLinkRoot + "/generated/en/calibre-server.html";
in

{
  imports = [
    (mkChangedOptionModule [ "services" "calibre-server" "libraryDir" ] [ "services" "calibre-server" "libraries" ]
      (config:
        let libraryDir = getAttrFromPath [ "services" "calibre-server" "libraryDir" ] config;
        in [ libraryDir ]
      )
    )
    (mkRemovedOptionModule [ "services" "calibre-server" "user" ] ''
      The module has been converted to use DynamicUser.
      This option is redundant.
    '')
    (mkRemovedOptionModule [ "services" "calibre-server" "group" ] ''
      The module has been converted to use DynamicUser.
      This option is redundant.
    '')
  ];

  options = {
    services.calibre-server = {

      enable = mkEnableOption (lib.mdDoc "calibre-server");
      package = lib.mkPackageOptionMD pkgs "calibre" { };

      libraries = mkOption {
        type = types.listOf types.path;
        default = [ "/var/lib/calibre-server" ];
        description = lib.mdDoc ''
          Make sure each library path is initialized before service startup.
          The directories of the libraries to serve. They must be readable for the user under which the server runs.
          See the [calibredb documentation](${documentationLinkRoot}/generated/en/calibredb.html#add) for details.
        '';
      };

      host = mkOption {
        type = types.str;
        default = "0.0.0.0";
        example = "::1";
        description = lib.mdDoc ''
          The interface on which to listen for connections.
          See the [calibre-server documentation](${serverCliDocumentationLink}#cmdoption-calibre-server-listen-on) for details.
        '';
      };

      port = mkOption {
        default = 8080;
        example = 8081;
        type = types.port;
        description = lib.mdDoc ''
          The port on which to listen for connections.
          See the [calibre-server documentation](${serverCliDocumentationLink}#cmdoption-calibre-server-port) for details.
        '';
      };

      auth = {
        enable = mkEnableOption (lib.mdDoc ''
          password based authentication to access the server.

          See the [calibre-server documentation](${serverCliDocumentationLink}#cmdoption-calibre-server-enable-auth) for details.
        '');

        mode = mkOption {
          type = types.enum [ "auto" "basic" "digest" ];
          default = "auto";
          description = lib.mdDoc ''
            Choose the type of authentication used.
            Set the HTTP authentication mode used by the server.
            See the [calibre-server documentation](${serverCliDocumentationLink}#cmdoption-calibre-server-auth-mode) for details.
          '';
        };

        userDb = mkOption {
          default = null;
          type = types.nullOr types.path;
          description = lib.mdDoc ''
            Choose users database file to use for authentication.
            Make sure users database file is initialized before service startup.
            See the [calibre-server documentation](${documentationLinkRoot}/server.html#managing-user-accounts-from-the-command-line-only) for details.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.calibre-server = {
      description = "Server exposing calibre libraries over the internet";
      documentation = [
        "${documentationLinkRoot}/server.html"
        serverCliDocumentationLink
      ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        Restart = "always";
        ExecStart = let
          execFlags = lib.cli.toGNUCommandLineShell { } {
            inherit (cfg) port;
            listen-on = cfg.host;
            auth-mode = cfg.auth.mode;
            userdb = cfg.auth.userDb;
            enable-auth = cfg.auth.enable;
          };
        in "${cfg.package}/bin/calibre-server ${lib.concatStringsSep " " cfg.libraries} ${execFlags}";

        ReadOnlyPaths = cfg.libraries;
        ReadWritePaths = optionals (cfg.auth.enable && cfg.auth.userDb != null) cfg.userDb;
        StateDirectory = "calibre-server";

        # AmbientCapabilities = "";
        # CapabilityBoundingSet = "";
        # LockPersonality = true;
        # MemoryDenyWriteExecute = true;
        # NoNewPrivileges = true;
        # PrivateDevices = true;
        # PrivateMounts = true;
        PrivateTmp = true;
        # PrivateUsers = true;
        # ProcSubset = "pid";
        # ProtectClock = true;
        # ProtectControlGroups = true;
        # ProtectHome = true;
        # ProtectHostname = true;
        # ProtectKernelLogs = true;
        # ProtectKernelModules = true;
        # ProtectKernelTunables = true;
        # ProtectProc = "invisible";
        # ProtectSystem = "strict";
        # RemoveIPC = true;
        # RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        # RestrictNamespaces = true;
        # RestrictRealtime = true;
        # RestrictSUIDSGID = true;
        # SocketBindAllow = cfg.port;
        # SocketBindDeny = "any";
        # SystemCallArchitectures = "native";
        # SystemCallFilter = [
        #   "@system-service"
        #   "~@privileged @obsolete"
        # ];
        # UMask = "0077";
      };
    };

    environment.systemPackages = [ cfg.package ];
  };

  meta.maintainers = with lib.maintainers; [ gaelreyrol ];
}
