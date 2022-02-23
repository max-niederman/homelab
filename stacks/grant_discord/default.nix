{ pkgs, lib }:

with lib;
rec {
  binds =
    let
      gen = stacks.getBindTarget "grant_discord"; in
    {
      redbot = gen "/redbot";
    };

  compose = {
    version = "3";

    services.redbot = {
      image = "phasecorex/red-discordbot";
      volumes = [ "${binds.redbot}:/data" ];
      environment = {
        PREFIX = "!";
        PUID = "1000";
        PGID = "1000";
      };
    };
  };
}
