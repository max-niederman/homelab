{
  network = {
    description = "homelab";
    storage = {
      legacy.databasefile = "~/.nixops/deployments.nixops";
    };
  };

  defaults = {
    imports = [ ./modules ];
  };

  beleg = import ./hosts/beleg;
}
