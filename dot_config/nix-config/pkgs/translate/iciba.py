#!/usr/bin/env python
# -*- coding: utf-8 -*
import base64
import hashlib
import json
import time
from urllib.parse import quote, urlencode

import requests
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from rich.console import Console

from translate import Translate

console = Console()

class ICibaTranslate(Translate):
    url = "http://dict.iciba.com/dictionary/word/query/web"
    sentence_url = (
        "http://ifanyi.iciba.com/index.php"
        "?c=trans&m=fy&client=6&auth_user=key_web_new_fanyi&sign="
    )

    # 类型映射常量
    SYMBOL_TYPES = {"ph_en": "英", "ph_am": "美", "word_symbol": "中"}
    EXCHANGE_TYPES = {
        "word_pl": "复数",
        "word_third": "第三人称单数",
        "word_past": "过去式",
        "word_done": "过去分词",
        "word_ing": "现在分词",
    }

    def source(self):
        return 1

    def signature(self, params):
        code = (
            "/dictionary/word/query/web"
            + params["client"]
            + params["key"]
            + params["timestamp"]
            + params["word"]
            + "7ece94d9f9c202b0d2ec557dg4r9bc"
        )
        md5 = hashlib.md5()
        md5.update(code.encode("utf-8"))
        return md5.hexdigest()

    def encryptor(self, key: str, data: str):
        # 使用 cryptography 统一实现 AES-ECB 加密
        key_bytes = key.encode("utf-8")
        padder = padding.PKCS7(128).padder()
        padded_data = padder.update(data.encode("utf-8")) + padder.finalize()

        cipher = Cipher(algorithms.AES(key_bytes), modes.ECB(), backend=default_backend())
        encryptor = cipher.encryptor()
        encrypted_data = encryptor.update(padded_data) + encryptor.finalize()
        return base64.b64encode(encrypted_data).decode("utf-8")

    def decryptor(self, key: bytes, content: str):
        content_bytes = base64.b64decode(content)
        cipher = Cipher(algorithms.AES(key), modes.ECB(), backend=default_backend())
        decryptor = cipher.decryptor()
        decrypted_data = decryptor.update(content_bytes) + decryptor.finalize()
        decrypted_data = decrypted_data.decode("utf-8")
        decrypted_data = decrypted_data[: decrypted_data.rfind("}") + 1]
        return decrypted_data

    def sentence_signature(self, q: str):
        code = "6key_web_new_fanyi6dVjYLFyzfkFkk" + q.strip()
        md5 = hashlib.md5()
        md5.update(code.encode("utf-8"))
        sign = md5.hexdigest()[:16]
        return self.encryptor("L4fBtD5fLC9FQw22", sign)

    def translate_sentence(self, word, zh=False):
        post_data = {"from": "en", "to": "zh", "q": word}
        if zh:
            post_data = {"from": "zh", "to": "en", "q": word}
        r = requests.post(
            self.sentence_url + self.sentence_signature(word), data=post_data
        )
        response = r.json()
        if 'error_code' in response:
            console.print(f"\n[red]{response}[/red]")
            return response
        response = self.decryptor(b"aahc3TfyfCEmER33", response["content"])
        return json.loads(response)

    def translate_word(self, word):
        query = {
            "client": "6",
            "key": "1000006",
        }
        query["word"] = quote(word)
        query["timestamp"] = str(int(round(time.time() * 1000)))
        query["signature"] = self.signature(query)
        r = requests.get(self.url + "?" + urlencode(query))
        return r.json()

    def pretty_print(self, result):
        if 'error_code' in result:
            console.print(f"\n[red]{result}[/red]")
            return
        if "out" in result:
            console.print(f"\n[red]{result['out']}[/red]")
            return

        message = result.get("message", {})
        baes_info = message.get("baesInfo", {})

        # 1. 解析音标和音频 URL
        if "symbols" in baes_info:
            symbols = baes_info["symbols"][0]
            symbols_output = []
            for skey, label in self.SYMBOL_TYPES.items():
                if symbols.get(skey):
                    symbols_output.append(f"{label} [[red]{symbols[skey]}[/]]")

            if symbols_output:
                console.print("   ".join(symbols_output))

            # 提取音频 URL
            self.mp3_url = (
                symbols.get("ph_en_mp3") or
                symbols.get("ph_am_mp3") or
                symbols.get("ph_tts_mp3")
            )

        # 2. 解析释义
        console.print()
        if "fromSymbolsMean" in baes_info and baes_info["fromSymbolsMean"]:
            for word_group in baes_info["fromSymbolsMean"]:
                for item in word_group.get("word", []):
                    for word_info in item.get("word", []):
                        means = word_info["symbols"][0]["parts"][0]["means"]
                        console.print(f"[blue]{word_info['word_name']}：{'；'.join(means)}[/]")
        elif "symbols" in baes_info:
            symbols = baes_info["symbols"][0]
            for part in symbols.get("parts", []):
                means = "；".join(part.get("means", []))
                console.print(f"[blue]{part.get('part', '')} {means}[/]")

        # 3. 解析词形变化
        if "exchange" in baes_info:
            exchange = baes_info["exchange"]
            exchange_output = []
            for skey, label in self.EXCHANGE_TYPES.items():
                if exchange.get(skey):
                    val = exchange[skey]
                    if isinstance(val, list) and val:
                        val = val[0]
                    exchange_output.append(f"{label}：[[red]{val}[/]]")
            if exchange_output:
                console.print("\n" + "  ".join(exchange_output))

        # 4. 最后播放音频并显示状态
        if self.mp3_url:
            self.play_mp3()
            with console.status("[bold green]Playing..."):
                while not self.play_finished:
                    time.sleep(0.1)


if __name__ == "__main__":
    t = ICibaTranslate()
    t.translate_print("Feb")
