{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.timekpr;
  format = pkgs.formats.ini { };
in
{
  options = {
    services.timekpr = {
      package = lib.mkPackageOption pkgs "timekpr" { };
      enable = lib.mkEnableOption "Timekpr-nExT, a screen time managing application that helps optimizing time spent at computer for your subordinates, children or even for yourself";
      adminUsers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "alice"
          "bob"
        ];
        description = ''
          All listed users will become part of the `timekpr` group so they can manage timekpr settings without requiring sudo.
        '';
      };

      settings = lib.mkOption {
        type = lib.types.submodule {
          freeformType = format.type;
        };
        default = { };
        description = "";
      };

      users = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            settings = lib.mkOption {
              type = lib.types.submodule {
                freeformType = format.type;
              };
              default = { };
              description = "";
            };
            controlSettings = lib.mkOption {
              type = lib.types.submodule {
                freeformType = format.type;
              };
              default = { };
              description = "";
            };
          };
        });
        default = { };
        description = "";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    services.timekpr.settings = {

    };

    users.groups.timekpr = {
      gid = 2000;
      members = cfg.adminUsers;
    };

    environment.systemPackages = [
      # Add timekpr to system packages so that polkit can find it
      cfg.package
    ];
    services.dbus.enable = true;
    services.dbus.packages = [
      cfg.package
    ];
    environment.etc."timekpr" = {
      source = "${cfg.package}/etc/timekpr";
    };
    systemd.packages = [
      cfg.package
    ];
    systemd.services.timekpr = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        StateDirectory = [
          "timepkr"
          "timepkr/config"
          "timepkr/work"
        ];
        StateDirectoryMode = "0755";
      };
    };
    security.polkit.enable = true;
  };

  meta.maintainers = [ lib.maintainers.atry ];
}
