# vim: set ft=zsh :
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export GPG_TTY=$(tty)
export PLM_RELEASE=$HOME/Workspace/plm-doc/docs/.vuepress/public/release
export MAVEN_USERNAME=admin
export MAVEN_PASSWORD=honeycomb
export WORKSPACE="${HOME}/Workspace"
export PROXYCHAINS_CONF_FILE="${HOME}/.config/proxychains/proxychains.conf"
export PASSWORD_STORE_DIR="$HOME/.password-store"
export N_PREFIX=$HOME/.local/

# https://github.com/sharkdp/bat/issues/523
# export MANPAGER="sh -c 'sed -e s/.\\\\x08//g | bat -l man -p'"
# https://github.com/sharkdp/bat#man
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"
export GOPATH="$WORKSPACE"/go
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export PATH="$HOME/.local/bin:$HOME/.local/scripts:$GOPATH/bin:$HOME/.local/share/JetBrains/Toolbox/apps/intellij-idea-ultimate/bin:$HOME/.config/emacs/bin:$PATH"

# export JAVA_HOME="/usr/lib/jvm/java-11-openjdk/"

export LANG=en_US.UTF-8
export BAT_THEME="Dracula"
export EDITOR=/usr/bin/nvim
export FORGIT_GLO_FORMAT='%C(auto)%h%d %C(magenta)%cn%Creset %s %C(black)%C(bold)%cd%Creset'
# export FORGIT_LOG_GIT_OPTS='--date=format:"%y/%m/%d %H:%M:%S"'

# zsh 忽略历史命令记录，只作用于 history file，当前会话 shell 不生效
export HISTORY_IGNORE="(pwd|ls|cd|ls -a|ll|clear)"
export JDTLS_JVM_ARGS="-javaagent:$HOME/.local/share/nvim/mason/packages/jdtls/lombok.jar"

if [ "$(uname)" = "Darwin" ];then
  if [ "$(uname -m)" = "arm64" ];then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
  export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"

  export PATH="$HOME/.jenv/bin:$HOME/Library/Application Support/JetBrains/Toolbox/scripts:$PATH"

  # jenv 懒加载
  load_jenv() {
    unset -f java jenv mvn
    eval "$(jenv init -)"
  }
  jenv() {
    load_jenv
    jenv $@
  }
  java() {
    load_jenv
    java $@
  }
  mvn() {
    load_jenv
    mvn $@
  }
else
  export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
  # export XSERVERRC="$XDG_CONFIG_HOME"/X11/xserverrc
  # export XINITRC="$XDG_CONFIG_HOME"/X11/xinitrc
  # export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority
  export _JAVA_AWT_WM_NONREPARENTING=1
  export SUDO_PROMPT=" 🔐 Password for $USER: "
  if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ];then
    exec Hyprland
  fi
fi
