{ pkgs, lib, ... }:
{
  programs.wezterm = {
    enable = true;
    settings = {
      color_scheme = "Catppuccin Mocha";
      font_size = 16;
      window_padding = {
        left = 30;
        right = 30;
        top = 15;
        bottom = 0;
      };
      font = lib.generators.mkLuaInline ''wezterm.font_with_fallback{ "JetBrainsMono Nerd Font Mono", "Maple Mono NF CN" }'';
      enable_tab_bar = true;
      use_fancy_tab_bar = false;
      hide_tab_bar_if_only_one_tab = true;
      show_new_tab_button_in_tab_bar = false;
      adjust_window_size_when_changing_font_size = false;
      window_close_confirmation = "AlwaysPrompt";
      window_decorations = "RESIZE | MACOS_FORCE_ENABLE_SHADOW";
      window_background_opacity = 1.0;
      macos_window_background_blur = 70;
      native_macos_fullscreen_mode = false;

      colors = {
        tab_bar = {
          background = "rgba(12%, 12%, 18%, 90%)";
          active_tab = {
            bg_color = "#cba6f7";
            fg_color = "rgba(12%, 12%, 18%, 0%)";
            intensity = "Bold";
          };
          inactive_tab = {
            fg_color = "#cba6f7";
            bg_color = "rgba(12%, 12%, 18%, 90%)";
            intensity = "Normal";
          };
          inactive_tab_hover = {
            fg_color = "#cba6f7";
            bg_color = "rgba(27%, 28%, 35%, 90%)";
            intensity = "Bold";
          };
          new_tab = {
            fg_color = "#808080";
            bg_color = "#1e1e2e";
          };
        };
      };
    };
  };
}
