{ config, lib, pkgs, ... }:
let
  cfg = config.services.go-neb;

  settingsFormat = pkgs.formats.yaml {};
in {
  options.services.go-neb = {
    enable = lib.mkEnableOption "an extensible matrix bot written in Go";

    bindAddress = lib.mkOption {
      type = lib.types.str;
      description = "Port (and optionally address) to listen on.";
      default = ":4050";
    };

    secretFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/keys/go-neb.env";
      description = ''
        Environment variables from this file will be interpolated into the
        final config file using envsubst with this syntax: `$ENVIRONMENT`
        or `''${VARIABLE}`.
        The file should contain lines formatted as `SECRET_VAR=SECRET_VALUE`.
        This is useful to avoid putting secrets into the nix store.
      '';
    };

    baseUrl = lib.mkOption {
      type = lib.types.str;
      description = "Public-facing endpoint that can receive webhooks.";
    };

    config = lib.mkOption {
      inherit (settingsFormat) type;
      description = ''
        Your {file}`config.yaml` as a Nix attribute set.
        See [config.sample.yaml](https://github.com/matrix-org/go-neb/blob/master/config.sample.yaml)
        for possible options.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.go-neb = {
      description = "Extensible matrix bot written in Go";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        BASE_URL = cfg.baseUrl;
        BIND_ADDRESS = cfg.bindAddress;
        CONFIG_FILE = "/run/go-neb/config.yaml";
      };

      preStart = let
        configFile = settingsFormat.generate "config.yaml" cfg.config;
      in ''
        umask 077
        ${pkgs.envsubst}/bin/envsubst -i "${configFile}" -o /run/go-neb/config.yaml
      '';
      serviceConfig = {
        EnvironmentFile = lib.optional (cfg.secretFile != null) cfg.secretFile;
        RuntimeDirectory = "go-neb";
        ExecStart = "${pkgs.go-neb}/bin/go-neb";
        User = "go-neb";
        DynamicUser = true;
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ hexa maralorn ];
}
