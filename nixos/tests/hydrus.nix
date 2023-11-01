import ./make-test-python.nix ({ pkgs, ... }: {
  name = "hydrus";

  meta = with pkgs.lib.maintainers; {
    maintainers = [ h7x4 ];
  };

  nodes = {
    server = { ... }: {
      virtualisation.vlans = [ 1 ];

      networking = {
        useNetworkd = true;
        useDHCP = false;
        firewall.enable = false;
      };

      systemd.network.networks."01-eth1" = {
        name = "eth1";
        networkConfig.Address = "10.0.0.1/24";
      };

      services.hydrus.enable = true;
    };

    client = { ... }: {
      virtualisation.vlans = [ 1 ];

      networking = {
        useNetworkd = true;
        useDHCP = false;
        firewall.enable = false;
      };

      systemd.network.networks."01-eth1" = {
        name = "eth1";
        networkConfig.Address = "10.0.0.2/24";
      };

      environment.systemPackages = with pkgs; [ hydrus ];
    };
  };

  testScript = { nodes, ... }: ''
    start_all()

    server.wait_for_unit("hydrus.service")
    server.wait_for_open_port(45870)
  '';
})
