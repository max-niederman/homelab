{ pkgs ? import <nixpkgs> { }
, lib ? import <nixpkgs/lib>
}:

with lib;
let
  nixpkgsRev = "nixos-22.05";

  hosts = import ./hosts { };
  server = hosts.withName "beleg";

  homelab-deploy =
    let
      leaderAddr = (head (hosts.withRole "leader")).address;
    in
    pkgs.writeShellScriptBin "homelab-deploy" ''
      nixops deploy

      if [ -z $1 ]; then
        ssh ${leaderAddr} -t "homelab-deploy-all"
      else
        ssh ${leaderAddr} -t "homelab-deploy $1"
      fi
    '';
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    docker
    docker-compose
    nixpkgs-fmt

    homelab-deploy
  ];

  NIX_PATH = "nixpkgs=https://github.com/NixOS/nixpkgs/archive/${nixpkgsRev}.tar.gz";
}
