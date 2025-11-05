{ pkgs, lib, ... }:
{
  name = "uptimed";
  meta.maintainers = with lib.maintainers; [ h7x4 ];

  nodes.machine =
    { ... }:
    {
      services.uptimed.enable = true;
      services.uptimed.settings = {
        SEND_EMAIL = "1";
        UPDATE_INTERVAL = "1";
        LOG_MINIMUM_UPTIME = "0s";
        MAIL_MINIMUM_UPTIME = "0s";
        MAIL_MINIMUM_POSITION = "1";
        MILESTONE = [
          "5s:five seconds"
          # "10s:ten seconds"
          # "12s:twelve seconds"
        ];
      };

      services.postfix.enable = true;
    };

  testScript = ''
    machine.wait_for_unit("uptimed.service")
    machine.wait_for_unit("postfix.service")

    machine.wait_for_file("/var/lib/uptimed/records")
    print(machine.succeed("uprecords"))

    # Simulate a restart without actually restarting
    # machine.systemctl("stop uptimed.service")
    # machine.succeed("rm /var/lib/uptimed/bootid")
    # machine.systemctl("start uptimed.service")

    machine.sleep(10)

    print(machine.succeed("cat /var/lib/uptimed/records"))
    print(machine.succeed("ls -lah /var/spool/mail/"))
    print(machine.succeed("ls -lah /var/lib/uptimed/"))
    print(machine.succeed("uprecords"))
  '';
}
