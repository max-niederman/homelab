{
  config = {
    boot.kernelPatches = [
      # see https://github.com/tailscale/tailscale/issues/13863
      {
        name = "fix problems with netfilter in 6.11.4";
        patch = ./fix-netfilter-6.11.4.patch;
      }
    ];
  };
}