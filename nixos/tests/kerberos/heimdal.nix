import ../make-test-python.nix (
  { pkgs, lib, ... }:
  {
    name = "kerberos_server-heimdal";

    nodes = {
      server =
        { config, pkgs, ... }:
        {
          imports = [ ../common/user-account.nix ];

          users.users.alice.extraGroups = [ "wheel" ];

          services.getty.autologinUser = "alice";

          virtualisation.vlans = [ 1 ];

          time.timeZone = "Etc/UTC";

          networking = {
            domain = "foo.bar";
            useDHCP = false;
            firewall.enable = false;
            hosts."10.0.0.1" = [ "server.foo.bar" ];
            hosts."10.0.0.2" = [ "client.foo.bar" ];
          };

          systemd.network.networks."01-eth1" = {
            name = "eth1";
            networkConfig.Address = "10.0.0.1/24";
          };

          security.krb5 = {
            enable = true;
            package = pkgs.heimdal;
            settings = {
              libdefaults.default_realm = "FOO.BAR";

              # Enable extra debug output
              logging = {
                admin_server = "SYSLOG:DEBUG:AUTH";
                default = "SYSLOG:DEBUG:AUTH";
                kdc = "SYSLOG:DEBUG:AUTH";
              };

              realms = {
                "FOO.BAR" = {
                  admin_server = "server.foo.bar";
                  kpasswd_server = "server.foo.bar";
                  kdc = [ "server.foo.bar" ];
                };
              };
            };
          };

          services.kerberos_server = {
            enable = true;
            settings.realms = {
              "FOO.BAR" = {
                acl = [
                  {
                    principal = "kadmin/admin@FOO.BAR";
                    access = "all";
                  }
                  {
                    principal = "alice/admin@FOO.BAR";
                    access = [
                      "add"
                      "cpw"
                      "delete"
                      "get"
                      "list"
                      "modify"
                    ];
                  }
                ];
              };
            };
          };
        };

      client =
        { config, pkgs, ... }:
        {
          imports = [ ../common/user-account.nix ];

          users.users.alice.extraGroups = [ "wheel" ];

          services.getty.autologinUser = "alice";

          virtualisation.vlans = [ 1 ];

          time.timeZone = "Etc/UTC";

          networking = {
            domain = "foo.bar";
            useDHCP = false;
            hosts."10.0.0.1" = [ "server.foo.bar" ];
            hosts."10.0.0.2" = [ "client.foo.bar" ];
          };

          systemd.network.networks."01-eth1" = {
            name = "eth1";
            networkConfig.Address = "10.0.0.2/24";
          };

          security.krb5 = {
            enable = true;
            package = pkgs.heimdal;
            settings = {
              libdefaults.default_realm = "FOO.BAR";

              logging = {
                admin_server = "SYSLOG:DEBUG:AUTH";
                default = "SYSLOG:DEBUG:AUTH";
                kdc = "SYSLOG:DEBUG:AUTH";
              };

              realms = {
                "FOO.BAR" = {
                  admin_server = "server.foo.bar";
                  kpasswd_server = "server.foo.bar";
                  kdc = [ "server.foo.bar" ];
                };
              };
            };
          };
        };
    };

    testScript =
      { nodes, ... }:
      let
        expectTemplate =
          program: argc: interaction:
          pkgs.writeScriptBin "${program}-auto-password" ''
            #!${pkgs.expect}/bin/expect -f

            set timeout 30
            ${lib.concatMapStringsSep "\n" (i: "set arg${toString i} [lindex $argv ${toString i}]") (
              lib.range 0 (argc - 1)
            )}
            set args [lrange $argv ${toString argc} end]
            eval spawn ${program} $args

            ${interaction}

            expect eof
            set exit_status [lindex [wait] 3]
            exit $exit_status
          '';

        kadmin = expectTemplate "kadmin" 1 ''
          expect {
              "alice/admin@FOO.BAR's Password: " {
                  send -- "$arg0\n"
              }
              timeout {
                  puts stderr "Error: Timeout waiting for password prompt"
                  exit 2
              }
              eof {
                  puts stderr "Error: kadmin exited unexpectedly"
                  break
              }
          }
        '';

        ktutil = expectTemplate "ktutil" 1 ''
          expect {
              "alice/admin@FOO.BAR's Password: " {
                  send -- "$arg0\n"
              }
              timeout {
                  puts stderr "Error: Timeout waiting for password prompt"
                  exit 2
              }
              eof {
                  puts stderr "Error: ktutil exited unexpectedly"
                  break
              }
          }
        '';

        kpasswd = expectTemplate "kpasswd" 2 ''
          set exchanges [list \
              [list "alice@FOO.BAR's Password: " $arg0] \
              [list "New password: " $arg1] \
              [list "Verify password - New password: " $arg1] \
          ]

          foreach pair $exchanges {
              lassign $pair prompt reply

              expect {
                  -exact $prompt {
                      send -- "$reply\n"
                  }
                  timeout {
                      puts stderr "Error: Timeout waiting for: $prompt"
                      exit 2
                  }
                  eof {
                      puts stderr "Error: Unexpected EOF while waiting for: $prompt"
                      exit 3
                  }
              }
          }
        '';
      in
      ''
        import string
        import random
        random.seed(0)

        start_all()

        with subtest("Server: initialize realm"):
          for unit in ["kadmind.service", "kdc.service", "kpasswdd.service"]:
              server.wait_for_unit(unit)

          server.succeed("kadmin -l init --realm-max-ticket-life='8 day' --realm-max-renewable-life='10 day' FOO.BAR")

          for unit in ["kadmind.service", "kdc.service", "kpasswdd.service"]:
              server.systemctl(f"restart {unit}")

        alice_krb_pw = "alice_hunter2"
        alice_old_krb_pw = ""
        alice_krb_admin_pw = "alice_admin_hunter2"
        bob_krb_pw = "bob_hunter2"

        def random_password():
          password_chars = string.ascii_letters + string.digits + "-_"
          return "".join(random.choice(password_chars) for _ in range(16))

        def kinit(node, user, password):
          node.succeed(
            f"echo '{password}' > /tmp/pw.txt",
            f"kinit --password-file=/tmp/pw.txt {user}",
            "rm /tmp/pw.txt",
          )
          tickets = node.succeed("klist")
          assert f"Principal: {user}@FOO.BAR" in tickets

        def kadmin(node, command, localAuth=False):
          if localAuth:
            return node.succeed(f"kadmin -l {command}")
          else:
            return node.succeed(f"${lib.getExe kadmin} '{alice_krb_admin_pw}' -p alice/admin {command}")

        with subtest("Server: initialize user principals and keytabs"):
          kadmin(server, f'add --password="{alice_krb_admin_pw}" --use-defaults alice/admin', localAuth=True)
          kadmin(server, f'add --password="{alice_krb_pw}" --use-defaults alice')
          kadmin(server, f'add --password="{bob_krb_pw}" --use-defaults bob')
          kadmin(server, 'check')

        server.wait_for_unit("getty@tty1.service")
        server.wait_until_succeeds("pgrep -f 'agetty.*tty1'")
        server.wait_for_unit("default.target")

        with subtest("Server: initialize host principal with keytab"):
          server.succeed(f"${lib.getExe ktutil} '{alice_krb_admin_pw}' get -p alice/admin host/server.foo.bar")
          server.wait_for_file("/etc/krb5.keytab")

          ktutil_list = server.succeed("ktutil list")
          if not "host/server.foo.bar" in ktutil_list:
            exit(1)

        client.systemctl("start network-online.target")
        client.wait_for_unit("network-online.target")
        client.wait_for_unit("getty@tty1.service")
        client.wait_until_succeeds("pgrep -f 'agetty.*tty1'")
        client.wait_for_unit("default.target")

        with subtest("Client: initialize host principal with keytab"):
          kinit(client, "alice/admin", alice_krb_admin_pw)
          client.succeed(f"${lib.getExe ktutil} '{alice_krb_admin_pw}' get -p alice/admin host/client.foo.bar")
          client.wait_for_file("/etc/krb5.keytab")

          ktutil_list = client.succeed("ktutil list")
          if not "host/client.foo.bar" in ktutil_list:
            exit(1)

        with subtest("Client: kinit alice"):
          kinit(client, "alice", alice_krb_pw)

        with subtest("Client: kpasswd alice"):
          alice_old_krb_pw = alice_krb_pw
          alice_krb_pw = random_password()
          output = client.succeed(f"${lib.getExe kpasswd} {alice_old_krb_pw} {alice_krb_pw}")
          assert "Success : Password changed" in output

        with subtest("Client: kadmin get bob"):
          output = kadmin(client, "get bob")
          print(output)
          assert "Principal: bob@FOO.BAR" in output

        with subtest("Server: kinit alice"):
          kinit(server, "alice", alice_krb_pw)

        with subtest("Server: kpasswd alice"):
          alice_old_krb_pw = alice_krb_pw
          alice_krb_pw = random_password()
          output = server.succeed(f"${lib.getExe kpasswd} {alice_old_krb_pw} {alice_krb_pw}")
          assert "Success : Password changed" in output

        with subtest("Server: kadmin get bob"):
          output = kadmin(server, "get bob")
          assert "Principal: bob@FOO.BAR" in output
      '';

    meta.maintainers = pkgs.heimdal.meta.maintainers;
  }
)
