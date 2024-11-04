# Manual Install zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

zinit snippet OMZP::vi-mode
zinit snippet OMZL::history.zsh

zinit ice depth=1
zinit light romkatv/powerlevel10k
zinit light Aloxaf/fzf-tab
zinit light supercrabtree/k

# lazy load
zinit wait lucid light-mode for \
    wfxr/forgit \
 atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
 blockf \
    zsh-users/zsh-completions \
 atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
    OMZP::sudo \
    OMZP::safe-paste \
    OMZP::fzf \
    OMZL::git.zsh \
    OMZP::z \

# If you source zinit.zsh after compinit, add the following snippet after sourcing zinit.zsh
# autoload -Uz _zinit
# (( ${+_comps} )) && _comps[zinit]=_zinit
