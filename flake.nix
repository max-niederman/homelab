{
  description = "Max Niederman's homelab.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    deploy-rs.url = "github:serokell/deploy-rs";
    sops-nix.url = "github:Mic92/sops-nix";
    dns.url = "github:nix-community/dns.nix";
  };

  outputs = { self, nixpkgs, flake-utils, deploy-rs, sops-nix, dns, }:
    {
      nixosConfigurations = {
        beleg = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/beleg

            ./modules

            sops-nix.nixosModules.sops
          ];
          specialArgs = { inherit dns; };
        };
      };

      deploy.nodes = {
        beleg = {
          hostname = "beleg.banded-scala.ts.net";
          profiles.system = {
            sshUser = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos
              self.nixosConfigurations.beleg;
          };
        };
      };
    } // flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        deployPkgs = deploy-rs.packages.${system};
      in {
        formatter = pkgs.alejandra;

        devShells.default = pkgs.mkShell {
          name = "homelab";
          buildInputs = [
            deployPkgs.deploy-rs

            pkgs.sops
            pkgs.age
            pkgs.ssh-to-age

            pkgs.alejandra
          ];
        };
      });
}
