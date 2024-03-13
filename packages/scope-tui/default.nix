{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libpulseaudio,
}:

rustPlatform.buildRustPackage {
  pname = "scope-tui";
  version = "0-unstable-2024-02-20";

  src = fetchFromGitHub {
    owner = "alemidev";
    repo = "scope-tui";
    rev = "c928ea48992dcabcf1a8fa5435b11190b5c39400";
    hash = "sha256-4iL2yKTQmpul70Tn6cuRq2zofaftPzEjNGsVcJsIzPM=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  postPatch = ''
    ln -s ${./Cargo.lock} Cargo.lock
  '';

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ libpulseaudio ];

  meta = with lib; {
    description = "A simple oscilloscope/vectorscope/spectroscope for your terminal";
    homepage = "https://github.com/alemidev/scope-tui";
    license = licenses.mit;
    maintainers = with maintainers; [ iynaix ];
    mainProgram = "scope-tui";
  };
}
