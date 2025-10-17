{ pkgs, lib, ... }:
let
  gpgKeyring = (
    pkgs.runCommand "gpg-keyring" { buildInputs = [ pkgs.gnupg ]; } ''
      mkdir -p $out
      export GNUPGHOME=$out
      cat > foo <<EOF
        %echo Generating a basic OpenPGP key
        %no-protection
        Key-Type: DSA
        Key-Length: 1024
        Subkey-Type: ELG-E
        Subkey-Length: 1024
        Name-Real: Foo Example
        Name-Email: foo@example.org
        Expire-Date: 0
        # Do a commit here, so that we can later print "done"
        %commit
        %echo done
      EOF
      gpg --batch --generate-key foo
      gpg --armor --export foo@example.org > $out/pub.key
      gpg --armor --export-secret-keys foo@example.org > $out/priv.key
      rm $out/S.gpg-agent $out/S.gpg-agent.* $out/S.scdaemon
    ''
  );
in
{
  name = "zeyple";

  meta = {
    maintainers = with lib.maintainers; [ h7x4 ];
  };

  nodes = {
    receiver =
      { config, ... }:
      {
        imports = [ ./common/user-account.nix ];

        virtualisation.vlans = [ 1 ];

        networking = {
          useNetworkd = true;
          useDHCP = false;
          firewall.allowedTCPPorts = [ 25 ];
          domain = "example.com";
          hosts."10.0.0.2" = [ "sender.example.com" ];
        };

        systemd.network.networks."01-eth1" = {
          name = "eth1";
          networkConfig.Address = "10.0.0.1/24";
        };

        services.postfix = {
          enable = true;

          localRecipients = [ "alice" ];

          settings = {
            main = {
              myhostname = config.networking.hostName;
              mydomain = config.networking.domain;
              mynetworks = [ "0.0.0.0/0" ];
              mydestination = [ "$mydomain" ];

              smtpd_recipient_restrictions = "permit_mynetworks, reject";
            };
          };
        };
      };

    sender =
      { config, ... }:
      {
        virtualisation.vlans = [ 1 ];

        networking = {
          useNetworkd = true;
          useDHCP = false;
          domain = "example.com";
          hosts."10.0.0.1" = [
            "receiver.example.com"
            "example.com"
          ];
        };

        systemd.network.networks."01-eth1" = {
          name = "eth1";
          networkConfig.Address = "10.0.0.2/24";
        };

        services.zeyple = {
          enable = true;
          keys = [ "${gpgKeyring}/pub.key" ];
        };

        services.postfix = {
          enable = true;

          localRecipients = [ "alice" ];

          settings = {
            main = {
              myhostname = config.networking.hostName;
              mydomain = config.networking.domain;
              mynetworks = [ "0.0.0.0/0" ];

              # relay_host = [ "[receiver.example.com]:25" ];
              # relay_domains = [ "example.com" ];

              smtpd_relay_restrictions = "permit_mynetworks, reject";
            };
          };
        };
      };
  };

  testScript = ''
    start_all()

    sender.wait_for_open_port(25, "receiver.example.com")
    sender.wait_for_unit("postfix.service")
    sender.succeed('printf "To: alice@example.com\r\n\r\nthis is the body of the email" | sendmail -t -i -f sender@example.com')

    receiver.wait_for_console_text("delivered to maildir")
    print(receiver.succeed("grep 'this is the body of the email' /var/spool/mail/alice/new/*"))
  '';
}
