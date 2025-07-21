# better repl with preloaded functions and libs already loaded
# https://bmcgee.ie/posts/2023/01/nix-and-its-slow-feedback-loop/#how-you-should-use-the-repl
{
  # host is passed down from the nrepl via a --arg argument, defaulting to the current host
  host ? "desktop",
  ...
}:
let
  user = "iynaix";
  flake = builtins.getFlake (toString ./.);
  inherit (flake) lib;
in
lib.pipe (lib.attrNames flake.nixosConfigurations) [
  (lib.filter (n: !(lib.hasInfix "-" n)))
  (map (
    name:
    let
      cfg = flake.nixosConfigurations.${name}.config;
    in
    {
      # utility variables for each host
      "${name}" = cfg;
      "${name}o" = cfg.custom;
      "${name}Hm" = cfg.hm;
      "${name}Hmo" = cfg.hm.custom;
    }
  ))
  lib.mergeAttrsList
]
// rec {
  inherit lib;
  inherit (flake) inputs self;
  inherit flake host user;

  # default host
  inherit (flake.nixosConfigurations.${host}) pkgs;
  c = flake.nixosConfigurations.${host}.config;
  config = c;
  o = c.custom;
  inherit (c) hm;
  hmo = hm.custom;

  # testing specialisations
  spec = c: spec_name: c.specialisation.${spec_name}.configuration;
  specHm = c: spec_name: (spec c spec_name).hm;

  # your code here
}
