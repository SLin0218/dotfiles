{
  pkgs,
  lib,
  ...
}:

{
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5 = {
      waylandFrontend = true;
      ignoreUserConfig = false;
      addons = with pkgs; [
        fcitx5-rime
        fcitx5-gtk
        kdePackages.fcitx5-chinese-addons
        kdePackages.fcitx5-configtool
        rime-data
      ];
      settings = {
        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "keyboard-us";
          };
          "Groups/0/Items/0" = {
            Name = "keyboard-us";
            Layout = "";
          };
          "Groups/0/Items/1" = {
            Name = "rime";
            Layout = "";
          };
          GroupOrder."0" = "Default";
        };
        globalOptions = {
          "Hotkey/TriggerKeys" = {
            "0" = "Control+backslash";
          };
          "Hotkey/EnumerateForwardKeys" = { };
          "Hotkey/EnumerateGroupForwardKeys" = { };
          Hotkey = {
            EnumerateWithTriggerKeys = true;
            EnumerateSkipFirst = false;
            ModifierOnlyKeyTimeout = 0;
          };
          "Hotkey/PrevPage"."0" = "Up";
          "Hotkey/NextPage"."0" = "Down";
          Behavior = {
            ActiveByDefault = false;
            resetStateWhenFocusIn = "No";
            ShareInputState = "No";
            PreeditEnabledByDefault = true;
            ShowInputMethodInformation = true;
            showInputMethodInformationWhenFocusIn = false;
            CompactInputMethodInformation = true;
            ShowFirstInputMethodInformation = true;
            DefaultPageSize = 5;
            OverrideXkbOption = false;
            CustomXkbOption = "";
            EnabledAddons = "";
            DisabledAddons = "";
            PreloadInputMethod = true;
            AllowInputMethodForPassword = false;
            ShowPreeditForPassword = false;
            AutoSavePeriod = 30;
          };
        };
      };
    };
  };

  # 显式注入输入法环境变量与 LC_CTYPE。
  # 注意：在支持 text-input-v3 的 Wayland 环境下不要设置 GTK_IM_MODULE=fcitx，
  # 否则 GTK (Emacs PGTK) 会启用 ClientSideInputPanel 由客户端自己绘制候选框，导致无法使用 Fcitx5 的皮肤主题。
  home.sessionVariables = {
    # GTK_IM_MODULE 在 Wayland 下留空/未定义，让 GTK 走原生 text-input-v3，由 Fcitx5 统一绘制主题皮肤
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    GLFW_IM_MODULE = "ibus";
    SDL_IM_MODULE = "fcitx";
    LC_CTYPE = "zh_CN.UTF-8";
  };
}
