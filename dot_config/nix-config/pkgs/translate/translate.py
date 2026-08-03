#!/usr/bin/env python

import json
import os
import platform
import subprocess

import requests
from rich.console import Console

import db

console = Console()


class Translate:
    mp3_url: str = ""
    play_finished: bool = True

    def translate_print(self, word: str):
        if word:
            self.pretty_print(self.translate(word))
        else:
            console.print("输入不能为空")

    def translate(self, word: str):
        import re

        zh_re = re.compile("^[\u4e00-\u9fa5，。]+$")
        r = db.query_by_id(word, self.source())
        if r:
            return r
        # 翻译句子
        if word.count(" ") > 0:
            # 中文
            if zh_re.search(word):
                r = self.translate_sentence(word, True)
            else:
                r = self.translate_sentence(word)
        # 翻译单词
        else:
            if zh_re.search(word) and len(word) > 2:
                r = self.translate_sentence(word, True)
            else:
                r = self.translate_word(word)
        db.create(word, False, self.source(), json.dumps(r))
        return r

    def translate_word(self, word: str):
        pass

    def translate_sentence(self, word: str, zh=False):
        pass

    def pretty_print(self, result):
        pass

    def source(self) -> int:
        return 0

    def play_mp3_task(self):
        prefix_dir = os.path.expanduser("~/.cache/translate/mp3/")
        if not os.path.exists(prefix_dir):
            os.makedirs(prefix_dir)

        path = f"{prefix_dir}{self.mp3_url[self.mp3_url.rfind('/')+1:]}"
        if not os.path.exists(path):
            r = requests.get(self.mp3_url, stream=True)
            if r.status_code == 200:
                with open(path, "wb") as file:
                    for chunk in r.iter_content(chunk_size=1024):
                        if chunk:
                            file.write(chunk)
            else:
                print("无法播放发音")
                return
        try:
            if platform.uname().system == "Linux":
                command_l = ["mpv", "--no-video", path]
            else:
                command_l = ["afplay", path];
            subprocess.run(
                command_l,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception:
            pass
        finally:
            self.play_finished = True

    def play_mp3(self):
        if self.mp3_url:
            import threading

            self.play_finished = False
            threading.Thread(target=self.play_mp3_task, daemon=True).start()
