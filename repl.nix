# better repl with preloaded functions and libs already loaded
# https://bmcgee.ie/posts/2023/01/nix-and-its-slow-feedback-loop/#how-you-should-use-the-repl
{
  # host is passed down from the nrepl via a --arg argument, defaulting to the current host
  host ? "desktop",
  ...
}: let
  user = "iynaix";
  flake = builtins.getFlake (toString ./.);
  lib = flake.inputs.nixpkgs.lib;
  hosts = ["desktop" "laptop" "vm"];
  vars = lib.attrsets.mergeAttrsList (builtins.map (host: let
      hostCfg = flake.nixosConfigurations.${host}.config;
      hmCfg = hostCfg.home-manager.users.${user};
    in {
      "${host}" = hostCfg;
      "${host}Opts" = hostCfg.iynaix-nixos;
      "${host}Hm" = hmCfg;
      "${host}HmOpts" = hmCfg.iynaix;
      "${host}OptsHm" = hmCfg.iynaix;
    })
    hosts);
in
  {
    inherit (flake) inputs;
    inherit (flake.inputs) nixpkgs;
    inherit lib host user;
  }
  // rec {
    # default host
    c = flake.nixosConfigurations.${host}.config;
    co = c.iynaix-nixos;
    hm = c.home-manager.users.${user};
    hmo = hm.iynaix;
  }
  // vars
  // {
    # your code here
  }
