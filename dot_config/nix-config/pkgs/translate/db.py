#!/usr/bin/env python
import hashlib
import json
import os
import sqlite3
import time
from pathlib import Path

prefix_dir = f"{os.getenv('HOME')}/.cache/translate/"
db_file = prefix_dir + "/translate.db"

Path(prefix_dir).mkdir(parents=True, exist_ok=True)

def query_by_id(word: str, source: int):
    conn = sqlite3.connect(db_file)
    c = conn.cursor()
    cursor = c.execute(
        'SELECT count(*) FROM sqlite_master WHERE type = "table" AND name = "translate"'
    )
    if not cursor.fetchone()[0]:
        c.execute(
            "CREATE TABLE translate(ID CHAR(32) PRIMARY KEY NOT NULL, WORD text, SOURCE TINYINT, SENTENCE BOOLEAN, CREATE_TIME int, RESULT text);"
        )

    c = conn.cursor()
    m = hashlib.md5()
    m.update(f"{word}{source}".encode("utf-8"))
    cursor = c.execute(f'SELECT RESULT from translate WHERE ID = "{m.hexdigest()}"')
    db_data = cursor.fetchone()

    if db_data:
        return json.loads(db_data[0])


def create(word: str, sentence: bool, source: int, result: str):
    conn = sqlite3.connect(db_file)
    c = conn.cursor()
    m = hashlib.md5()
    m.update(f"{word}{source}".encode("utf-8"))

    cursor = c.execute(
        f"INSERT INTO translate (ID, WORD, SOURCE, SENTENCE, CREATE_TIME, RESULT) VALUES (?, ?, ?, ?, ?, ?);",
        (
            m.hexdigest(),
            word,
            source,
            sentence,
            int(time.time()),
            result,
        ),
    )
    conn.commit()
    cursor.close()
