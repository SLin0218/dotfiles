{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font Mono";
      size = if pkgs.stdenv.isDarwin then 16.0 else 12.0;
    };

    shellIntegration = {
      enableZshIntegration = true;
      mode = "no-cursor";
    };

    settings = {

      cursor_shape = "underline";
      cursor_trail = 1;
      symbol_map = "U+4E00-U+9FFF,U+3400-U+4DBF,U+20000–U+323AF Maple Mono NF CN";

      allow_remote_control = true;
      listen_on = "unix:/tmp/kitty";

      enabled_layouts = "Splits,Stack";

      startup_session = "~/.config/kitty/default.s";

      window_padding_width = 15.0;
      window_margin_width = 0;
      update_check_interval = 0;

      tab_bar_margin_height = "10 0";
      tab_bar_edge = "top";
      tab_bar_style = "custom";
    };

    keybindings = {
      "alt+v" = "paste_from_clipboard";
      "kitty_mod+]" = "next_tab";
      "kitty_mod+[" = "previous_tab";
      "kitty_mod+h" = "previous_window";
      "kitty_mod+l" = "next_window";
      "kitty_mod+o" = "show_scrollback";
      "kitty_mod+n" = "set_tab_title";
      "kitty_mod+'" = "launch --cwd=current --location vsplit";
      "kitty_mod+5" = "launch --cwd=current --location hsplit";
      "kitty_mod+z" = "next_layout";
      "kitty_mod+u" = "scroll_page_up";
      "kitty_mod+d" = "scroll_page_down";

      "kitty_mod+m" = "create_marker";
      "ctrl+m" = "remove_marker";
    };

    extraConfig = ''
      mark1_foreground red
      mark1_background #282a36
      mark2_foreground green
      mark2_background #282a36

      # kitty-scrollback.nvim Kitten alias
      action_alias kitty_scrollback_nvim kitten '~/.local/share/nvim/lazy/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py'
      # Browse scrollback buffer in nvim
      map kitty_mod+enter kitty_scrollback_nvim
      # Browse output of the last shell command in nvim
      map kitty_mod+g kitty_scrollback_nvim --config ksb_builtin_last_cmd_output
      # Show clicked command output in nvim
      mouse_map ctrl+shift+right press ungrabbed combine : mouse_select_command_output : kitty_scrollback_nvim --config ksb_builtin_last_visited_cmd_output
    '';

  };

  xdg.configFile."kitty/tab_bar.py".source = ../../config/kitty/tab_bar.py;
  xdg.configFile."kitty/default.s".source = ../../config/kitty/default.s;

}
