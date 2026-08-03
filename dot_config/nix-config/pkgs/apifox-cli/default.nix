{ pkgs }:

pkgs.buildNpmPackage rec {
  pname = "apifox-cli";
  version = "2.2.7";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/apifox-cli/-/apifox-cli-${version}.tgz";
    hash = "sha256-HH/lTa7ndhBR0EM+oxeD458zDeuskWFSe8sBsjSMbcY=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  npmDepsHash = "sha256-ZXloElpQ3IJAS+CT/CmE6J+kt0znnLMrTkrpNgZjv5w=";

  npmInstallFlags = [ "--omit=optional" ];

  meta = with pkgs.lib; {
    description = "Apifox CLI";
    homepage = "https://apifox.com/";
    license = licenses.unfree;
    mainProgram = "apifox";
  };
}
