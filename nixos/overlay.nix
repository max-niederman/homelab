self: super:

let
  stackPkgs = import ../stacks { pkgs = self; };
in
{
  homelab = {
    inherit (stackPkgs)
      stacks stackFarm
      networks
      deploy deploy-all;
  };
}
