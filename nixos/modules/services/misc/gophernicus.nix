{ config, options, pkgs, lib, ... }:
let
  cfg = config.services.gophernicus;
  opt = options.services.gophernicus;
in
{
  options.services.gophernicus = {
    enable = lib.mkEnableOption "";
    package = lib.mkPackageOption pkgs "gophernicus" { };

    gopherRoot = lib.mkOption {
      type = lib.types.path;
      description = "The directory which contains the root of your gopher content";
      default = "/var/lib/gophernicus/gopher";
      example = "/some/other/dir";
    };

    binPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      description = "Packages with content in `/bin` that should be available to gophernicus";
      default = with pkgs; [
        coreutils
        gnused
        whoami
      ];
      defaultText = lib.literalExpression ''
        with pkgs; [
          coreutils
          gnused
          whoami
        ]
      '';
    };

    cgiBinPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      description = "Packages with cgi handlers in `/bin` that should be available to gophernicus";
      default = with pkgs; [
        bash
        php
        perl
      ];
      defaultText = lib.literalExpression ''
        with pkgs; [
          bash
          php
          perl
        ]
      '';
    };

    rootGophermap = lib.mkOption {
      description = "The file used as the root gophermap";
      type = lib.types.path;
      default = "${cfg.package}/share/gophernicus/gopher/gophermap";
      example = lib.literalExpression ''
        pkgs.writeText "gophernicus-gophermap" '''
          -------------------------------
           MY GOPHER SERVER LANDING PAGE
          -------------------------------

          Welcome to the crib.
        '''
      '';
    };

    settings = {
      hostname = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        example = "0.0.0.0";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 70;
        example = 8000;
      };

      # tlsPort = lib.mkOption {
      #   type = lib.types.nullOr lib.types.port;
      #   default = null;
      #   example = 9000;
      # };
    };

    extraArgs = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = { };
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.packages = [ cfg.package ];

    systemd.sockets."gophernicus" = {
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenStream = [
          ""
          "${cfg.settings.hostname}:${toString cfg.settings.port}"
        # ] ++ lib.optionals (cfg.settings.tlsPort != null) [
        #   "${cfg.settings.hostname}:${toString cfg.settings.tlsPort}"
        ];
      };
    };

    systemd.services."gophernicus@" = {
      documentation = [ "man:gophernicus(8)" ];
      serviceConfig = {
        DynamicUser = true;
        User = "gophernicus";
        Group = "gophernicus";

        StateDirectory = [ "gophernicus/gopher" ];

        RuntimeDirectory = [ "gophernicus/bin" ];
        BindReadOnlyPaths = let
          binDir = pkgs.symlinkJoin {
            name = "gophernicus-bin";
            paths = cfg.binPackages;
            stripPrefix = "/bin";
          };

          cgiBinDir = pkgs.symlinkJoin {
            name = "gophernicus-cgi-bin";
            paths = cfg.cgiBinPackages;
            stripPrefix = "/bin";
          };
        in [
          "${binDir}:/run/gophernicus/bin"
          "${cgiBinDir}:/run/gophernicus/cgi-bin"
        ] ++ (lib.optionals (cfg.gopherRoot != opt.gopherRoot.default) [
          "${cfg.gopherRoot}:/var/lib/gophernicus/gopher"
        ]) ++ [
          "${cfg.rootGophermap}:/var/lib/gophernicus/gopher/gophermap"
        ];

        ExecStart = let
          args = lib.cli.toGNUCommandLineShell { } ({
            c = "/run/gophernicus/cgi-bin";
            r = "/var/lib/gophernicus/gopher";
          } // cfg.extraArgs);
        in [
          ""
          "${lib.getExe cfg.package} ${args}"
        ];

        ProtectHome = lib.mkDefault "read-only";
      };
    };
  };
}
