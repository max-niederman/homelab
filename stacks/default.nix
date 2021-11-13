{ pkgs ? import <nixpkgs> { }
, lib ? import <nixpkgs/lib> { }
, networks ? import ./networks.nix
}:

with lib;
rec {
  stacks = builtins.path {
    name = "homelab-stacks";
    path = ./.;
    filter = path: type: !strings.hasSuffix ".nix";
  };

  create-networks = pkgs.writeShellScriptBin "homelab-create-networks"
    (strings.concatStrings
      (attrsets.mapAttrsToList
        (name: { subnet }:
          "${pkgs.docker}/bin/docker network create ${name} -d overlay --subnet ${subnet}\n")
        networks));

  deploy = pkgs.writeShellScriptBin "homelab-deploy" ''
    name=$1
    docker stack deploy -c ${stacks}/$name/docker-compose.yml $name
  '';

  deploy-all = pkgs.writeShellScriptBin "homelab-deploy-all" ''
    for filename in ${stacks}/*; do
      name=$(basename $filename)
      ${homelab-deploy}/bin/homelab-deploy $name
    done
  '';
}

