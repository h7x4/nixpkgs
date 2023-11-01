{ config, lib, pkgs, ... }:

with lib;
let

  cfg = config.services.lighthouse;
in {

  options = {
    services.lighthouse = {
      beacon = mkOption {
        description = lib.mdDoc "Beacon node";
        default = {};
        type = types.submodule {
          options = {
            enable = lib.mkEnableOption (lib.mdDoc "Lightouse Beacon node");

            dataDir = mkOption {
              type = types.path;
              default = "/var/lib/lighthouse-beacon";
              description = lib.mdDoc ''
                Directory where data will be stored. Each chain will be stored under it's own specific subdirectory.
              '';
            };

            address = mkOption {
              type = types.str;
              default = "0.0.0.0";
              description = lib.mdDoc ''
                Listen address of Beacon node.
              '';
            };

            port = mkOption {
              type = types.port;
              default = 9000;
              description = lib.mdDoc ''
                Port number the Beacon node will be listening on.
              '';
            };

            openFirewall = mkOption {
              type = types.bool;
              default = false;
              description = lib.mdDoc ''
                Open the port in the firewall
              '';
            };

            disableDepositContractSync = mkOption {
              type = types.bool;
              default = false;
              description = lib.mdDoc ''
                Explicitly disables syncing of deposit logs from the execution node.
                This overrides any previous option that depends on it.
                Useful if you intend to run a non-validating beacon node.
              '';
            };

            execution = {
              address = mkOption {
                type = types.str;
                default = "127.0.0.1";
                description = lib.mdDoc ''
                  Listen address for the execution layer.
                '';
              };

              port = mkOption {
                type = types.port;
                default = 8551;
                description = lib.mdDoc ''
                  Port number the Beacon node will be listening on for the execution layer.
                '';
              };

              jwtPath = mkOption {
                type = types.str;
                default = "";
                description = lib.mdDoc ''
                  Path for the jwt secret required to connect to the execution layer.
                '';
              };
            };

            http = {
              enable = lib.mkEnableOption (lib.mdDoc "Beacon node http api");
              port = mkOption {
                type = types.port;
                default = 5052;
                description = lib.mdDoc ''
                  Port number of Beacon node RPC service.
                '';
              };

              address = mkOption {
                type = types.str;
                default = "127.0.0.1";
                description = lib.mdDoc ''
                  Listen address of Beacon node RPC service.
                '';
              };
            };

            metrics = {
              enable = lib.mkEnableOption (lib.mdDoc "Beacon node prometheus metrics");
              address = mkOption {
                type = types.str;
                default = "127.0.0.1";
                description = lib.mdDoc ''
                  Listen address of Beacon node metrics service.
                '';
              };

              port = mkOption {
                type = types.port;
                default = 5054;
                description = lib.mdDoc ''
                  Port number of Beacon node metrics service.
                '';
              };
            };

            extraArgs = mkOption {
              type = with types; coercedTo (listOf str) lib.escapeShellArgs str;
              description = lib.mdDoc ''
                Additional arguments passed to the lighthouse beacon command.
              '';
              default = [ ];
            };
          };
        };
      };

      validator = mkOption {
        description = lib.mdDoc "Validator node";
        default = {};
        type = types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = lib.mdDoc "Enable Lightouse Validator node.";
            };

            dataDir = mkOption {
              type = types.path;
              default = "/var/lib/lighthouse-validator";
              description = lib.mdDoc ''
                Directory where data will be stored. Each chain will be stored under it's own specific subdirectory.
              '';
            };

            beaconNodes = mkOption {
              type = types.listOf types.str;
              default = ["http://localhost:5052"];
              description = lib.mdDoc ''
                Beacon nodes to connect to.
              '';
            };

            metrics = {
              enable = lib.mkEnableOption (lib.mdDoc "Validator node prometheus metrics");
              address = mkOption {
                type = types.str;
                default = "127.0.0.1";
                description = lib.mdDoc ''
                  Listen address of Validator node metrics service.
                '';
              };

              port = mkOption {
                type = types.port;
                default = 5056;
                description = lib.mdDoc ''
                  Port number of Validator node metrics service.
                '';
              };
            };

            extraArgs = mkOption {
              type = with types; coercedTo (listOf str) lib.escapeShellArgs str;
              description = lib.mdDoc ''
                Additional arguments passed to the lighthouse validator command.
              '';
              default = [ ];
            };
          };
        };
      };

      network = mkOption {
        type = types.enum [ "mainnet" "prater" "goerli" "gnosis" "kiln" "ropsten" "sepolia" ];
        default = "mainnet";
        description = lib.mdDoc ''
          The network to connect to. Mainnet is the default ethereum network.
        '';
      };

      extraArgs = mkOption {
        type = with types; coercedTo (listOf str) lib.escapeShellArgs str;
        description = lib.mdDoc ''
          Additional arguments passed to every lighthouse command.
        '';
        default = [ ];
      };
    };
  };

  config = mkIf (cfg.beacon.enable || cfg.validator.enable) {

    environment.systemPackages = [ pkgs.lighthouse ];

    networking.firewall = mkIf (cfg.beacon.enable && cfg.beacon.openFirewall) {
      allowedTCPPorts = [ cfg.beacon.port ];
      allowedUDPPorts = [ cfg.beacon.port ];
    };

    systemd.tmpfiles.rules = [ ]
      ++ optional cfg.beacon.enable "d ${cfg.beacon.dataDir}/${cfg.network} 0700 root root - -"
      ++ optional cfg.validator.enable "d ${cfg.validator.dataDir}/${cfg.network} 0700 root root - -";

    systemd.services.lighthouse-beacon = mkIf  {
      description = "Lighthouse beacon node (connect to P2P nodes and verify blocks)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = let
          args = lib.cli.toGNUCommandLineShell { } lib.mkMerge [
            {
              disable-upnp = true;
              disable-deposit-contract-sync = cfg.beacon.disableDepositContractSync;
              port = cfg.beacon.port;
              listen-address = cfg.beacon.address;
              network = cfg.network;
              datadir = "${cfg.beacon.dataDir}/${cfg.network}";
              execution-endpoint = "http://${cfg.beacon.execution.address}:${toString cfg.beacon.execution.port}";
              execution-jwt = "%d/LIGHTHOUSE_JWT";
            }
            (lib.mkIf (cfg.beacon.http.enable) {
              http = true;
              http-address = cfg.beacon.http.address;
              http-port = cfg.beacon.http.port;
            })
            (lib.mkIf (cfg.beacon.metrics.enable) {
              metrics = true;
              metrics-address = cfg.beacon.metrics.address;
              metrics-port = cfg.beacon.metrics.port;
            })
          ];
        in "${pkgs.lighthouse}/bin/lighthouse beacon_node ${args} ${cfg.extraArgs} ${cfg.beacon.extraArgs}";

        LoadCredential = "LIGHTHOUSE_JWT:${cfg.beacon.execution.jwtPath}";
        DynamicUser = true;
        Restart = "on-failure";
        StateDirectory = "lighthouse-beacon";
        ReadWritePaths = [ cfg.beacon.dataDir ];
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectClock = true;
        ProtectProc = "noaccess";
        ProcSubset = "pid";
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        RemoveIPC = true;
        SystemCallFilter = [ "@system-service" "~@privileged" ];
      };
    };

    systemd.services.lighthouse-validator = mkIf cfg.validator.enable {
      description = "Lighthouse validtor node (manages validators, using data obtained from the beacon node via a HTTP API)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = let
          args = lib.cli.toGNUCommandLineShell { } lib.mkMerge [
            {
              network = cfg.network;
              beacon-nodes = lib.concatStringsSep "," cfg.validator.beaconNodes;
              datadir = "${cfg.validator.dataDir}/${cfg.network}";
            }
            (lib.mkIf (cfg.validator.metrics.enable) {
              metrics = true;
              metrics-address = cfg.validator.metrics.address;
              metrics-port = cfg.validator.metrics.port;
            })
          ];
        in "${pkgs.lighthouse}/bin/lighthouse validator_client ${args} ${cfg.extraArgs} ${cfg.validator.extraArgs}";

        Restart = "on-failure";
        StateDirectory = "lighthouse-validator";
        ReadWritePaths = [ cfg.validator.dataDir ];
        CapabilityBoundingSet = "";
        DynamicUser = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectClock = true;
        ProtectProc = "noaccess";
        ProcSubset = "pid";
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        RemoveIPC = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        SystemCallFilter = [ "@system-service" "~@privileged" ];
      };
    };
  };
}
