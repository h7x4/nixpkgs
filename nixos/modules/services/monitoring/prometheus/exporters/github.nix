{ config, pkgs, lib, ... }:
let
  inherit (lib) mkOption types mdDoc concatStringsSep;
  cfg = config.services.prometheus.exporters.github;
in {
  port = 9504;
  extraOpts = {
    telemetryPath = mkOption {
      type = types.str;
      default = "/metrics";
      description = mdDoc ''
        Path under which to expose metrics.
      '';
    };

    enterprises = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "microsoft" ];
      description = mdDoc ''
        Enterprises to scrape metrics from.
      '';
    };

    organizations = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "NixOS"
        "nix-community"
      ];
      description = mdDoc ''
        Organizations to scrape metrics from.
      '';
    };

    repositories = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "NixOS/nixpkgs"
        "nix-community/home-manager"
      ];
      description = mdDoc ''
        Repositories to scrape metrics from.
      '';
    };
  };
  serviceOpts = {
    serviceConfig = {
      ExecStart = let
        flags = [
          "--web.address ${cfg.listenAddress}:${toString cfg.port}"
          "--web.path ${cfg.telemetryPath}"
        ]
        ++ (map (x: "--github.repo ${x}") cfg.enterprises)
        ++ (map (x: "--github.org ${x}") cfg.organizations)
        ++ (map (x: "--github.enterprise ${x}") cfg.repositories)
        ++ cfg.extraFlags;
      in ''
        ${pkgs.prometheus-github-exporter}/bin/github_exporter \
          ${concatStringsSep " \\\n  " flags}
      '';
    };
  };
}
