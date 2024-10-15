let
  javascript = {
    path = ./javascript;
    description = "Javascript / Typescript dev environment";
  };

  python = {
    path = ./python;
    description = "Python dev environment";
  };

  rust = {
    path = ./rust;
    description = "Rust dev environment";
  };

  rust-stable = {
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
