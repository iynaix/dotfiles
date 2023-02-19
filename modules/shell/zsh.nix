{ pkgs, user, config, ... }: {
  config = {
    home-manager.users.${user} = {
      home = {
        packages = with pkgs; [ zsh zsh-powerlevel10k ];

        # TODO: use starship?

        file.".config/zsh" = {
          source = ./zsh;
          recursive = true;
        };

        # zsh shortcuts
        # programs.zsh.shellAliases = lib.mapAttrs (name: value: "cd ${value}") config.iynaix.shortcuts;
      };
    };

    iynaix.persist.home = {
      # directories = [
      #   ".cache/zsh4humans" # TODO: remove when switching to starship?
      # ];
      files = [
        ".config/zsh/.zsh_history"
      ];
    };
  };
}
