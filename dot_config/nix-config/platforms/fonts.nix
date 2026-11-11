{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      # 编程与西文字体
      nerd-fonts.jetbrains-mono
      maple-mono.NF-CN-unhinted
      roboto-mongo
      adwaita-fonts

      # 中文字体
      sarasa-gothic
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      lxgw-wenkai
      vista-fonts-chs

      # Emoji
      noto-fonts-color-emoji
    ];

    fontconfig = {
      enable = true;
      antialias = true;
      hinting = {
        enable = true;
        style = "slight";
      };

      # 统一管理通用字体族的系统级回退顺序（无重复配置）
      defaultFonts = {
        sansSerif = [
          "霞鹜975圆体SC"
          "Noto Sans CJK SC"
          "Microsoft YaHei"
          "Source Han Sans SC"
          "DejaVu Sans"
        ];
        serif = [
          "Noto Serif CJK SC"
          "Source Han Serif SC"
          "DejaVu Serif"
        ];
        monospace = [
          "JetBrainsMono Nerd Font Mono"
          "霞鹜975圆体SC"
          "LXGW 975 Yuan SC"
          "LXGW 975 Maru SC"
          "Maple Mono NF CN"
          "Sarasa Mono SC"
          "Noto Sans Mono CJK SC"
          "DejaVu Sans Mono"
        ];
        emoji = [ "Noto Color Emoji" ];
      };

      # 专有字体中文补丁：为 JetBrainsMono 实体字体强绑定中文与 Emoji 回退链
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <!-- JetBrainsMono Nerd Font Mono 中文回退链 -->
          <match target="pattern">
            <test qual="any" name="family">
              <string>JetBrainsMono Nerd Font Mono</string>
            </test>
            <edit name="family" mode="append" binding="strong">
              <string>霞鹜975圆体SC</string>
              <string>LXGW 975 Yuan SC</string>
              <string>LXGW 975 Maru SC</string>
              <string>Noto Color Emoji</string>
            </edit>
          </match>

          <!-- JetBrainsMono Nerd Font 中文回退链 -->
          <match target="pattern">
            <test qual="any" name="family">
              <string>JetBrainsMono Nerd Font</string>
            </test>
            <edit name="family" mode="append" binding="strong">
              <string>霞鹜975圆体SC</string>
              <string>LXGW 975 Yuan SC</string>
              <string>LXGW 975 Maru SC</string>
              <string>Noto Color Emoji</string>
            </edit>
          </match>

          <!-- JetBrains Mono 中文回退链 -->
          <match target="pattern">
            <test qual="any" name="family">
              <string>JetBrains Mono</string>
            </test>
            <edit name="family" mode="append" binding="strong">
              <string>霞鹜975圆体SC</string>
              <string>LXGW 975 Yuan SC</string>
              <string>LXGW 975 Maru SC</string>
              <string>Noto Color Emoji</string>
            </edit>
          </match>
        </fontconfig>
      '';
    };

    # Enable font directory for system-wide access
    fontDir.enable = true;
  };
}
