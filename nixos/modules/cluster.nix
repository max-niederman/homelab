{ config, pkgs, lib, ... }:

{
  config = {
    # unfortunately we can't declaratively specify Docker Swarm configurations, because joining a Swarm requires a token
    # also, Docker's configuration is extremely imperative, and therefore not well-suited to Nixops even if it were possible

    virtualisation.docker = {
      enable = true;
      liveRestore = false; # live restore is incompatible with Swarm mode
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
  };
}

