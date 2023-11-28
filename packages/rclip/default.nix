{
  lib,
  python3,
  fetchFromGitHub,
  open-clip-torch,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "rclip";
  version = "1.7.6";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "yurijmikhalevich";
    repo = "rclip";
    rev = "v${version}";
    hash = "sha256-lWaWq+dcAa/2pONka4xRpixqDuL6iYDF46vCyCmVWwE=";
  };

  nativeBuildInputs = [
    python3.pkgs.poetry-core
  ];

  propagatedBuildInputs = with python3.pkgs; [
    open-clip-torch
    pillow
    requests
    torch
    torchvision
    tqdm
  ];

  pythonImportsCheck = ["rclip"];

  meta = with lib; {
    description = "AI-Powered Command-Line Photo Search Tool";
    homepage = "https://github.com/yurijmikhalevich/rclip";
    license = licenses.mit;
    maintainers = with maintainers; [iynaix];
    mainProgram = "rclip";
  };
}
