{ inputs, pkgs, lib, ...}:
let
  toggleApp = pkgs.writeShellScript "toggle-app" ''
    HYPRCTL="${pkgs.hyprland}/bin/hyprctl"
    GREP="${pkgs.gnugrep}/bin/grep"
    APP_CLASS=$1
    LAUNCH_CMD=$2

    if $HYPRCTL clients | $GREP -q "class: $APP_CLASS"; then
        $HYPRCTL dispatch "hl.dsp.focus({ window = 'class:$APP_CLASS' })"
    else
        $HYPRCTL dispatch "hl.dsp.exec_cmd('$LAUNCH_CMD')"
    fi
  '';

  toLua = x: lib.generators.mkLuaInline (lib.generators.toLua {} x);
in
{

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    # set the flake package
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    settings = {

      mod._var = "SUPER";

      monitor = [
        {
          output = "eDP-1";
          mode = "2560x1600@60";
          position = "0x0";
          scale = "1.6";
        }
        {
          output = "HDMI-A-1";
          mode = "preferred";
          position = "0x-1440";
          scale = "auto";
        }
      ];

      config = [
        {
          input = {
            kb_layout  = "us";
            touchpad = {
              natural_scroll = true;
              scroll_factor = 0.5;
              clickfinger_behavior = true;
            };
            natural_scroll = false;
          };
        }
        {
          general = {
            gaps_in = 5;
            gaps_out = 20;
            border_size = 2;
            col = {
              active_border = (lib.generators.mkLuaInline "colors.lavender");
              inactive_border = "rgba(595959aa)";
            };
            resize_on_border = false;
            allow_tearing = false;
            layout = "dwindle";
          };
        }
        {
          decoration = {
             rounding = 5;
             rounding_power = 2;
             active_opacity = 1.0;
             inactive_opacity = 1.0;
             shadow = {
                 enabled = true;
                 range = 4;
                 render_power = 3;
                 color = "rgba(1a1a1aee)";
             };
             blur = {
                 enabled = true;
                 size = 3;
                 passes = 1;
                 vibrancy = 0.1696;
             };
          };
        }
        {
          dwindle = {
            preserve_split = true;
          };
        }
        {
          master = {
            new_status = "master";
          };
        }
        {
          misc = {
            force_default_wallpaper = -1;
            disable_hyprland_logo = false;
          };
        }
        {
          xwayland = {
            force_zero_scaling = true;
          };
        }
      ];

      gesture = {
        fingers = 3;
        direction = "horizontal";
        action = "workspace";
      };

      curve = [
        { _args = [ "easeOutQuint"   (toLua { type = "bezier"; points = [ [0.23      1] [0.32     1] ]; }) ]; }
        { _args = [ "easeInOutCubic" (toLua { type = "bezier"; points = [ [0.65   0.05] [0.36     1] ]; }) ]; }
        { _args = [ "linear"         (toLua { type = "bezier"; points = [ [0         0] [1        1] ]; }) ]; }
        { _args = [ "almostLinear"   (toLua { type = "bezier"; points = [ [0.5     0.5] [0.75     1] ]; }) ]; }
        { _args = [ "quick"          (toLua { type = "bezier"; points = [ [0.15      0] [0.1      1] ]; }) ]; }
        { _args = [ "macEaseOut"     (toLua { type = "bezier"; points = [ [0.15      0] [0        1] ]; }) ]; }
        { _args = [ "macEaseIn"      (toLua { type = "bezier"; points = [ [0.42      0] [1        1] ]; }) ]; }
        { _args = [ "macScale"       (toLua { type = "bezier"; points = [ [0.175 0.885] [0.32 1.275] ]; }) ]; }
      ];

      animation = [
        { _args = [ (toLua { leaf =        "global"; enabled = true; speed =   10; bezier =        "default"; })]; }
        { _args = [ (toLua { leaf =        "border"; enabled = true; speed = 5.39; bezier =   "easeOutQuint"; })]; }
        { _args = [ (toLua { leaf =       "windows"; enabled = true; speed = 4.79; bezier =     "macEaseOut"; })]; }
        { _args = [ (toLua { leaf =     "windowsIn"; enabled = true; speed = 4.79; bezier =     "macEaseOut"; style = "popin 50%"; })]; }
        { _args = [ (toLua { leaf =    "windowsOut"; enabled = true; speed =  2.5; bezier =     "macEaseOut"; style = "popin 30%"; })]; }
        { _args = [ (toLua { leaf =        "fadeIn"; enabled = true; speed = 1.73; bezier =   "almostLinear"; })]; }
        { _args = [ (toLua { leaf =       "fadeOut"; enabled = true; speed = 1.46; bezier =   "almostLinear"; })]; }
        { _args = [ (toLua { leaf =          "fade"; enabled = true; speed = 3.03; bezier =          "quick"; })]; }
        { _args = [ (toLua { leaf =        "layers"; enabled = true; speed = 3.81; bezier =   "easeOutQuint"; })]; }
        { _args = [ (toLua { leaf =      "layersIn"; enabled = true; speed =    4; bezier =   "easeOutQuint"; style = "fade"; })]; }
        { _args = [ (toLua { leaf =     "layersOut"; enabled = true; speed =  1.5; bezier =         "linear"; style = "fade"; })]; }
        { _args = [ (toLua { leaf =  "fadeLayersIn"; enabled = true; speed = 1.79; bezier =   "almostLinear"; })]; }
        { _args = [ (toLua { leaf = "fadeLayersOut"; enabled = true; speed = 1.39; bezier =   "almostLinear"; })]; }
        { _args = [ (toLua { leaf =    "workspaces"; enabled = true; speed = 1.94; bezier =   "almostLinear"; style = "slide"; })]; }
        { _args = [ (toLua { leaf =  "workspacesIn"; enabled = true; speed = 1.21; bezier =   "almostLinear"; style = "slide"; })]; }
        { _args = [ (toLua { leaf = "workspacesOut"; enabled = true; speed = 1.94; bezier =   "almostLinear"; style = "slide"; })]; }
        { _args = [ (toLua { leaf =    "zoomFactor"; enabled = true; speed =    7; bezier =          "quick"; })]; }
      ];


      bind = [
        { _args = [ "SUPER + I" (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${toggleApp} kitty kitty\")") ]; }
        { _args = [ "SUPER + G" (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${toggleApp} brave-browser brave\")") ]; }
        { _args = [ "SUPER + U" (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${toggleApp} wechat wechat\")") ]; }
        { _args = [ "SUPER + Y" (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${toggleApp} qqmusic qqmusic\")") ]; }
        { _args = [ "SUPER + M" (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${toggleApp} emacs emacs\")") ]; }

        { _args = [ "SUPER + Q" (lib.generators.mkLuaInline "hl.dsp.window.close({ window = 'activewindow' })") ]; }
        { _args = [ "SUPER + K" (lib.generators.mkLuaInline "hl.dsp.focus({ direction = 'u' })") ]; }
        { _args = [ "SUPER + J" (lib.generators.mkLuaInline "hl.dsp.focus({ direction = 'd' })") ]; }
        { _args = [ "SUPER + H" (lib.generators.mkLuaInline "hl.dsp.focus({ direction = 'l' })") ]; }
        { _args = [ "SUPER + L" (lib.generators.mkLuaInline "hl.dsp.focus({ direction = 'r' })") ]; }

        { _args = [ "SUPER + SHIFT + K" (lib.generators.mkLuaInline "hl.dsp.window.move({ x =   0, y = -50, relative = true, window = 'activewindow' })") ]; }
        { _args = [ "SUPER + SHIFT + J" (lib.generators.mkLuaInline "hl.dsp.window.move({ x =   0, y =  50, relative = true, window = 'activewindow' })") ]; }
        { _args = [ "SUPER + SHIFT + H" (lib.generators.mkLuaInline "hl.dsp.window.move({ x = -50, y =   0, relative = true, window = 'activewindow' })") ]; }
        { _args = [ "SUPER + SHIFT + L" (lib.generators.mkLuaInline "hl.dsp.window.move({ x =  50, y =   0, relative = true, window = 'activewindow' })") ]; }

        { _args = [ "SHIFT + ALT + K" (lib.generators.mkLuaInline "hl.dsp.window.resize({ x =   0, y = -50, relative = true, window = 'activewindow' })") ]; }
        { _args = [ "SHIFT + ALT + J" (lib.generators.mkLuaInline "hl.dsp.window.resize({ x =   0, y =  50, relative = true, window = 'activewindow' })") ]; }
        { _args = [ "SHIFT + ALT + H" (lib.generators.mkLuaInline "hl.dsp.window.resize({ x = -50, y =   0, relative = true, window = 'activewindow' })") ]; }
        { _args = [ "SHIFT + ALT + L" (lib.generators.mkLuaInline "hl.dsp.window.resize({ x =  50, y =   0, relative = true, window = 'activewindow' })") ]; }


        { _args = [ "SUPER + F" (lib.generators.mkLuaInline "hl.dsp.window.fullscreen({ window = 'activewindow', action = 'toggle' })") ]; }
        { _args = [ "SUPER + SPACE" (lib.generators.mkLuaInline "hl.dsp.exec_cmd('ags request launcher app')") ]; }
        { _args = [ "CTRL + SHIFT + V" (lib.generators.mkLuaInline "hl.dsp.exec_cmd('ags request launcher cliphist')") ]; }

        { _args = [ "SUPER + SHIFT + A" (lib.generators.mkLuaInline "hl.dsp.exec_cmd('ags request launcher screenshot')") ]; }
        { _args = [ "SUPER + L" (lib.generators.mkLuaInline "hl.dsp.exec_cmd('hyprlock')") ]; }
        { _args = [ "SUPER + SHIFT + Q" (lib.generators.mkLuaInline "hl.dsp.exit()") ]; }

        { _args = [ "SUPER + 1" (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = '1' })") ]; }
        { _args = [ "SUPER + 2" (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = '2' })") ]; }
        { _args = [ "SUPER + 3" (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = '3' })") ]; }
        { _args = [ "SUPER + 4" (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = '4' })") ]; }
        { _args = [ "SUPER + 5" (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = '5' })") ]; }
        { _args = [ "SUPER + 6" (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = '6' })") ]; }
        { _args = [ "SUPER + 7" (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = '7' })") ]; }
        { _args = [ "SUPER + 8" (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = '8' })") ]; }
        { _args = [ "SUPER + 9" (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = '9' })") ]; }
        { _args = [ "SUPER + 0" (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = '10' })") ]; }

        { _args = [ "SUPER + SHIFT + 1" (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = '1', window = 'activewindow' })") ]; }
        { _args = [ "SUPER + SHIFT + 2" (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = '2', window = 'activewindow' })") ]; }
        { _args = [ "SUPER + SHIFT + 3" (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = '3', window = 'activewindow' })") ]; }
        { _args = [ "SUPER + SHIFT + 4" (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = '4', window = 'activewindow' })") ]; }
        { _args = [ "SUPER + SHIFT + 5" (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = '5', window = 'activewindow' })") ]; }
        { _args = [ "SUPER + SHIFT + 6" (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = '6', window = 'activewindow' })") ]; }
        { _args = [ "SUPER + SHIFT + 7" (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = '7', window = 'activewindow' })") ]; }
        { _args = [ "SUPER + SHIFT + 8" (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = '8', window = 'activewindow' })") ]; }
        { _args = [ "SUPER + SHIFT + 9" (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = '9', window = 'activewindow' })") ]; }
        { _args = [ "SUPER + SHIFT + 0" (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = '10', window = 'activewindow' })") ]; }

        { _args = [
            "XF86AudioRaiseVolume"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd('wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ && ags request volume')")
            { repeating = true; locked = true; }
          ];
        }
        {
          _args = [
            "XF86AudioLowerVolume"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd('wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && ags request volume')")
            { repeating = true; locked = true; }
          ];
        }
        {
          _args = [
            "XF86AudioMute"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd('wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && ags request volume')")
            { repeating = true; locked = true; }
          ];
        }
        {
          _args = [
            "XF86AudioMicMute"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd('wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggl && ags request volume')")
            { repeating = true; locked = true; }
          ];
        }
        {
          _args = [
            "XF86MonBrightnessUp"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd('brightnessctl s 5%+ && ags request brightness')")
            { repeating = true; locked = true; }
          ];
        }
        {
          _args = [
            "XF86MonBrightnessDown"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd('brightnessctl s 5%- && ags request brightness')")
            { repeating = true; locked = true; }
          ];
        }

        # LMB -> 272
        # RMB -> 273
        # MMB -> 274
        { _args = [ "ALT + mouse:272" (lib.generators.mkLuaInline "hl.dsp.window.drag()") { mouse = true; } ]; }

      ];

      on = {
        _args = [
          "hyprland.start"
          (lib.generators.mkLuaInline ''
            function()
              hl.exec_cmd("echo 'Xft.dpi: 160' | ${pkgs.xrdb}/bin/xrdb -merge")
              hl.exec_cmd("keyd-application-mapper -d")
              hl.exec_cmd("ags run")
              hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
              hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
            end
          '')
        ];
      };

      workspace_rule = [
        {
          workspace = 1;
          monitor = "HDMI-A-1";
          default = true;
        }
        {
          workspace = 2;
          monitor = "HDMI-A-1";
          default = true;
        }
        {
          workspace = 3;
          monitor = "HDMI-A-1";
          default = true;
        }
        {
          workspace = 4;
          monitor = "HDMI-A-1";
          default = true;
        }
        {
          workspace = 5;
          monitor = "HDMI-A-1";
          default = true;
        }
        {
          workspace = 6;
          monitor = "eDP-1";
          default = true;
        }
        {
          workspace = 7;
          monitor = "eDP-1";
          default = true;
        }
        {
          workspace = 8;
          monitor = "eDP-1";
          default = true;
        }
        {
          workspace = 9;
          monitor = "eDP-1";
          default = true;
        }
        {
          workspace = 10;
          monitor = "eDP-1";
          default = true;
        }
      ];

      window_rule = [
        {
          name = "Xwayland Float no blur";
          match = {
            xwayland = true;
            float = true;
          };
          no_blur = true;
          border_size = 0;
        }
        {
          name = "Wehchat Photos Float";
          match = {
            xwayland = true;
            title = "Photos and Videos";
          };
          float = true;
        }
        {
          name = "Nautilus Float";
          match = {
            class = "org.gnome.Nautilus";
          };
          float = true;
        }
      ];

      layer_rule = [
        {
          # 通知中心 (Notification)
          name = "notification";
          match = {
            namespace = "notification";
          };
          blur = true;
          ignore_alpha = 0.5;
          animation = "slide right";
        }
        {
          name = "bar";
          match = {
            namespace = "bar";
          };
          blur_popups = true;
          ignore_alpha = 0.5;
          blur = true;
        }
      ];

    };
  };
}
