{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.uptimed;
  stateDir = "/var/lib/uptimed";
  runtimeDir = "/run/uptimed";
in
{
  options = {
    services.uptimed = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable `uptimed`, allowing you to track
          your highest uptimes.
        '';
      };

      settings = lib.mkOption {
        type = lib.types.submodule {
          freeformType = with lib.types; attrsOf (either str (listOf str));
          options = {
            PIDFILE = lib.mkOption {
              type = lib.types.path;
              default = "${runtimeDir}/pid";
              description = "Where to put uptimed's PID file";
            };

            SEND_EMAIL = lib.mkOption {
              type = lib.types.enum [
                "0"
                "1"
                "2"
                "3"
              ];
              default = "0";
              description = ''
                Whether to send email. This assumes that you have a working MTA on your system.

                - `0`: off
                - `1`: on
                - `2`: only for milestones
                - `3`: only for records
              '';
            };

            SENDMAIL = lib.mkOption {
              type = lib.types.path;
              default = "${pkgs.system-sendmail}/bin/sendmail -t";
              defaultText = lib.literalExpression ''"''${pkgs.system-sendmail}/bin/sendmail -t"'';
              description = ''
                The command to use for sending mail.

                The command needs to be {command}`sendmail` compatible.
              '';
            };

            EMAIL = lib.mkOption {
              type = lib.types.str;
              description = "Which email to send";
              example = "someone@example.com";
              default = "root@localhost";
            };
          };
        };
        default = { };
        description = ''
          Settings for {file}`uptimed.conf`.

          For available options, see <https://github.com/rpodgorny/uptimed/blob/master/etc/uptimed.conf-dist>.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.uptimed ];

    environment.etc."uptimed/uptimed.conf".text =
      lib.concatStringsSep "\n" (lib.mapAttrsToList (
        k: v: if builtins.isList v then lib.concatMapStringsSep "\n" (v': "${k}=${v'}") v else "${k}=${v}"
      ) cfg.settings);

    systemd.services.uptimed = {
      documentation = [
        "man:uptimed(8)"
        "man:uprecords(1)"
      ];
      description = "uptimed service";
      wantedBy = [ "multi-user.target" ];

      restartTriggers = [ config.environment.etc."uptimed/uptimed.conf".source ];

      serviceConfig = {
        Type = "notify";
        NotifyAccess = "all";
        Restart = "on-failure";
        DynamicUser = lib.mkIf (cfg.settings.SEND_EMAIL == "0") true;
        # ExecStartPre = [
        #   "${lib.getExe' pkgs.coreutils "ls"} -lah /etc"
        #   "${lib.getExe' pkgs.coreutils "ls"} -lah /etc/uptimed"
        # ];
        ExecStart = "${lib.getExe pkgs.strace} -f ${pkgs.uptimed}/sbin/uptimed -f -i 1";
        PIDFile = cfg.settings.PIDFILE;

        Nice = 19;
        IOSchedulingClass = "idle";

        StateDirectory = "uptimed";
        StateDirectoryMode = "0755";
        ConfigurationDirectory = "uptimed::ro";
        RuntimeDirectory = [
          "uptimed"
          "uptimed/root-mnt"
        ];

        RootDirectory = "/run/uptimed/root-mnt";
        BindPaths = [
          "-/var/lib/postfix"
        ];
        BindReadOnlyPaths = [
          builtins.storeDir
          "/bin/sh"
          "/etc"
          # "/etc/static/uptimed"
          "-/run/wrappers/bin/sendmail"
          # "-/var/lib/postfix"
        ];

        # Needs to be able to access /proc/stat to read bootid
        ProcSubset = "all";

        # AmbientCapabilities = "";
        CapabilityBoundingSet = "CAP_SYS_PTRACE";
        DeviceAllow = null;
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateNetwork = true;
        PrivateDevices = true;
        PrivateIPC = true;
        PrivateTmp = "disconnected";
        PrivateUsers = lib.mkIf (cfg.settings.SEND_EMAIL == "0") true;
        ProtectClock = true;
        ProtectControlGroups = "strict";
        ProtectHome = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        ProtectKernelLogs = true;
        IPAddressDeny = "any";
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [
          "AF_UNIX" # To talk with $NOTIFY_SOCKET
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
          "~@resources"
          "@debug"
        ];
        UMask = "022";
      };
    };
  };
}
