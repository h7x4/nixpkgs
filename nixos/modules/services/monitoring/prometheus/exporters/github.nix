{ config, lib, pkgs, options }:
let
  inherit (lib) mkOption types mdDoc mkDefault concatStringsSep;
  cfg = config.services.prometheus.exporters.github;
in {
  port = 9171;
  extraOpts = {
    telemetryPath = mkOption {
      type = types.str;
      default = "/metrics";
      description = mdDoc ''
        Path under which to expose metrics.
      '';
    };

    settings = mkOption {
      type = (types.submodule {
        # systemd environment file type
        freeformType = with types; attrsOf (nullOr (oneOf [ str path package ]));
        options = let
          coerce = concatStringsSep ", ";
        in {
          USERS = mkOption {
            type = with types; coercedTo (listOf str) coerce str;
            default = "";
            example = [
              "user1"
              "user2"
            ];
            description = ''
              Users whose repos should get enumerated.
            '';
          };

          ORGS = mkOption {
            type = with types; coercedTo (listOf str) coerce str;
            default = [ ];
            example = [
              "NixOS"
              "nix-community"
            ];
            description = ''
              Organizations whose repos should get enumerated
            '';
          };

          REPOS = mkOption {
            type = with types; coercedTo (listOf str) coerce str;
            default = "";
            example = [
              "NixOS/nixpkgs"
              "nix-community/home-manager"
            ];
            description = ''
              Repos to enumerate.
            '';
          };
        };
      });
      default = { };
      description = mdDoc ''
        Settings for the exporter.

        See <https://github.com/githubexporter/github-exporter/tree/master#configuration>
        for more information.
      '';
    };
  };
  serviceOpts = {
    environment = {
      LISTEN_PORT = mkDefault (toString cfg.port);
      METRICS_PATH = mkDefault cfg.telemetryPath;
    } // cfg.settings;
    serviceConfig.ExecStart = "${pkgs.prometheus-github-exporter}/bin/github-exporter";
  };
}
