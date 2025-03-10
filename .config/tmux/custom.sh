#/bin/bash

TMUX_CONF_FILE=$HOME/.config/tmux/tmux.conf.local

sed -i '' 's/^#set -g status-position top/set -g status-position top/' $TMUX_CONF_FILE

sed -i '' 's/^tmux_conf_theme_window_status_current_bg="$tmux_conf_theme_colour_4"/tmux_conf_theme_window_status_current_bg="$tmux_conf_theme_colour_3"/' $TMUX_CONF_FILE

sed -i '' 's/^tmux_conf_theme_window_status_current_format=".*"/tmux_conf_theme_window_status_current_format="#[fg=$tmux_conf_theme_colour_7,bg=$tmux_conf_theme_colour_3] #I #{hostname_ssh} #(printf "%%-15s" #W)"/' $TMUX_CONF_FILE

sed -i '' 's/^tmux_conf_theme_window_status_format=".*"/tmux_conf_theme_window_status_format="#[fg=$tmux_conf_theme_colour_7,bg=$tmux_conf_theme_colour_2] #I #{hostname_ssh} #(printf "%%-10s" #W)"/' $TMUX_CONF_FILE

sed -i '' 's/^tmux_conf_theme_status_left=".*"/tmux_conf_theme_status_left="#{?pane_in_mode,#[bg=$tmux_conf_theme_colour_11]  NORMAL,#[bg=$tmux_conf_theme_colour_11]  } "/' $TMUX_CONF_FILE

sed -i '' 's/^tmux_conf_theme_status_right=".*"/tmux_conf_theme_status_right="#{prefix} #[fg=$tmux_conf_theme_colour_1,bg=$tmux_conf_theme_colour_13]  #S "/' $TMUX_CONF_FILE

new_colors=(
    ["1"]="#282a36"
    ["2"]="#44475a"
    ["3"]="#bd93f9"
    ["4"]="#8be9fd"
    ["5"]="#f1fa8c"
    ["6"]="#282a36"
    ["7"]="#f8f8f2"
    ["8"]="#282a36"
    ["9"]="#f1fa8c"
    ["10"]="#ff79c6"
    ["11"]="#50fa7b"
    ["12"]="#ffb86c"
    ["13"]="#f8f8f2"
    ["14"]="#282a36"
    ["15"]="#282a36"
    ["16"]="#ff5555"
    ["17"]="#f8f8f2"
)

for index in "${!new_colors[@]}"; do
    sed -i.bak "s/^tmux_conf_theme_colour_${index}=\"#[0-9a-fA-F]\{6\}\"/tmux_conf_theme_colour_${index}=\"${new_colors[$index]}\"/" "$TMUX_CONF_FILE"
done

# set -g @plugin 'tmux-plugins/tmux-copycat'
# set -g @plugin 'tmux-plugins/tmux-resurrect'
# set -g @plugin 'schasse/tmux-jump'
# set -g @continuum-restore 'on'
# set -g @jump-key 's'
# set -g @plugin 'tmux-plugins/tmux-prefix-highlight'
# set -g @prefix_highlight_show_copy_mode 'on'
# set -g @prefix_highlight_copy_mode_attr 'fg=blue'

# set -Fg 'status-format[1]' ''
# set -g status 2
# set -sg repeat-time 300
