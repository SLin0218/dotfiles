export FZF_DEFAULT_COMMAND="fd --exclude={.git,.idea,.vscode,.sass-cache,node_modules,build}"

export CATPPUCCIN_MOCHA="--color=bg+:#1e1e2e,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
--color=marker:#f5e0dc,fg+:#a6e3a1,prompt:#cba6f7,hl+:#f38ba8"

export CATPPUCCIN_LATTE="--color=bg+:#ccd0da,bg:#eff1f5,spinner:#dc8a78,hl:#d20f39
--color=fg:#4c4f69,header:#d20f39,info:#8839ef,pointer:#dc8a78
--color=marker:#7287fd,fg+:#4c4f69,prompt:#8839ef,hl+:#d20f39
--color=selected-bg:#bcc0cc"

export DRACULA='--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4'

export FZF_DEFAULT_OPTS="
--layout=reverse
--height '100%'
--border
--no-separator
--bind 'alt-y:execute(echo -n {} | xclip -selection clipboard)'
${DRACULA}
"

export FORGIT_BLAME_FZF_OPTS="--preview-window='right:60%'"
export FORGIT_FZF_DEFAULT_OPTS="
--exact
--cycle
--reverse
--no-separator
--height '100%'
--preview-window=right,70%
${DRACULA}
"

# export FZF_TMUX_OPTS="-p50%,50%
# --color=bg+:#1e1e2e,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
# --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
# --color=marker:#f5e0dc,fg+:#a6e3a1,prompt:#cba6f7,hl+:#f38ba8,border:#cba6f7"


export FZF_CTRL_R_OPTS=$FORGIT_FZF_DEFAULT_OPTS
export FZF_CTRL_T_COMMAND="fd --exclude={.git,.idea,.vscode,.sass-cache,node_modules,build}"
export FZF_CTRL_T_OPTS="${FZF_CTRL_R_OPTS}"

zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:*' default-color $'\033[34m'
# zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-pad 4
# --border=none \
zstyle ':fzf-tab:*' fzf-flags --no-separator \
--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
