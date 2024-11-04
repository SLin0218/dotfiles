#!/usr/bin/env python3

import os
import subprocess

session_name = "dev"

# 判断会话是否存在, 不为空时则不存在会话
not_session = subprocess.run(
    "tmux has -t dev", shell=True, stderr=subprocess.PIPE
).stderr.decode("utf-8")

window_list = [
    {"name": "WORKSPACE", "dir": "~/Workspace/v1flow-api/"},
    {"name": "WEB", "dir": "~/Workspace/v1flow-h5/"},
    {"name": "HTTP", "dir": "~/http-client/"},
    {"name": "DOC", "dir": "~/Workspace/plm-doc/"},
    {"name": "MY-BOOK", "dir": "~/my-book/"},
    {"name": "OTHER", "dir": "~"},
]


def get_cur_wname():
    return os.popen("tmux lsw -F '#W #F' -t dev | grep '*' | awk '{print $1}'").read()


def select_window(w):
    os.popen(f"tmux select-window -t {session_name}:{w}").read()


def re_order(cur_w_name):
    """
    按 window_list 重排序
    """
    if not cur_w_name:
        cur_w_name = get_cur_wname()
    i = 1
    for w in window_list:
        w_name = w["name"]
        # print(f"tmux lsw -t {session_name} -F '#I #W ' | grep '{w_name}' | awk '{{print $1}}'")
        cur_w_index = (
            os.popen(
                f"tmux lsw -t {session_name} -F '#I #W ' | grep '{w_name}' | awk '{{print $1}}'"
            )
            .read()
            .strip()
        )
        if str(i) != cur_w_index:
            # print(f"tmux swapw -t {i} -s {cur_w_index}")
            os.popen(f"tmux swapw -t {i} -s {cur_w_index}").read()
        i = i + 1
    select_window(cur_w_name)


existent_window_list = os.popen("tmux lsw -F \\#W").read().split("\n")

if not_session:
    os.popen(f"tmux new-session -s {session_name} -d").read()
    first = True
    for w in window_list:
        w_name = w["name"]
        if first:
            os.popen(f"tmux renamew {w_name}").read()
            first = False
        else:
            os.popen(f"tmux new-window -t {session_name} -n {w_name}").read()
        os.popen(f"tmux send-keys -t {session_name} 'cd {w['dir']}' C-m C-l").read()
    # selected first window
    select_window("1")
else:
    cur_w_name = get_cur_wname()
    for w in window_list:
        w_name = w["name"]
        if w_name not in existent_window_list:
            # print(f"tmux new-window -t {session_name} -n {w_name}")
            os.popen(f"tmux new-window -t {session_name} -n {w_name}").read()
            # print(f"tmux send-keys -t {session_name} 'cd {w['dir']}' C-m C-l")
            os.popen(f"tmux send-keys -t {session_name} 'cd {w['dir']}' C-m C-l").read()
    re_order(cur_w_name)
