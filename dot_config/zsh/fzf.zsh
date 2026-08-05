export THEME=" \
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"


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

zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:*' default-color $'\033[38;2;180;190;254m'
zstyle ':fzf-tab:*' group-title-color $'\033[38;2;203;166;247m'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-pad 4
zstyle ':fzf-tab:*' fzf-flags --no-separator ${(s: :)THEME}
