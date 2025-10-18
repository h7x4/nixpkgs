{ lib, ... }:
{
  name = "logkeys";
  meta.maintainers = with lib.maintainers; [ h7x4 ];

  nodes.machine = {
    imports = [ ./common/user-account.nix ];

    services.getty.autologinUser = "alice";

    services.logkeys = {
      enable = true;
      # device = "by-id/vm-default-kbd";
    };
  };

  testScript = ''
    machine.wait_for_unit("getty@tty1.service")
    machine.wait_until_succeeds("pgrep -f 'agetty.*tty1'")
    machine.wait_for_unit("logkeys.service")

    machine.sleep(1)
    machine.send_chars("Hello world!\n")
    machine.sleep(1)
    print(machine.succeed("cat /var/log/logkeys.log"))
    machine.succeed("grep 'Hello world!' /var/log/logkeys.log")
  '';
}
