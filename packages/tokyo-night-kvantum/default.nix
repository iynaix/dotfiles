{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation {
  pname = "tokyo-night-kvantum";
  version = "0-unstable-2024-08-08";

  src = fetchFromGitHub {
    owner = "0xsch1zo";
    repo = "Kvantum-Tokyo-Night";
    rev = "82d104e0047fa7d2b777d2d05c3f22722419b9ee";
    hash = "sha256-Uy/WthoQrDnEtrECe35oHCmszhWg38fmDP8fdoXQgTk=";
  };
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/Kvantum
    cp -a Kvantum-Tokyo-Night $out/share/Kvantum
    runHook postInstall
  '';

  meta = {
    description = "Tokyo Night Kvantum theme";
    homepage = "https://github.com/0xsch1zo/Kvantum-Tokyo-Night";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ iynaix ];
    mainProgram = "kvantum-tokyo-night";
    platforms = lib.platforms.all;
  };
}
