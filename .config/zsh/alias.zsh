alias rmm=/bin/rm
alias rm=$HOME/.local/scripts/safe-rm
alias mqtt=$HOME/.local/scripts/mqttx
alias sudo='sudo '
alias prss=proxy_status
alias prstr=proxy_start
alias prstp=proxy_stop

alias ls='eza'
alias l='eza -l'
alias la='eza -a'
alias ll='eza -l'
alias lla='eza -la'
alias lt='eza -T'
alias lg='eza -l --git'
alias lsd='eza -D'
alias lsf='eza -f'
alias lld='eza -lD'
alias llf='eza -lf'

alias cp='rsync -aP'
alias unmount='diskutil unmount'
alias vim='nvim'
alias cat='bat --style=changes'
alias cls='clear'
alias aria2p="aria2p -H http://192.168.0.245 -p 6800 -s 7096d190-3d75-47a3-8278-4b6209880cd8"
alias aria2p="aria2p -H http://127.0.0.1 -p 6800 -s 7096d190-3d75-47a3-8278-4b6209880cd8"
alias fetch="neofetch --ascii ~/.config/ascii/arch"

# git
alias gl="git pull"
alias gp="git push"
alias gcmsg="git commit -m"
alias gss="git status -s"
alias gst="git status"
alias gsw='git switch'
alias gswc='git switch --create'
alias gswm='git switch $(git_main_branch)'
alias gswd='git switch $(git_develop_branch)'
alias gm='git merge'
alias gma='git merge --abort'
alias gbr='git br'
alias gcl='git clone'
alias grv='git remote --verbose'
alias feh='feh -F'

alias neomutt='TERM=xterm-direct proxychains -q neomutt'
alias datetime="date '+%Y-%m-%d %H:%M:%S'"

alias bc='bc -ql'

alias zc='z -c'
alias zl='z -l'
alias ze='z -e'

# # kitty
# alias ssh='kitten ssh'
# alias d="kitten diff"
# alias icat="kitten icat"
