{ config, lib, pkgs, ... }:
let
  inherit (lib) mdDoc;
  cfg = config.programs.wireshark;
in
{
  options = {
    programs.wireshark = {
      enable = lib.mkEnableOption (mdDoc "wireshark, and configure a setcap wrapper for 'dumpcap' for users in the 'wireshark' group";
      package = lib.mkPackageOptionMD pkgs "wireshark-cli" {
        example = lib.literalExpression "pkgs.wireshark";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    users.groups.wireshark = { };

    security.wrappers.dumpcap = {
      source = "${cfg.package}/bin/dumpcap";
      capabilities = "cap_net_raw,cap_net_admin+eip";
      owner = "root";
      group = "wireshark";
      permissions = "u+rx,g+x";
    };
  };
}
