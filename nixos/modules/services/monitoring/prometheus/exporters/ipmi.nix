{ config, lib, pkgs, options }:

with lib;

let
  logPrefix = "services.prometheus.exporter.ipmi";
  cfg = config.services.prometheus.exporters.ipmi;
in {
  port = 9290;

  extraOpts = {
    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = lib.mdDoc ''
        Path to configuration file.
      '';
    };

    webConfigFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = lib.mdDoc ''
        Path to configuration file that can enable TLS or authentication.
      '';
    };
  };

  serviceOpts.serviceConfig = {
    ExecStart = concatStringsSep " " [
      "${pkgs.prometheus-ipmi-exporter}/bin/ipmi_exporter"
      (cli.toGNUCommandLineShell { } {
        "web.listen-address" = "${listenAddress}:${toString port}";
        "web.config.file" = cfg.webConfigFile;
        "config.file" = cfg.configFile;
      })
      (escapeShellArgs extraFlags)
    ];
    ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
    RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
  };
}
