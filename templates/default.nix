let
  javascript = {
    path = ./javascript;
    description = "Javascript / Typescript dev environment";
  };

  javascript-devenv = {
    path = ./javascript-devenv;
    description = "Javascript / Typescript dev environment using devenv";
  };

  python = {
    path = ./python;
    description = "Python dev environment";
  };

  rust = {
    path = ./rust;
    description = "Rust dev environment";
  };
in
{
  inherit
    javascript
    javascript-devenv
    python
    rust
    ;
  js = javascript;
  ts = javascript;
  js-devenv = javascript-devenv;
  ts-devenv = javascript-devenv;
  py = python;
  rs = rust;
}
