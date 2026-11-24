{ pkgs }:

pkgs.stdenvNoCC.mkDerivation rec {
  pname = "lxgw-975-yuan";
  version = "26.07.26";

  src = pkgs.fetchFromGitHub {
    owner = "lxgw";
    repo = "975Yuan";
    rev = version;
    hash = "sha256-iN6AiIcAqkO9KgSkTDlS1Y2RSx26ACtukcVqvVOqgJ8=";
  };

  installPhase = ''
    runHook preInstall
    install -Dm644 TTF/*.ttf -t $out/share/fonts/truetype
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "霞鹜975圆体 / LXGW 975 Yuan";
    homepage = "https://github.com/lxgw/975Yuan";
    license = licenses.ofl;
    platforms = platforms.all;
  };
}
