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
  inherit (flake.inputs.nixpkgs) lib;
in
(
  flake.nixosConfigurations
  |> lib.attrNames
  |> lib.filter (n: !(lib.hasInfix "-" n))
  |> map (
    name:
    let
      cfg = flake.nixosConfigurations.${name}.config;
    in
    {
      # utility variables for each host
      "${name}" = cfg;
      "${name}o" = cfg.custom;
    }
  )
  |> lib.mergeAttrsList
)
// rec {
  inherit lib;
  inherit (flake) inputs;
  inherit flake host user;
  self = flake;

  # default host
  inherit (flake.nixosConfigurations.${host}) pkgs;
  c = flake.nixosConfigurations.${host}.config;
  config = c;
  o = c.custom;

  # testing specialisations
  spec = c: spec_name: c.specialisation.${spec_name}.configuration;

  tty = c.specialisation.tty.configuration;
  niri = c.specialisation.niri.configuration;
  hyprland = c.specialisation.hyprland.configuration;
  # mango = c.specialisation.mango.configuration;

  # your code here
}
