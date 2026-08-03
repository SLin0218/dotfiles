{ ... }: {
  programs.hyprlock = {
    enable = true;
    settings = {
      font = "Roboto Mono";
      general = {
        disable_loading = true;
        hide_cursor = true;
        no_fade_in = false;
      };
      background = {
        monitor = "";
        path = "screenshot";
        blur_passes = 2;
        color = "$base";
      };
      animations = {
        enabled = true;
        bezier = "linear, 1, 1, 0, 0";
        animation = [
          "fade, 1, 5, linear"
          "inputField, 1, 1.8, linear"
        ];
      };
      label = [
        {
          monitor = "";
          text = "$TIME";
          color = "$text";
          font_size = "200";
          font_family = "$font";
          position = "0, -300";
          halign = "center";
          valign = "top";
        }
        {
          monitor = "";
          text = "cmd[update:43200000] date '+%A, %B %d'";
          color = "$text";
          font_size = 50;
          font_family = "$font";
          position = "0, -220";
          halign = "center";
          valign = "top";
        }
      ];
      image = {
        monitor = "";
        path = "$HOME/.face";
        size = 150;
        border_color = "$accent";
        border_size = 0;
        position = "0, 300";
        halign = "center";
        valign = "right";
      };
      input-field = {
        monitor = "";
        border_size = 0;
        size = "300, 55";
        outline_thickness = 4;
        dots_size = 0.2;
        dots_spacing = 0.2;
        dots_center = true;
        outer_color = "$accent";
        inner_color = "$surface0";
        font_color = "$text";
        fade_on_empty = false;
        placeholder_text = "<span foreground=\"##$textAlpha\"><i>󰌾 Logged in as </i><span foreground=\"##$accentAlpha\">$USER</span></span>";
        hide_input = false;
        check_color = "$accent";
        fail_color = "$red";
        fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
        capslock_color = "$yellow";
        position = "0, 200";
        halign = "center";
        valign = "right";
      };
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        # {
        #   timeout = 150; # 2 mins
        #   on-timeout = "brightnessctl -s set 10";
        #   on-resume = "brightnessctl -r";
        # }
        # {
        #   timeout = 150; # 2 mins
        #   on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
        #   on-resume = "brightnessctl -rd rgb:kbd_backlight";
        # }
        # {
        #   timeout = 600; # 10 mins
        #   on-timeout = "loginctl lock-session";
        # }
        # {
        #   timeout = 630; # 10.5 mins
        #   on-timeout = "hyprctl dispatch dpms off";
        #   on-resume = "hyprctl dispatch dpms on";
        # }
        # {
        #   timeout = 1800; # 30 mins
        #   on-timeout = "systemctl suspend";
        # }
      ];
    };
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      wallpaper = [
        {
          monitor = "";
          path = "~/Pictures/wallpaper/";
          timeout = 600;
          fit_mode = "cover";
        }
      ];
    };
  };

}
