let
  welcomeText = ''
    # `.devenv` and `direnv` should be added to `.gitignore`
    ```sh
      echo .devenv >> .gitignore
      echo .direnv >> .gitignore
    ```
  '';
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

  rust-stable = {
    inherit welcomeText;
    path = ./rust-stable;
    description = "Rust (latest stable from fenix) dev environment";
  };
in
{
  inherit
    javascript
    python
    rust
    rust-stable
    ;
  js = javascript;
  ts = javascript;
  py = python;
  rs = rust;
  rs-stable = rust-stable;
}
