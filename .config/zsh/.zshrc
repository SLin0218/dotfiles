# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

setopt auto_cd
setopt multios
setopt prompt_subst
setopt hist_ignore_space
setopt hist_ignore_dups

# ssh -N -L 3307:127.0.0.1:3306 -p 22 root@124.71.82.216

[[ ! -f ~/.config/zsh/zinit.zsh ]] || source ~/.config/zsh/zinit.zsh
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
[[ ! -f ~/.config/zsh/browser.zsh ]] || source ~/.config/zsh/browser.zsh
[[ ! -f ~/.config/zsh/proxy.zsh ]] || source ~/.config/zsh/proxy.zsh
[[ ! -f ~/.config/zsh/git.zsh ]] || source ~/.config/zsh/git.zsh
[[ ! -f ~/.config/zsh/user.zsh ]] || source ~/.config/zsh/user.zsh
[[ ! -f ~/.config/zsh/fzf.zsh ]] || source ~/.config/zsh/fzf.zsh
[[ ! -f ~/.config/zsh/alias.zsh ]] || source ~/.config/zsh/alias.zsh

# 要放在 autoload -U compinit 之前才生效
fpath+=("$HOME/.zfunc")
autoload -Uz compinit && compinit
