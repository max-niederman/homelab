{
  description = "Max Niederman's homelab.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      beleg = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./modules ];
      };
    };
  };
}