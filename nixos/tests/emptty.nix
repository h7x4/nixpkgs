{ lib, ... }:

let
  machineBase = {
    imports = [ ./common/user-account.nix ];
    services.displayManager.emptty.enable = true;
  };
in
{
  name = "emptty";
  meta.maintainers = with lib.maintainers; [ h7x4 ];

  nodes.machine =
    { ... }:
    lib.attrsets.recursiveUpdate machineBase {
      services.xserver.enable = true;
      services.xserver.windowManager.icewm.enable = true;
    };
  nodes.machineAutologin =
    { ... }:
    lib.attrsets.recursiveUpdate machineBase {
      services.xserver.enable = true;
      services.xserver.windowManager.icewm.enable = true;
      services.displayManager.defaultSession = "none+icewm";
      services.displayManager.autoLogin = {
        enable = true;
        user = "alice";
      };
    };
  nodes.machineNoX11 =
    { ... }:
    lib.attrsets.recursiveUpdate machineBase {
      services.displayManager.defaultSession = "sway";
      programs.sway.enable = true;
    };

  testScript =
    { nodes, ... }:
    let
      user = nodes.machine.users.users.alice;
    in
    # python
    ''
      start_all()

      with subtest("X11 manual login"):
        # https://github.com/NixOS/nixpkgs/pull/455191#discussion_r2507716719
        machine.wait_until_succeeds("getfacl /dev/dri/card0 | grep video")
        machine.wait_until_tty_matches("1", "login:")
        machine.screenshot("emptty")
        machine.send_chars("${user.name}\n")
        machine.wait_until_tty_matches("1", "Password: ")
        machine.send_chars("${user.password}\n")
        machine.wait_for_file("/run/user/${toString user.uid}/.emptty-xauth")
        machine.succeed("xauth merge /run/user/${toString user.uid}/.emptty-xauth")
        machine.wait_for_window("^IceWM ")
        machine.sleep(2)
        machine.screenshot("icewm")

      with subtest("X11 automatic ogin"):
        machineAutologin.wait_until_succeeds("getfacl /dev/dri/card0 | grep video")
        machineAutologin.wait_for_file("/run/user/${toString user.uid}/.emptty-xauth")
        machineAutologin.succeed("xauth merge /run/user/${toString user.uid}/.emptty-xauth")
        machineAutologin.wait_for_window("^IceWM ")
        machineAutologin.sleep(2)
        machineAutologin.screenshot("autologin-icewm")

      with subtest("Wayland login"):
        machineNoX11.wait_until_tty_matches("1", "login:")
        machineNoX11.screenshot("emptty-no-x11")
        machineNoX11.send_chars("${user.name}\n")
        machineNoX11.wait_until_tty_matches("1", "Password: ")
        machineNoX11.send_chars("${user.password}\n")
        machineNoX11.wait_for_file("/run/user/${toString user.uid}/wayland-1")
        machineNoX11.wait_for_file("/run/user/${toString user.uid}/sway-ipc.*.sock")
        machineNoX11.sleep(5)
        machineNoX11.screenshot("sway")
    '';
}
