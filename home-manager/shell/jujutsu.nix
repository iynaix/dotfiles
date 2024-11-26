_: {
  programs = {
    git.ignores = [ ".jj" ];
    jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "iynaix";
          email = "iynaix@gmail.com";
        };
        template-aliases = {
          "format_short_id(id)" = "id.shortest()";
        };
      };
    };
  };
}
