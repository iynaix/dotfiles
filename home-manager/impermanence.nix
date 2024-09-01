# note: this file exists just to define options for home-manager,
# impermanence is not actually used in standalone home-manager as
# it doesn't serve much utility on legacy distros
{ lib, ... }:
{
  options.custom = with lib; {
    persist = {
      home = {
        directories = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Directories to persist in home directory";
        };
        files = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Files to persist in home directory";
        };
        cache = {
          directories = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Directories to persist, but not to snapshot";
          };
          files = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Files to persist, but not to snapshot";
          };
        };
      };
    };
  };
}
