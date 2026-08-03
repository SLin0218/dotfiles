{ pkgs }:

pkgs.python3Packages.buildPythonApplication {
  pname = "t";
  version = "1.0.0";

  src = ./.;

  pyproject = true;

  nativeBuildInputs = [
    pkgs.python3Packages.setuptools
  ];

  propagatedBuildInputs = with pkgs.python3Packages; [
    requests
    cryptography
    rich
  ];

}
