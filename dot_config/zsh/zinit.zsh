# Manual Install zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# 1. 基础环境 & 主题（同步加载）
zinit depth"1" light-mode for \
    romkatv/powerlevel10k

zinit snippet OMZL::history.zsh

# 2. 补全定义增强（需在 compinit 之前加载）
zinit wait"0a" lucid blockf light-mode for \
    zsh-users/zsh-completions

# 3. 异步延迟加载插件 (Turbo Mode)
zinit wait lucid light-mode for \
    OMZL::git.zsh \
    OMZP::sudo \
    wfxr/forgit

# 4. fzf-tab、自动建议与高亮（ strictly ordered: compinit/fzf-tab -> autosuggestions -> fast-syntax-highlighting）
zinit wait"0b" lucid light-mode for \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
        Aloxaf/fzf-tab \
    atload"!_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
        zdharma-continuum/fast-syntax-highlighting

# If you source zinit.zsh after compinit, add the following snippet after sourcing zinit.zsh
# autoload -Uz _zinit
# (( ${+_comps} )) && _comps[zinit]=_zinit
