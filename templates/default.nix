let
  welcomeText = ''
    # `.devenv` and `direnv` should be added to `.gitignore`
    ```sh
      echo .devenv >> .gitignore
      echo .direnv >> .gitignore
    ```
  '';
in rec {
  javascript = {
    inherit welcomeText;
    path = ./javascript;
    description = "Javascript / Typescript dev environment";
  };

  python = {
    inherit welcomeText;
    path = ./python;
    description = "Python dev environment";
  };

  rust = {
    inherit welcomeText;
    path = ./rust;
    description = "Rust dev environment";
  };

  js = javascript;
  ts = javascript;
  py = python;
  rs = rust;
}
