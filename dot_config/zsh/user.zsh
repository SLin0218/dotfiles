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
