{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.dictd;
in
{
  meta.maintainers = with lib.maintainers; [ h7x4 ];

  options = {
    services.dictd = {
      enable = lib.mkEnableOption "the DICT.org dictionary server";

      package = lib.mkPackageOption pkgs "dict" { };

      DBs = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs.dictdDBs; [
          wiktionary
          wordnet
        ];
        defaultText = lib.literalExpression "with pkgs.dictdDBs; [ wiktionary wordnet ]";
        example = lib.literalExpression "[ pkgs.dictdDBs.nld2eng ]";
        description = "List of databases to make available.";
      };

      # host
      # port
      # extraArgs
    };
  };

  config = lib.mkIf cfg.enable {
    # get the command line client on system path to make some use of the service
    environment.systemPackages = [ cfg.package ];

    environment.etc."dict.conf".text = ''
      server localhost
    '';

    systemd.services."dictd" = {
      description = "DICT.org Dictionary Server";
      documentation = [ "man:dictd(8)" ];

      after = [ "network.target" ];
      requires = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        LOCALE_ARCHIVE = "/run/current-system/sw/lib/locale/locale-archive";
      };

      serviceConfig = {
        Type = "forking";
        ExecStart = let
          dictdb = pkgs.dictDBCollector {
            dictlist = map (x: {
              name = x.name;
              filename = x;
            }) cfg.DBs;
          };

          args = lib.cli.toCommandLineShellGNU { } {
            syslog = true;
            config = "${dictdb}/share/dictd/dictd.conf";
            locale = "en_US.UTF-8";
            pid-file = "/run/dictd/dictd.pid";
          };
        in "${lib.getExe' cfg.package "dictd"} ${args}";

        # Work around the fact that dictd doesn't handle SIGTERM; it terminates
        # with code 143 instead of exiting with code 0.
        SuccessExitStatus = [ 143 ];

        DynamicUser = true;

        RuntimeDirectory = [ "dictd" "dictd/root-mnt" ];
        RuntimeDirectoryMode = "0700";

        RootDirectory = "/run/dictd/root-mnt";
        BindPaths = [
          # Needs to talk with DNS resolver
          "/run"
          "/var/run"
        ];
        BindReadOnlyPaths = [
          builtins.storeDir
          # Needs to read config of DNS resolver, as well as timezones.
          "/etc"
        ];
        NoExecPaths = "/";
        ExecPaths = "${lib.getExe' cfg.package "dictd"}";

        AmbientCapabilities = "";
        CapabilityBoundingSet = "";
        DevicePolicy = "closed";
        LimitNPROC = "1";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = "disconnected";
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = "strict";
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX" # In order to talk to syslog socket
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
          "~@resources"
        ];
        UMask = "0777";
      };
    };
  };
}
