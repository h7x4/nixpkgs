{ pkgs, lib, ... }:
{
  name = "gophernicus";
  meta.maintainers = with lib.maintainers; [ h7x4 ];

  nodes.machine =
    { options, ... }:
    {
      imports = [ ./common/user-account.nix ];

      environment.systemPackages = with pkgs; [
        phetch
      ];

      users.users = {
        alice.homeMode = "755";
        bob.homeMode = "755";
      };

      services.gophernicus = {
        enable = true;

        binPackages = options.services.gophernicus.cgiBinPackages.default ++ [
          (pkgs.writeScriptBin "hello" ''printf "aaaaaaa\n"'')
        ];

        # cgiBinPackages = options.services.gophernics.cgiBinPackages.default ++ [

        # ];
      };
    };

  testScript = let
    alice-hello = pkgs.writeText "gophernicus-test-alice-hello" ''
      Hi!
    '';
    bob-hello = pkgs.writeText "gophernicus-test-bob-hello" ''
      Hello!
    '';
    bob-custom-command = pkgs.writeText "gophernicus-test-bob-hello" ''
      =echo "$(hello)"
    '';
  in ''
    machine.wait_for_unit("sockets.target")

    def phetch_or_fail(path: str) -> str:
        result = machine.succeed(f"phetch -r gopher://localhost/{path}")
        print(result)
        assert "Error:" not in result
        return result

    with subtest("Fetch root pages"):
        phetch_or_fail("")
        phetch_or_fail("/server-status")
        phetch_or_fail("/caps.txt")

    machine.succeed("runuser -u alice -- install -Dm755 -d /home/alice/public_gopher")
    machine.succeed("runuser -u bob -- install -Dm755 -d /home/bob/public_gopher")

    with subtest("Fetch user pages"):
        machine.succeed("runuser -u alice -- install -Dm644 '${alice-hello}' /home/alice/public_gopher/hello")
        machine.succeed("runuser -u bob -- install -Dm644 '${bob-hello}' /home/bob/public_gopher/world")
        phetch_or_fail("1~alice/hello")
        phetch_or_fail("1~bob/world")

    with subtest("Render page with custom command"):
        machine.succeed("runuser -u bob -- install -Dm644 '${bob-custom-command}' /home/bob/public_gopher/custom")
        content = phetch_or_fail("1~bob/custom")
        assert "aaaaaaa" in content

    with subtest("Render php as cgi"):
        pass

    with subtest("Render php as filter"):
        pass
  '';
}
