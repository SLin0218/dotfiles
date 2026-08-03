{ pkgs }:

let
  stdenv = pkgs.stdenv;
  system = stdenv.hostPlatform.system;

  srcs = {
    "aarch64-darwin" = {
      url = "https://cache-redirector.jetbrains.com/intellij-jbr/jbrsdk-17.0.12-osx-aarch64-b1087.25.tar.gz";
      sha256 = "1ihpijnwdyvl3pqjszfi17rxhsq0ikdaq3r33fiwyi7z08gmmfpp";
    };
    "x86_64-linux" = {
      url = "https://cache-redirector.jetbrains.com/intellij-jbr/jbrsdk-17.0.12-linux-x64-b1087.25.tar.gz";
      sha256 = "0cxxw02mad2ljlry78f7km9d7plkpgnspxggy9q2h2ly4fz452vi";
    };
  };

  srcAttrs = srcs.${system} or (throw "Unsupported system architecture: ${system}");

  # 保持原始 JBR 17 二进制文件不被 patchelf 修改
  jbrRaw = stdenv.mkDerivation rec {
    pname = "jbrsdk-17-raw";
    version = "17.0.12-b1087.25";

    src = pkgs.fetchurl {
      inherit (srcAttrs) url sha256;
    };

    dontBuild = true;
    dontStrip = true;
    dontPatchELF = true;
    dontPatchelf = true;

    installPhase = ''
      mkdir -p $out
      if [ -d Contents/Home ]; then
        cp -r Contents/Home/* $out/
      else
        cp -r * $out/
      fi
    '';
  };

in
if stdenv.isDarwin then
  jbrRaw
else
  # 在 Linux 下使用 FHS 环境包装，解决 autoPatchelfHook 破坏 libjimage.so 导致的 SIGSEGV 崩溃
  pkgs.buildFHSEnv {
    name = "java";
    targetPkgs = pkgs: (with pkgs; [
      alsa-lib
      fontconfig
      freetype
      libx11
      libxext
      libxi
      libxrender
      libxtst
      libxrandr
      libxcursor
      libxcb
      wayland
      zlib
      stdenv.cc.cc.lib
    ]);
    runScript = "${jbrRaw}/bin/java";
    passthru = {
      home = jbrRaw;
    };
  }


