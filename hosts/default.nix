{ lib ? import <nixpkgs/lib> }:

with builtins;
with lib;
rec {
  # all :: [Host]
  all = with attrsets;
    mapAttrsToList
      (path: _: recursiveUpdate (import (./. + "/${path}")) { name = path; })
      (filterAttrs
        (_: type: type == "directory")
        (readDir ./.));

  # withRole :: String -> [Host]
  withRole = role: filter (host: elem role host.roles) all;
  # withName :: String -> Host
  withName = name: lists.findFirst (host: host.name == name) null all;
}
