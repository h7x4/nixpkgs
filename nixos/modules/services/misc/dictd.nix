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
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable the DICT.org dictionary server.
        '';
      };

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
    };
  };

  config =
    let
      dictdb = pkgs.dictDBCollector {
        dictlist = map (x: {
          name = x.name;
          filename = x;
        }) cfg.DBs;
      };
    in
    lib.mkIf cfg.enable {

      # get the command line client on system path to make some use of the service
      environment.systemPackages = [ cfg.package ];

      environment.etc."dict.conf".text = ''
        server localhost
      '';

      systemd.services.dictd = {
        description = "DICT.org Dictionary Server";
        wantedBy = [ "multi-user.target" ];
        environment = {
          LOCALE_ARCHIVE = "/run/current-system/sw/lib/locale/locale-archive";
        };
        # Work around the fact that dictd doesn't handle SIGTERM; it terminates
        # with code 143 instead of exiting with code 0.
        serviceConfig.SuccessExitStatus = [ 143 ];
        serviceConfig.Type = "forking";
        serviceConfig.DynamicUser = true;
        script = "${cfg.package}/sbin/dictd -s -c ${dictdb}/share/dictd/dictd.conf --locale en_US.UTF-8";
      };
    };
}
