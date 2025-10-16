{
  flake.modules.nixos.keyd = {
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings.main = {
          capslock = "overload(meta, esc)";
          rightshift = "C-s";
          rightalt = "C-c";
          rightcontrol = "C-v";
        };
      };
    };
  };
}
