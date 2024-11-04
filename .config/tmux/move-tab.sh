#!/bin/bash

lock="/tmp/move-tab"
if [[ ! -e "$lock" ]];
then
  touch $lock
  if [[ "$1" == "-1" ]]; then
    tmux swap-window -t "$1"
    tmux previous-window
  elif [[ "$1" == "+1" ]]; then
    tmux swap-window -t "$1"
    tmux next-window
  fi
  rm -f $lock
fi
