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

      vendorSha256 = "QuLUEDH+YZUME1nE3P6HnWhZmSfCSORElS6+x0oWEjM=";

      runVend = true;

      meta = with lib; {
        description = "The server control plane for Pterodactyl Panel.";
        homepage = "https://pterodactyl.io/";
        license = licenses.mit;
      };
    };
}
