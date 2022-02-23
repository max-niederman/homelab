self: super:

let
  lib = import <nixpkgs/lib>;
  stackPkgs = import ../stacks { pkgs = self; };
in
{
  homelab = {
    inherit (stackPkgs)
      stacks stackFarm
      networks
      deploy deploy-all;
  };

  pterodactyl-wings = with self;
    buildGoModule rec {
      pname = "pterodactyl-wings";
      version = "1.5.3";

      src = fetchFromGitHub {
        owner = "pterodactyl";
        repo = "wings";
        rev = "v${version}";
        sha256 = "2Tdx37/rojpj2d9Pm7KV6MFNveYmEqbP94HaJuwT4O4=";
      };

      vendorSha256 = "ni02sXxCHBUVadLbXsjVzy1rcBJwnk5q3YgnQiBPBKA=";

      proxyVendor = true;

      meta = with lib; {
        description = "The server control plane for Pterodactyl Panel.";
        homepage = "https://pterodactyl.io/";
        license = licenses.mit;
      };
    };
}
