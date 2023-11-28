{
  lib,
  python3,
  fetchFromGitHub,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "open-clip";
  version = "2.23.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "mlfoundations";
    repo = "open_clip";
    rev = "v${version}";
    hash = "sha256-Txm47Tc4KMbz1i2mROT+IYbgS1Y0yHK80xY0YldgBFQ=";
  };

  nativeBuildInputs = [
    python3.pkgs.setuptools
    python3.pkgs.wheel
  ];

  propagatedBuildInputs = with python3.pkgs; [
    ftfy
    huggingface-hub
    protobuf
    regex
    sentencepiece
    timm
    torch
    torchvision
    tqdm
  ];

  pythonImportsCheck = ["open_clip"];

  meta = with lib; {
    description = "An open source implementation of CLIP";
    homepage = "https://github.com/mlfoundations/open_clip";
    license = licenses.mit;
    maintainers = with maintainers; [iynaix];
    mainProgram = "open-clip";
  };
}
