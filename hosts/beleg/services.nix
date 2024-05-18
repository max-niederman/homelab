{...}: {
  config = {
    hcontainers = {
      prometheus = {
        config = {...}: {
          services.prometheus = {
            enable = true;
            port = 80;
          };
        };
      };
    };
  };
}
