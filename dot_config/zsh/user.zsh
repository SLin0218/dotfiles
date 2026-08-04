# find wechat file list, order by change date

fwc() {
  fd . -p /mnt/wechat/ -t=f -c never --exec ls -l --time-style=+%s {} \
    | sort -nr -k6 | awk '{for (i=7; i<=NF; i++) printf "%s", $i; print""}' \
    | fzf --bind="enter:become(echo -n {+} | xclip -selection clipboard -i)"
}

# find work wechat file list, order by change date
fww() {
  fd . -p /mnt/work_wechat/ -t=f -c never -E 'Temp' --exec ls -l --time-style=+%s {} \
    | sort -nr -k6 \
    | awk '{for (i=7; i<=NF; i++) printf "%s", $i; print""}' \
    | fzf --bind="enter:become(echo -n {+} | xclip -selection clipboard -i)"
}

cf () {
  fd | fzf --bind="enter:become(echo -n 'cp {+}')"
}

# honeycomb web login token
login() {
  # access_token=$(node ~/http-client/login.js | jq '.access_token')
  # export access_token="Authorization: ${access_token:1:-1}"
  token=$(http ':8089/login' --raw '{"username": "admin", "password": "admin123"}' | jq -r '.token')
  export auth="Authorization: Bearer $token"
}


zz() {
  r=$(z -l $1 | grep -v '^common:' | awk '{print $2}')
  filtered=''
  echo $r | while IFS= read -r line; do
    if [[ $(basename "$line") == *$1* ]]; then
      if [[ $filtered != '' ]]; then
        filtered+="\n"
      fi
      filtered+="${line//#$HOME/~}"
    fi
  done

  if [[ $(echo $filtered | wc -l | awk '{print $1}') == 1 ]]; then
    cd ${filtered//#\~/$HOME}
  else
    dir=$(echo $filtered | fzf)
    if [[ -n $dir ]];then
      cd ${dir//#\~/$HOME}
    fi
  fi
}

function pyvenv_cd {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    if [[ $PWD != "${VIRTUAL_ENV}"* ]]; then
      deactivate
    fi
  else
    if [[ -d .venv ]]; then
      source .venv/bin/activate
      #export PATH="$PATH:$VIRTUAL_ENV/.venv/bin"
    fi
  fi
}

wpath() {
  local win_path
  win_path=$(powershell.exe -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; \$p = Get-Clipboard; if (\$p) { \$p.ToString().Trim('\"').Replace('\', '/') }" 2>/dev/null | tr -d '\r')
  if [ -n "$win_path" ]; then
     wslpath -u "$win_path"
  fi
}

tmuxa () {
  ~/.config/alacritty/tmux-dev.py && tmux a
}

autoload -U add-zsh-hook
add-zsh-hook chpwd pyvenv_cd
[[ $PWD != ~ ]] && pyvenv_cd

export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
export GPG_TTY=$(tty)
if [[ -n "$TTY" ]]; then
    export GPG_TTY="$TTY"
    # 自动通知 gpg-agent 更新当前终端 TTY，解决 pinentry 弹窗失败问题
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
fi
