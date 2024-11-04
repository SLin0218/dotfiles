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

  if [[ $(echo $filtered | wc -l) == 1 ]]; then
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
      path=(${path:#$VIRTUAL_ENV})
    fi
  else
    if [[ -d ./bin && -e ./pyvenv.cfg ]]; then
      source bin/activate
      export PATH="$PATH:$VIRTUAL_ENV"
    fi
  fi
}


tmuxa () {
  ~/.config/alacritty/tmux-dev.py && tmux a
}

autoload -U add-zsh-hook
add-zsh-hook chpwd pyvenv_cd
[[ $PWD != ~ ]] && pyvenv_cd
