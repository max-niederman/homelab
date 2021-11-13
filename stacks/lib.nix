super:

with builtins;
with super;

attrsets.recursiveUpdate super
rec {
  attrsets = super.attrsets // {
    flattenAttrs =
      with attrsets;
      let
        # flattenAttrs' :: nullOr str -> any -> attrsOf (not attrs)
        flattenAttrs' = path: val:
          if isAttrs val
          then
            lists.concatLists
              (mapAttrsToList
                (name: flattenAttrs' (if path == null then name else "${path}.${name}"))
                val)
          else [{
            name = path;
            value = val;
          }];
      in
      val: trivial.pipe val [ (flattenAttrs' null) listToAttrs ];
  };

  /*
    * utility functions for writing Docker Compose stacks
  */
  stacks = rec {
    getBindTarget = app: path: "/data/${app}${path}";

    # transform nested attrset into key-value labels for Docker
    genKVLabels = val: trivial.pipe val [
      attrsets.flattenAttrs
      (attrsets.mapAttrsToList (name: val: "${name}=${toString val}"))
    ];

    traefik = {
      genSimpleLabels =
        { name
        , port
        , domain ? name
        , service ? name
        , router ? name
        }:
        genKVLabels {
          traefik = {
            enable = true;
            network = "public";
            http = {
              services.${service}.loadbalancer.server.port = port;
              routers.${router} = {
                inherit service;
                # matches on any top-level domain
                rule = "HostRegexp(`${domain}{tld:(\\.\\S+)*\\.?}`)";
              };
            };
          };
        };
    };
  };
}
