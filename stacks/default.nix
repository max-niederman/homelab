{ pkgs ? import <nixpkgs> { }
, lib ? import <nixpkgs/lib>
}:

with lib;

let
  networkSources = import ./networks.nix;

  stackSources = with attrsets;
    mapAttrs
      (path: _: import (./. + "/${path}") { inherit pkgs; lib = import ./lib.nix lib; })
      (filterAttrs
        (_: type: type == "directory")
        (builtins.readDir ./.));

  # slightly modified version of `pkgs.formats.yaml`
  buildStack = name: { compose, binds ? { } }:
    let
      composeJSON = builtins.toJSON compose;
      bindsLines = strings.concatStringsSep "\n" (attrsets.attrValues binds);
    in
    pkgs.runCommandLocal
      name
      {
        nativeBuildInputs = [ pkgs.remarshal ];
        inherit composeJSON bindsLines;
        passAsFile = [ "composeJSON" "bindsLines" ];
      }
      ''
        mkdir "$out"
        cp "$bindsLinesPath" "$out/binds"
        json2yaml "$composeJSONPath" "$out/docker-compose.yml"
      '';
in
rec {
  stacks = attrsets.mapAttrs buildStack stackSources;
  stackFarm = pkgs.linkFarmFromDrvs
    "homelab-stacks"
    (attrsets.attrValues stacks);

  networks = {
    create = pkgs.writeShellScriptBin "homelab-networks-create"
      (strings.concatStrings
        (attrsets.mapAttrsToList
          (name: { subnet }:
            "${pkgs.docker}/bin/docker network create ${name} -d overlay --subnet ${subnet}\n")
          networkSources));

    destroy = pkgs.writeShellScriptBin "homelab-networks-destroy"
      (strings.concatStrings
        (attrsets.mapAttrsToList
          (name: { subnet }:
            "${pkgs.docker}/bin/docker network rm ${name}\n")
          networkSources));
  };


  deploy = pkgs.writeShellScriptBin "homelab-deploy" ''
    name=$1

    # initializing binds
    echo "Initializing binds"
    for bind in $(cat ${stackFarm}/$name/binds)
    do
      if [ ! -d "$bind" ]; then
        if [ -f "$bind" ]; then
          echo "File collided with bind $bind"
          echo "Should we remove the file?"
          rm -i "$bind"
        fi

        echo "Initiatalizing bind $bind"
        mkdir -p "$bind"
      else
        echo "Skipping already initialized bind $bind"
      fi

      echo "Setting permissions on $bind"
      chmod -R 777 "$bind"
      chown -R "root:root" "$bind"
    done

    # deploy Compose stack
    echo "Deploying stack to Docker Swarm"
    docker stack deploy -c ${stackFarm}/$name/docker-compose.yml $name
  '';

  deploy-all = pkgs.writeShellScriptBin "homelab-deploy-all" ''
    for filename in ${stackFarm}/*; do
      name=$(basename $filename)
      ${deploy}/bin/homelab-deploy $name
    done
  '';
}
