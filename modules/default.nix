{
  imports = [
    ./kernel
    ./administration.nix
    ./networking.nix
    ./services/caddy.nix
    ./services/monitoring.nix
  ];

  config = {
    sops = {
      defaultSopsFile = ../secrets.yaml;
      age.sshKeyPaths = ["/persist/ssh/ssh_host_ed25519_key"];
    };

    services.openssh = {
      enable = true;
      hostKeys = [
        {
          path = "/persist/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/persist/ssh/ssh_host_rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];
    };
  };
}
