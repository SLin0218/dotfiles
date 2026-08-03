{ ... }:
{

  services.mpd = {
    enable = true;
    musicDirectory = "/home/lin/Music/";
    extraConfig = ''
      audio_output {
        type "pulse"
        name "PulseAudio"
      }
    '';
  };

  programs.ncmpcpp = {
    enable = true;
    bindings = [
      {
        key = "9";
        command = "show_help";
      }
      {
        key = "D";
        command = "delete_playlist_items";
      }
      {
        key = "D";
        command = "delete_browser_items";
      }
      {
        key = "D";
        command = "delete_stored_playlist";
      }
      {
        key = "k";
        command = "scroll_up";
      }
      {
        key = "K";
        command = [
          "select_item"
          "scroll_up"
        ];
      }
      {
        key = "j";
        command = "scroll_down";
      }
      {
        key = "J";
        command = [
          "select_item"
          "scroll_down"
        ];
      }
      {
        key = "n";
        command = "next_found_item";
      }
      {
        key = "N";
        command = "previous_found_item";
      }
    ];

    settings = {
      # ### Behaviour ###
      # execute_on_song_change = "bash ~/.config/ncmpcpp/mpd-notification"
      message_delay_time = 1;
      playlist_disable_highlight_delay = 2;
      autocenter_mode = "yes";
      centered_cursor = "yes";
      ignore_leading_the = "yes";
      allow_for_physical_item_deletion = "no";

      ### Appearance ###
      colors_enabled = "yes";
      playlist_display_mode = "columns";
      # user_interface = "classic";
      user_interface = "alternative";
      volume_color = "white";

      # Window #
      song_window_title_format = "Music";
      # song_window_title_format = "{%a - }{%t}|{%f}"
      statusbar_visibility = "no";
      header_visibility = "no";
      titles_visibility = "no";

      # Progress bar #
      progressbar_look = "▂▂▂";
      progressbar_color = "black";
      progressbar_elapsed_color = "yellow";

      # Alternative UI
      alternative_ui_separator_color = "black";
      alternative_header_first_line_format = "$b$5«$/b$5« $b$8{%t}|{%f}$/b $5»$b$5»$/b";
      alternative_header_second_line_format = "{$b{$2%a$9}{ - $7%b$9}{ ($2%y$9)}}|{%D}";
      # Song list #
      song_status_format = "$7%t";
      song_list_format = "  %t $R%a %l  ";
      song_columns_list_format = "(53)[white]{tr} (45)[blue]{a}";

      song_library_format = "{{%a - %t} (%b)}|{%f}";

      # Colors #
      main_window_color = "blue";
      current_item_prefix = "$(blue)$r";
      current_item_suffix = "$/r$(end)";

      current_item_inactive_column_prefix = "red";
      current_item_inactive_column_suffix = "red";

      color1 = "white";
      color2 = "red";
    };
  };

  programs.cava = {
    enable = true;
  };

}
