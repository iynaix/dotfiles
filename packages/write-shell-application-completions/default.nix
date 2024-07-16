{
  lib,
  symlinkJoin,
  writeShellApplication,
  writeTextFile,
}:
{
  name,
  bashCompletion ? null,
  zshCompletion ? null,
  fishCompletion ? null,
  ...
}@shellArgs:
let
  app = writeShellApplication (
    lib.removeAttrs shellArgs [
      "bashCompletion"
      "zshCompletion"
      "fishCompletion"
    ]
  );
  completions =
    lib.optional (bashCompletion != null) (writeTextFile {
      name = "${name}.bash";
      destination = "/share/bash-completion/completions/${name}.bash";
      text = bashCompletion;
    })
    ++ lib.optional (zshCompletion != null) (writeTextFile {
      name = "${name}.zsh";
      destination = "/share/zsh/site-functions/_${name}";
      text = zshCompletion;
    })
    ++ lib.optional (fishCompletion != null) (writeTextFile {
      name = "${name}.fish";
      destination = "/share/fish/vendor_completions.d/${name}.fish";
      text = fishCompletion;
    });
in
if lib.length completions == 0 then
  app
else
  symlinkJoin {
    inherit name;
    inherit (app) meta;
    paths = [ app ] ++ completions;
  }
