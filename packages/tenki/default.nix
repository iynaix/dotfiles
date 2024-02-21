{
  lib,
  rustPlatform,
  source,
}:
rustPlatform.buildRustPackage (
  {
    inherit (source) pname version src;
    cargoLock = source.cargoLock."Cargo.lock";
  }
  // {
    meta = with lib; {
      description = "Tty-clock with weather effect";
      homepage = "https://github.com/ckaznable/tenki";
      license = licenses.mit;
      maintainers = with maintainers; [ iynaix ];
      mainProgram = "tenki";
    };
  }
)
