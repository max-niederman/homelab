{ pkgs ? import <nixpkgs> { }
, lib ? import <nixpkgs/lib>
}:

with lib;
let
  hosts = import ./servers/hosts { };
  server = hosts.withName "beleg";
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    docker
    docker-compose
    nixpkgs-fmt
  ];
}
