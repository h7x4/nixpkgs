{ lib, ... }:

{
  name = "systemd-confinement-nss-passthrough";
  meta.maintainers = with lib.maintainers; [ h7x4 ];

  nodes.machine = {
    environment.etc."nss-sandbox-test-file".text = "hello\n";

    systemd.tmpfiles.settings."10-nss-sandbox-test" = {
      "/var/lib/nss-sandbox-test-writable".d = {
        mode = "0755";
        user = "root";
        group = "root";
      };
    };

    system.nssDatabases.systemdConfinementPassthrough = {
      paths = {
        "/etc/nss-sandbox-test-file" = {
          enable = true;
          optional = false;
        };
        "/var/lib/nss-sandbox-test-writable" = {
          enable = true;
          writable = true;
        };
        "/run/nss-sandbox-test-missing-optional".enable = true;
      };
      addresses."127.0.0.53" = true;
    };

    systemd.services.nss-passthrough-confined = {
      description = "NSS passthrough test for a confined unit";
      confinement.enable = true;
      serviceConfig.Type = "oneshot";
      script = ''
        set -eux
        [[ -e /etc/nss-sandbox-test-file ]]
        read -r content < /etc/nss-sandbox-test-file
        [[ "$content" == "hello" ]]
        [[ -d /var/lib/nss-sandbox-test-writable ]]
        : > /var/lib/nss-sandbox-test-writable/marker-confined
        # files that were never passed through must not be visible.
        [[ ! -e /etc/machine-id ]]
      '';
    };

    systemd.services.nss-passthrough-opted-out = {
      description = "NSS passthrough opt-out test for a confined unit";
      confinement.enable = true;
      confinement.enableNssPassthrough = false;
      serviceConfig.Type = "oneshot";
      script = ''
        set -eux
        [[ ! -e /etc/nss-sandbox-test-file ]]
      '';
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    with subtest("passthrough paths are reachable from a confined unit"):
        machine.succeed("systemctl start nss-passthrough-confined.service")
        machine.succeed("test -e /var/lib/nss-sandbox-test-writable/marker-confined")

    with subtest("passthrough paths are not applied when explicitly opted out"):
        machine.succeed("systemctl start nss-passthrough-opted-out.service")
  '';
}
