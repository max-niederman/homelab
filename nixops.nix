with import <nixpkgs/lib>;
let
  hosts = import ./hosts { };
  machines = builtins.listToAttrs
    (builtins.map
      (host: {
        name = host.name;
        value = ({ config, pkgs, lib, ... } @ args:
          attrsets.recursiveUpdate
            (attrsets.setAttrByPath [ "homelab" "host" ] host)
            (host.nixosConfig args));
      })
      hosts.all);
in
machines // {
  network = {
    description = "homelab";
    storage = {
      legacy.databasefile = "~/.nixops/deployments.nixops";
    };
  };

  defaults = {
    imports = [ ./nixos/modules ];
  };

  # keys = import ./keys;
}
