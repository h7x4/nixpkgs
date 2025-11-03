{ runTest }:
let
  meta = lib: { maintainers = with lib.maintainers; [ h7x4 ]; };

  commonQemuOptions =
    pkgs: lib:
    let
      qemu-img = lib.getExe' pkgs.vmTools.qemu "qemu-img";
      empty = pkgs.runCommand "empty.qcow2" { } ''
        ${qemu-img} create -f qcow2 "$out" 32M
      '';
    in
    [
      "-drive"
      "id=nvme0n1,if=none,format=qcow2,readonly=on,file=${empty}"
      "-device"
      "nvme,serial=deadbeef,drive=nvme0n1,ocp=on"

      "-drive"
      "id=nvme0n2,if=none,format=qcow2,readonly=on,file=${empty}"
      "-device"
      "nvme,serial=8badf00d,drive=nvme0n2,ocp=on"
    ];
in
{
  notifyX11 = runTest (
    { pkgs, lib, ... }:
    {
      name = "smartd-notify-x11";
      meta = meta lib;
      nodes.machine = {
        imports = [ ./common/x11.nix ];

        virtualisation.qemu.options = commonQemuOptions pkgs lib;

        services.smartd.enable = true;
        services.smartd.notifications.test = true;
        services.smartd.notifications.wall.enable = false;
        services.smartd.notifications.x11.enable = true;
      };

      testScript = ''
        machine.wait_for_unit("smartd.service")
        machine.wait_until_succeeds("${lib.getExe' pkgs.procps "ps"} -aux | grep xmessage | grep -v grep")
        #TODO
      '';
    }
  );

  notifyWall = runTest (
    { pkgs, lib, ... }:
    {
      name = "smartd-notify-wall";
      meta = meta lib;
      nodes.machine = {
        virtualisation.qemu.options = commonQemuOptions pkgs lib;

        services.smartd.enable = true;
        services.smartd.notifications.test = true;
        services.smartd.notifications.wall.enable = true;
      };

      testScript = ''
        machine.wait_for_unit("smartd.service")

        # wait for notification
        #TODO
      '';
    }
  );

  notifyMail = runTest (
    { pkgs, lib, ... }:
    {
      name = "smartd-notify-mail";
      meta = meta lib;
      nodes.machine = {
        virtualisation.qemu.options = commonQemuOptions pkgs lib;

        services.smartd.enable = true;
        services.smartd.notifications.test = true;
        services.smartd.notifications.wall.enable = false;
        services.smartd.notifications.mail = {
          enable = true;
          sender = "smartd@example.org";
          recipient = "admin@example.org";
        };
      };

      testScript = ''
        machine.wait_for_unit("smartd.service")

        # wait for notification
        #TODO
      '';
    }
  );

  notifySystembus = runTest (
    { pkgs, lib, ... }:
    {
      name = "smartd-notify-systembus";
      meta = meta lib;
      nodes.machine = {
        virtualisation.qemu.options = commonQemuOptions pkgs lib;

        services.smartd.enable = true;
        services.smartd.notifications.test = true;
        services.smartd.notifications.wall.enable = false;
        services.smartd.notifications.systembus-notify.enable = true;
      };

      testScript = ''
        machine.wait_for_unit("smartd.service")

        print(machine.succeed("${lib.getExe' pkgs.dbus "dbus-monitor"} \"type='signal',sender='net.nuetzlich.SystemNotifications.Notify'\""))
        #TODO
      '';
    }
  );

  autoDetect = runTest (
    { pkgs, lib, ... }:
    {
      name = "smartd-autodetect";
      meta = meta lib;
      nodes.machine =
        { pkgs, lib, ... }:
        {
          virtualisation.qemu.options = commonQemuOptions pkgs lib;

          services.smartd.enable = true;
        };

      testScript = ''
        machine.wait_for_unit("smartd.service")
        machine.wait_for_console_text('Device: /dev/nvme0, is SMART capable. Adding to "monitor" list')
        machine.wait_for_console_text('Device: /dev/nvme1, is SMART capable. Adding to "monitor" list')
      '';
    }
  );

  manuallyMonitored = runTest (
    { pkgs, lib, ... }:
    {
      name = "smartd-autodetect";
      meta = meta lib;
      nodes.machine =
        { pkgs, lib, ... }:
        {
          virtualisation.qemu.options = commonQemuOptions pkgs lib;

          services.smartd.enable = true;
          services.smartd.devices = [
            {
              device = "/dev/nvme1";
            }
          ];
          services.smartd.autodetect = false;
        };

      testScript = ''
        machine.wait_for_unit("smartd.service")
        machine.wait_for_console_text('Device: /dev/nvme1, is SMART capable. Adding to "monitor" list')
        machine.succeed("journalctl -eu smartd.service | grep -v /dev/nvme0")
      '';
    }
  );

  saveState = runTest (
    { pkgs, lib, ... }:
    {
      name = "smartd-savestate";
      meta = meta lib;
      nodes.machine =
        { pkgs, lib, ... }:
        {
          virtualisation.qemu.options = commonQemuOptions pkgs lib;

          services.smartd.enable = true;
          services.smartd.extraOptions = [ "--savestates=/var/lib/smartd/ --interval=10" ];
        };

      testScript = ''
        machine.wait_for_unit("smartd.service")
        machine.systemctl("stop smartd.service")
        machine.wait_for_console_text("state written to /var/lib/smartd/")
        print(machine.succeed("cat /var/lib/smartd/*"))
        #TODO
      '';
    }
  );
}
