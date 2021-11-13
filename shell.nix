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
    nomad
    (buildGoModule rec {
      pname = "levant";
      version = "0.3.0";

      src = fetchFromGitHub {
        owner = "hashicorp";
        repo = "levant";
        rev = "v${version}";
        sha256 = "9M7a4i+DPKb1H9jOEVAvhvYxGwtj3dK/40n4GSy4Rqo=";
      };

      vendorSha256 = "5JlrgmIfhX0rPR72sUkFcofw/iIbIaca359GN9C9dhU=";

      runVend = true;

      # testing disabled because it needs a Nomad cluster
      doCheck = false;

      meta = with lib; {
        description = "An open source templating and deployment tool for HashiCorp Nomad jobs";
        homepage = "https://github.com/hashicorp/levant";
        license = licenses.mpl20;
        platforms = platforms.linux ++ platforms.darwin;
      };
    })

    nixpkgs-fmt
  ];

  NOMAD_ADDR = "http://${server.address}:4646";
  CONSUL_HTTP_AGENT = "http://${server.address}:8500";
}
