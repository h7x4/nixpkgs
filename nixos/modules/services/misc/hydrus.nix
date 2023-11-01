{ config, pkgs, lib, ... }:
let
  inherit (lib) types mkOption mdDoc;
  cfg = config.services.hydrus;
in
{
  options.services.hydrus = {
    enable = lib.mkEnableOption (mdDoc "Hydrus server");
    package = lib.mkPackageOptionMD pkgs "hydrus" { };

    extraArgs = mkOption {
      type = with types; listOf str;
      default = [];
      description = mdDoc ''
        Additional arguments passed to hydrus.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.hydrus = {
      enable = true;
      description = "Personal booru-style media tagger";
      wantedBy = [ "multi-user.target" ];
      after = [ "networking.target" ];
      serviceConfig = {
        WorkingDirectory = "hydrus";
        StateDirectory = "hydrus";
        Restart = "always";
        DynamicUser = true;
        ExecStart =
          let
            args = lib.escapeShellArgs ([ "--db-dir" "/var/lib/hydrus" ] ++ cfg.extraArgs);
          in
            "${cfg.package}/bin/hydrus-server ${args} start";
        ExecReload = "${cfg.package}/bin/hydrus-server restart";
        ExecStop = "${cfg.package}/bin/hydrus-server stop";

        # Hardening
        # CapabilityBoundingSet = [ "" ];
        # LockPersonality = true;
        # RestrictAddressFamilies = [
        #   "AF_INET"
        #   "AF_INET6"
        # ];
        # RestrictNamespaces = true;
        # RestrictRealtime = true;
        # PrivateTmp = true;
        # PrivateUsers = true;
        # ProcSubset = "pid";
        # ProtectClock = true;
        # ProtectControlGroups= true;
        # ProtectHome = true;
        # ProtectHostname = true;
        # ProtectKernelLogs = true;
        # ProtectKernelModules = true;
        # ProtectKernelTunables = true;
        # ProtectProc = "invisible";
        # SystemCallArchitectures = "native";
        # SystemCallFilter = [
        #   "@system-service"
        #   "~@privileged"
        # ];
        # UMask = "0077";
      };
    };
  };
}
