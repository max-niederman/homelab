{ pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      htop
      neovim
    ];

    users = {
      mutableUsers = false;
      users.root = {
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINmdKg6WzEiyKysklc3YAKLjHEDLZq4RAjRYlSVbwHs9 max"
        ];
      };
    };

    services.openssh.enable = true;
  };
}
