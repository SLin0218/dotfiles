export FZF_DEFAULT_COMMAND="fd --exclude={.git,.idea,.vscode,.sass-cache,node_modules,build}"

export THEME=" \
--color=bg+:#363A4F,bg:#24273A,spinner:#F4DBD6,hl:#ED8796 \
--color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 \
--color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 \
--color=selected-bg:#494D64 \
--color=border:#6E738D,label:#CAD3F5"

export FZF_DEFAULT_OPTS="
--layout=reverse
--height '100%'
--border
--no-separator
--bind 'alt-y:execute(echo -n {} | xclip -selection clipboard)'
${THEME}
"

export FORGIT_BLAME_FZF_OPTS="--preview-window='right:60%'"
export FORGIT_FZF_DEFAULT_OPTS="
--exact
--cycle
--reverse
--no-separator
--height '100%'
--preview-window=right,70%
${THEME}
"

export FZF_CTRL_R_OPTS=$FORGIT_FZF_DEFAULT_OPTS
export FZF_CTRL_T_COMMAND="fd --exclude={.git,.idea,.vscode,.sass-cache,node_modules,build}"
export FZF_CTRL_T_OPTS="${FZF_CTRL_R_OPTS}"

zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:*' default-color $'\033[34m'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-pad 4
zstyle ':fzf-tab:*' fzf-flags --no-separator \
--color=bg+:#363A4F,bg:#24273A,spinner:#F4DBD6,hl:#ED8796 \
--color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 \
--color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 \
--color=selected-bg:#494D64 \
--color=border:#6E738D,label:#CAD3F5

