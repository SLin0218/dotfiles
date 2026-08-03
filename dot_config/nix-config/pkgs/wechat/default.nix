{ pkgs }:

let
  pname = "wechat";
  version = "4.1.1.4";

  src = pkgs.fetchurl {
    url = "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage";
    hash = "sha256-XxAvFnlljqurGPDgRr+DnuCKbdVvgXBPh02DLHY3Oz8=";
  };

  appimageContents = pkgs.appimageTools.extract {
    inherit pname version src;
    postExtract = ''
      # 修复 libtiff 版本依赖
      [ -f $out/opt/wechat/wechat ] && patchelf --replace-needed libtiff.so.5 libtiff.so $out/opt/wechat/wechat || true
    '';
  };

  wechat-raw = pkgs.appimageTools.wrapAppImage {
    inherit pname version;
    src = appimageContents;
  };

  wechat-sandboxed = pkgs.writeShellScriptBin "wechat" ''
    # 定义并创建沙箱目录
    SANDBOX_DIR="$HOME/.local/share/wechat-sandbox"
    mkdir -p "$SANDBOX_DIR"

    # 针对 XWayland 注入 Xresources DPI 配置，修复 Fcitx5 候选框
    # echo "Xft.dpi: 160" | ${pkgs.xrdb}/bin/xrdb -merge

    # 执行 bubblewrap 沙箱
    # 隔离 HOME 到沙箱目录，保持主目录干净
    # 使用用户提供的缩放和环境配置，并修复 Fcitx5 候选框大小
    exec ${pkgs.bubblewrap}/bin/bwrap \
      --dev-bind / / \
      --bind "$SANDBOX_DIR" "$HOME" \
      --ro-bind-try "$HOME/.Xauthority" "$HOME/.Xauthority" \
      --ro-bind-try /etc/resolv.conf /etc/resolv.conf \
      --setenv HOME "$HOME" \
      --setenv QT_QPA_PLATFORM "wayland;xcb" \
      --setenv QT_IM_MODULE fcitx \
      --setenv GTK_IM_MODULE fcitx \
      --setenv XMODIFIERS "@im=fcitx" \
      ${wechat-raw}/bin/wechat "$@"
  '';
  in
  pkgs.symlinkJoin {
    name = "${pname}-sandboxed-${version}";
    paths = [ wechat-sandboxed wechat-raw ];
    postBuild = ''
      # 覆盖 desktop 文件
      mkdir -p $out/share/applications
      if [ -f ${appimageContents}/wechat.desktop ]; then
        cp ${appimageContents}/wechat.desktop $out/share/applications/
        substituteInPlace $out/share/applications/wechat.desktop \
          --replace-fail "Exec=AppRun %U" "Exec=$out/bin/wechat"
      fi
    '';

  meta = with pkgs.lib; {
    description = "WeChat (Linux) with bubblewrap sandbox (Data isolated in ~/.local/share/wechat-sandbox)";
    homepage = "https://linux.weixin.qq.com/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "wechat";
  };
}
