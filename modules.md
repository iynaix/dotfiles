## Motivation

I liked the standardized module format that flake-parts offered, along with being able to freely move files around with libraries like [import-tree](https://github.com/denful/import-tree) or similar. I also liked being able to defined a wrapped package to be exposed in flake.packages as well as the config around that package in a single file.

However, I did not like the amount of boilerplate of flake-parts or having to come up with arbitrary names for modules that ultimately only housed a single application for a single host and then
assembling lists of these modules for each host.

So I decided to reinvent the wheel, and write the module system I wanted to use, heavily inspired by [nosh](https://codeberg.org/poacher/nosh).

The implementation can be found in [flake-lib.nix](./flake-lib.nix).

## Modules

Each module within `modules/` is an attrset with the following attrs:

1. `enabled ? true` optionally defines if the module will be used
2. `tags ? null` optionally defines which tags this module will be used for
3. `hosts ? null` optionally defines which hosts this module will be used on
4. `packages ? null` optionally defines packages to be exposed in the flake's `packages`
5. `config ? {}` defines the configuration for the module

```nix
{
    enabled = true;

    tags = [ "gaming" ];
    hosts = [ "laptop" ];

    packages = { pkgs, ... }: {
        # packages
    };

    config = { /* specialArgs */ }: {
        # config
    };
}
```

## mkHost

Each host is then created with the `mkHost` function with the following arguments:

`hostName` the name of the host, and an attrset with the following attrs:

1. `system ? "x86_64-linux"` the system passed to `nixosSystem`
2. `tags ? null` optionally defines a list of tags that this system will have
3. `specialArgs ? {}` optionally defines the specialArgs attr of nixosSystem, the following arguments will also be provided:
    - `host` the name of the host
    - `tags` the tags of the host
    - `system` the system passed to `nixosSystem` (ain't nobody got time to type `pkgs.stdenv.hostPlatform.system`)
4. `modules ? []` optionally defines a list of modules or directories the will be imported

```nix
{
    nixosConfigurations = {
        laptop = mkHost "laptop" {
            system = "x86_64-linux"; # optional as x86_64-linux is the default
            tags = [ "gaming" "impermanence" "laptop" ];
            specialArgs = { inherit inputs self; };
            modules = [ ./modules ];
        }
    };
}
```

## mkPackages

Packages can be created with the `mkPackages` function with the following arguments:

`pkgs` the nixpkgs package set
`modules` the list of modules or directories where packages are defined
`packagesArgs` the arguments that will be passed to the `packages` function of each module, the following arguments will also be provided:
    - `pkgs` the nixpkgs package set
    - `system` shorthand for `pkgs.stdenv.hostPlatform.system`

```nix
{
    packages = mkPackages pkgs [ ./modules ] {
        inherit inputs self;
    };
}
```
