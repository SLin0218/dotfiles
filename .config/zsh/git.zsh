# git 添加到暂存区
function glin() {
  list=`git status -s | grep -E '^( |MM|UU|AM|RM)' | fzf -m --preview="git diff --color=always {2}" | awk '{sub(" .* ->", "");print $0}'`
  if [ -n "$list" ];then
    echo -e $list | awk 'BEGIN {FS = " "} {print $2}' | xargs git add
  fi
}

function ag() {
  v=`alias | fzf --ansi --no-hscroll --preview='' | awk 'BEGIN {FS = "="} END {print $1}'`
  echo "$v" | tr -d '\n' | xclip -selection clipboard > /dev/null 2>&1
  xdotool key ctrl+shift+o > /dev/null 2>&1
}

function current_branch() {
  git_current_branch
}

function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default}; do
    if command git show-ref -q --verify $ref; then
      echo ${ref:t}
      return
    fi
  done
  echo master
}

function git_develop_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local branch
  for branch in dev devel development; do
    if command git show-ref -q --verify refs/heads/$branch; then
      echo $branch
      return
    fi
  done
  echo develop
}
