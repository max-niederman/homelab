{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      neovim
    ];

    users = {
      mutableUsers = false;
      users = lib.genAttrs
        [ "root" ]
        (_: {
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINmdKg6WzEiyKysklc3YAKLjHEDLZq4RAjRYlSVbwHs9 max@tar-minyatur"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLIO4au21QNFa+ILVOwqIJSy8fO3VlsNhyFxONPwU3N max@tar-elendil"
          ];
        });
    };

    services.openssh.enable = true;
  };
}
