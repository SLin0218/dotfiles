#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
sync_from_qingfeng.py - 官方小鹤音形_清风便携版 -> Rime 码表无损转换同步工具

功能说明：
1. 完整解析官方清风便携版 (WindInput) 核心双数组 Trie 二进制词库 (00_xh.wdat，DAT v6 格式)；
2. 严格按照原词库自然出现顺序 (order 字段) 无损还原首选字词为 Rime 标准词库；
3. 解析并分类提取分类词库 (11_fl -> secondary, off-table, whimsicality)；
4. 解析一简次选 (21_yj)、二简次选 (22_ej)、全码词 (51_qmc)、全码字 (53_qmz)；
5. 解析生僻字 (52_upz) 与 ok 两分/三分拆字拼字词库 (61_ok)；
6. 清洗并规范化快符 (81_kf) 与符号字根 (41_fh)；
7. 提取二简词提示词典 (ejc.wdict.yaml -> opencc/short_hints.txt)；
8. 重新生成符合最新官方规范的 xhup.dict.yaml，支持熟手/常规/初学模式按需开关。
"""

import os
import sys
import re
import glob
import struct
from pathlib import Path


def clean_cc_expr(text: str) -> str:
    """清洗清风输入法专有的 $CC(...) 命令表达式为标准文本"""
    if "$CC" not in text:
        return text

    # ime.pair("“", "”") -> 成对符号
    m_pair = re.search(r'ime\.pair\("([^"]+)",\s*"([^"]+)"\)', text)
    if m_pair:
        return m_pair.group(1) + m_pair.group(2)

    # type("文字") -> 真实打出的文字
    m_type = re.search(r'type\("([^"]+)"\)', text)
    if m_type:
        return m_type.group(1)

    # $CC("文字", ...) -> 降级匹配第一参数
    m_label = re.search(r'\$CC\("([^"]+)"', text)
    if m_label:
        label = m_label.group(1)
        # 去掉诸如 横_一 这种展示性下划线前缀，取实际字
        if "_" in label and len(label.split("_")[-1]) == 1:
            return label.split("_")[-1]
        return label

    return text


def parse_wdat(path: Path) -> list:
    """
    解析 WindInput WDAT v6 二进制词典格式并按原始 order 返回词条列表。
    返回: [(code, text, weight), ...] 严格按 order 升序排列
    """
    with open(path, "rb") as f:
        mmap = f.read()

    if len(mmap) < 48 or mmap[:4] != b"WDAT":
        raise ValueError(f"不是合法的 WDAT 文件或文件损坏: {path}")

    rd = lambda off: struct.unpack("<I", mmap[off:off+4])[0]
    rd_i32 = lambda off: struct.unpack("<i", mmap[off:off+4])[0]

    version = rd(4)
    dat_size = rd(8)
    leaf_count = rd(12)
    dat_off = rd(16)
    leaf_off = rd(20)
    entry_off = rd(24)
    str_off = rd(28)
    entry_count = rd(40)
    char_map_off = rd(44)

    max_code = rd_i32(char_map_off)
    char_map = [rd_i32(char_map_off + 4 + b * 4) for b in range(256)]
    rev_map = [0] * (max(0, max_code) + 1)
    for b, c in enumerate(char_map):
        if c > 0 and c < len(rev_map):
            rev_map[c] = b

    base_off = dat_off
    check_off = dat_off + dat_size * 4

    def base(i): return rd_i32(base_off + i * 4)
    def check(i): return rd_i32(check_off + i * 4)

    def terminal_leaf(s):
        t = base(s)
        if not (0 <= t < dat_size) or check(t) != s:
            return None
        bt = base(t)
        return (-bt - 1) if bt < 0 else None

    def read_leaf(leaf_idx):
        o = leaf_off + leaf_idx * 8
        return rd(o), struct.unpack("<H", mmap[o+4:o+6])[0]

    def read_string(off, length):
        start = str_off + off
        return mmap[start:start+length].decode("utf-8", errors="replace")

    def read_leaf_entries(leaf_idx):
        eoff, elen = read_leaf(leaf_idx)
        b_off = entry_off + eoff
        res = []
        for i in range(elen):
            o = b_off + i * 22
            toff = rd(o)
            tlen = struct.unpack("<H", mmap[o+4:o+6])[0]
            weight = rd_i32(o+6)
            order = rd(o+10)
            res.append((read_string(toff, tlen), weight, order))
        return res

    entries_by_order = [None] * entry_count
    stack = [(0, 0, 1)]  # (state, prefix_len, next_compact_char)
    path_bytes = []

    # 根节点自身是否有成词
    term = terminal_leaf(0)
    if term is not None:
        for text, weight, order in read_leaf_entries(term):
            entries_by_order[order] = ("", text, weight)

    # DFS 深度优先遍历还原 Trie
    while stack:
        s, plen, next_c = stack[-1]
        del path_bytes[plen:]
        descended = False
        while next_c <= max_code:
            c = next_c
            next_c += 1
            stack[-1] = (s, plen, next_c)
            t = base(s) + c
            if not (0 <= t < dat_size) or check(t) != s:
                continue
            path_bytes.append(rev_map[c])
            term = terminal_leaf(t)
            if term is not None:
                code = bytes(path_bytes).decode("ascii")
                for text, weight, order in read_leaf_entries(term):
                    entries_by_order[order] = (code, text, weight)
            stack.append((t, len(path_bytes), 1))
            descended = True
            break
        if not descended:
            stack.pop()

    # 完整性校验
    missing = [i for i, e in enumerate(entries_by_order) if e is None]
    if missing:
        raise RuntimeError(f"WDAT 解析存在缺失条目数: {len(missing)} (首个缺失 order: {missing[0]})")

    return entries_by_order


def make_rime_header(dict_name: str, version: str, description: str = "") -> str:
    """生成统一规范的 Rime Dict YAML 头部"""
    desc_lines = f"\n# {description}" if description else ""
    return f"""# Rime dictionary
# encoding: utf-8
#{desc_lines}
# 来源：官方小鹤音形_清风便携版 {version}

---
name: {dict_name}
version: "{version}"
sort: original
...
"""


def find_source_dir(cli_arg: str = None) -> Path:
    """定位官方清风便携版目录"""
    if cli_arg:
        p = Path(cli_arg)
        if p.is_dir():
            return p
        raise FileNotFoundError(f"指定的目录不存在: {cli_arg}")

    candidates = sorted(glob.glob("小鹤音形_清风便携版*"), reverse=True)
    if candidates and Path(candidates[0]).is_dir():
        return Path(candidates[0])

    raise FileNotFoundError("未在当前目录下找到形如 '小鹤音形_清风便携版*' 的目录，请手动指定路径")


def extract_schema_version(schema_toml_path: Path) -> str:
    """从 flypy.schema.toml 中提取官方版本号"""
    if not schema_toml_path.is_file():
        return "v1.26.9c"
    with open(schema_toml_path, "r", encoding="utf-8") as f:
        for line in f:
            m = re.match(r'version\s*=\s*"([^"]+)"', line.strip())
            if m:
                return m.group(1)
    return "v1.26.9c"


def convert_all(src_dir: Path, repo_root: Path):
    print(f"=== 开始从小鹤音形官方清风便携版同步码表 ===")
    print(f"源目录: {src_dir.resolve()}")
    print(f"目标仓库: {repo_root.resolve()}")

    flypy_dir = src_dir / "WindInput" / "data_custom" / "schemas" / "flypy"
    if not flypy_dir.is_dir():
        # 兼容直接把 flypy 作为根目录的情况
        if (src_dir / "00_xh.wdat").is_file():
            flypy_dir = src_dir
        else:
            raise FileNotFoundError(f"未找到 flypy 方案目录: {flypy_dir}")

    schema_toml = src_dir / "WindInput" / "data_custom" / "schemas" / "flypy.schema.toml"
    version = extract_schema_version(schema_toml)
    print(f"检测到官方版本号: {version}")

    xhup_dicts_dir = repo_root / "xhup_dicts"
    xhup_dicts_dir.mkdir(parents=True, exist_ok=True)

    # 1. 转换 00_xh.wdat -> xhup.primary.dict.yaml
    wdat_file = flypy_dir / "00_xh.wdat"
    primary_out = xhup_dicts_dir / "xhup.primary.dict.yaml"
    print(f"\n[1/11] 正在解析主词库: {wdat_file.name} ...")
    entries = parse_wdat(wdat_file)
    print(f"       已精确解析 {len(entries)} 个条目，正在写入 {primary_out.name} ...")
    with open(primary_out, "w", encoding="utf-8", newline="\n") as f:
        f.write(make_rime_header("xhup.primary", version, f"小鹤音形首选字词（共 {len(entries)} 条，保留官方原生出现序）"))
        for code, text, _ in entries:
            f.write(f"{text}\t{code}\n")

    # 2. 转换 11_fl.dict.yaml -> secondary, off-table, whimsicality
    fl_file = flypy_dir / "11_fl.dict.yaml"
    print(f"\n[2/11] 正在处理分类词库: {fl_file.name} ...")
    sec_entries = []
    off_entries = []
    whimsical_entries = []
    current_sec = None

    with open(fl_file, "r", encoding="utf-8") as f:
        for line in f:
            line_s = line.strip()
            if line_s.startswith("## "):
                current_sec = line_s[3:].strip()
                continue
            if not line_s or line_s.startswith("#") or "\t" not in line_s:
                continue

            parts = line_s.split("\t")
            txt, code = parts[0], parts[1]
            txt = clean_cc_expr(txt)

            if current_sec == "次选":
                sec_entries.append((txt, code))
            elif current_sec == "表外":
                off_entries.append((txt, code))
            elif current_sec == "随心":
                whimsical_entries.append((txt, code))

    # 写入次选
    secondary_out = xhup_dicts_dir / "xhup.secondary.dict.yaml"
    print(f"       次选字词: {len(sec_entries)} 条 -> {secondary_out.name}")
    with open(secondary_out, "w", encoding="utf-8", newline="\n") as f:
        f.write(make_rime_header("xhup.secondary", version, "小鹤音形次选字词（分类词库：次选）"))
        for txt, code in sec_entries:
            f.write(f"{txt}\t{code}\n")

    # 写入表外
    off_out = xhup_dicts_dir / "xhup.off-table.dict.yaml"
    print(f"       表外字词: {len(off_entries)} 条 -> {off_out.name}")
    with open(off_out, "w", encoding="utf-8", newline="\n") as f:
        f.write(make_rime_header("xhup.off-table", version, "小鹤音形表外字（分类词库：表外）"))
        for txt, code in off_entries:
            f.write(f"{txt}\t{code}\n")

    # 写入随心
    whimsical_out = xhup_dicts_dir / "xhup.whimsicality.dict.yaml"
    print(f"       随心码词: {len(whimsical_entries)} 条 -> {whimsical_out.name}")
    with open(whimsical_out, "w", encoding="utf-8", newline="\n") as f:
        f.write(make_rime_header("xhup.whimsicality", version, "小鹤音形随心码（分类词库：随心）"))
        for txt, code in whimsical_entries:
            f.write(f"{txt}\t{code}\n")

    # 3. 转换 21_yj.dict.yaml -> xhup.single.code.dict.yaml (一简次选)
    yj_file = flypy_dir / "21_yj.dict.yaml"
    yj_out = xhup_dicts_dir / "xhup.single.code.dict.yaml"
    print(f"\n[3/11] 正在处理一简次选: {yj_file.name} ...")
    yj_entries = []
    with open(yj_file, "r", encoding="utf-8") as f:
        for line in f:
            line_s = line.strip()
            if "\t" in line_s and not line_s.startswith("#"):
                parts = line_s.split("\t")
                yj_entries.append((parts[0], parts[1]))
    print(f"       一简词: {len(yj_entries)} 条 -> {yj_out.name}")
    with open(yj_out, "w", encoding="utf-8", newline="\n") as f:
        f.write(make_rime_header("xhup.single.code", version, "小鹤音形一简次选（26个单字/高频词）"))
        for txt, code in yj_entries:
            f.write(f"{txt}\t{code}\n")

    # 4. 转换 22_ej.dict.yaml -> xhup.secondary.simple.dict.yaml (二简次选)
    ej_file = flypy_dir / "22_ej.dict.yaml"
    ej_out = xhup_dicts_dir / "xhup.secondary.simple.dict.yaml"
    print(f"\n[4/11] 正在处理二简次选: {ej_file.name} ...")
    ej_entries = []
    with open(ej_file, "r", encoding="utf-8") as f:
        for line in f:
            line_s = line.strip()
            if "\t" in line_s and not line_s.startswith("#"):
                parts = line_s.split("\t")
                ej_entries.append((parts[0], parts[1]))
    print(f"       二简次选: {len(ej_entries)} 条 -> {ej_out.name}")
    with open(ej_out, "w", encoding="utf-8", newline="\n") as f:
        f.write(make_rime_header("xhup.secondary.simple", version, "小鹤音形二简次选单字（二重简码）"))
        for txt, code in ej_entries:
            f.write(f"{txt}\t{code}\n")

    # 5. 转换 51_qmc.dict.yaml -> xhup.full.code.words.dict.yaml (全码词)
    qmc_file = flypy_dir / "51_qmc.dict.yaml"
    qmc_out = xhup_dicts_dir / "xhup.full.code.words.dict.yaml"
    print(f"\n[5/11] 正在处理全码词: {qmc_file.name} ...")
    qmc_entries = []
    with open(qmc_file, "r", encoding="utf-8") as f:
        for line in f:
            line_s = line.strip()
            if "\t" in line_s and not line_s.startswith("#"):
                parts = line_s.split("\t")
                qmc_entries.append((parts[0], parts[1]))
    print(f"       全码词: {len(qmc_entries)} 条 -> {qmc_out.name}")
    with open(qmc_out, "w", encoding="utf-8", newline="\n") as f:
        f.write(make_rime_header("xhup.full.code.words", version, "小鹤音形全码词（已有简码，全码隐藏词）"))
        for txt, code in qmc_entries:
            f.write(f"{txt}\t{code}\n")

    # 6. 转换 53_qmz.dict.yaml -> xhup.full.code.chars.yaml (全码字)
    qmz_file = flypy_dir / "53_qmz.dict.yaml"
    qmz_out = xhup_dicts_dir / "xhup.full.code.chars.yaml"
    print(f"\n[6/11] 正在处理全码字: {qmz_file.name} ...")
    qmz_entries = []
    with open(qmz_file, "r", encoding="utf-8") as f:
        for line in f:
            line_s = line.strip()
            if "\t" in line_s and not line_s.startswith("#"):
                parts = line_s.split("\t")
                qmz_entries.append((parts[0], parts[1]))
    print(f"       全码字: {len(qmz_entries)} 条 -> {qmz_out.name}")
    with open(qmz_out, "w", encoding="utf-8", newline="\n") as f:
        f.write(make_rime_header("xhup.full.code.chars", version, "小鹤音形全码字（已有简码，全码出字）"))
        for txt, code in qmz_entries:
            f.write(f"{txt}\t{code}\n")

    # 7. 转换 52_upz.dict.yaml -> xhup.rare.chars.dict.yaml (生僻字)
    upz_file = flypy_dir / "52_upz.dict.yaml"
    upz_out = xhup_dicts_dir / "xhup.rare.chars.dict.yaml"
    print(f"\n[7/11] 正在处理生僻字: {upz_file.name} ...")
    upz_entries = []
    with open(upz_file, "r", encoding="utf-8") as f:
        for line in f:
            line_s = line.strip()
            if "\t" in line_s and not line_s.startswith("#"):
                parts = line_s.split("\t")
                upz_entries.append((parts[0], parts[1]))
    print(f"       生僻字: {len(upz_entries)} 条 -> {upz_out.name}")
    with open(upz_out, "w", encoding="utf-8", newline="\n") as f:
        f.write(make_rime_header("xhup.rare.chars", version, "小鹤音形生僻字（初学模式可选启用）"))
        for txt, code in upz_entries:
            f.write(f"{txt}\t{code}\n")

    # 8. 转换 61_ok.dict.yaml -> xhup.ok.dict.yaml (ok拼字)
    ok_file = flypy_dir / "61_ok.dict.yaml"
    ok_out = xhup_dicts_dir / "xhup.ok.dict.yaml"
    print(f"\n[8/11] 正在处理 ok 拼字库: {ok_file.name} ...")
    ok_entries = []
    with open(ok_file, "r", encoding="utf-8") as f:
        for line in f:
            line_s = line.strip()
            if "\t" in line_s and not line_s.startswith("#"):
                parts = line_s.split("\t")
                ok_entries.append((parts[0], parts[1]))
    print(f"       ok拼字: {len(ok_entries)} 条 -> {ok_out.name}")
    with open(ok_out, "w", encoding="utf-8", newline="\n") as f:
        f.write(make_rime_header("xhup.ok", version, "小鹤音形 ok 引导两分/三分拆字拼字"))
        for txt, code in ok_entries:
            f.write(f"{txt}\t{code}\n")

    # 9. 转换 81_kf.dict.yaml -> xhup.fast.symbols.dict.yaml (快符)
    kf_file = flypy_dir / "81_kf.dict.yaml"
    kf_out = xhup_dicts_dir / "xhup.fast.symbols.dict.yaml"
    print(f"\n[9/11] 正在处理快符: {kf_file.name} ...")
    kf_entries = [("：", ";"), ("；", ";")]  # 保留分号直接出冒号及分号
    with open(kf_file, "r", encoding="utf-8") as f:
        for line in f:
            line_s = line.strip()
            if "\t" not in line_s or line_s.startswith("#"):
                continue
            parts = line_s.split("\t")
            txt, code = parts[0], parts[1]
            if "$CC" in txt:
                if any(x in txt for x in ["last()", "undo_commit", "Tab", "End"]):
                    continue
                txt = clean_cc_expr(txt)
            if not code.startswith(";"):
                code = ";" + code
            # 避免重复
            if (txt, code) not in kf_entries:
                kf_entries.append((txt, code))
    print(f"       快符: {len(kf_entries)} 条 -> {kf_out.name}")
    with open(kf_out, "w", encoding="utf-8", newline="\n") as f:
        f.write(make_rime_header("xhup.fast.symbols", version, "小鹤音形分号快符"))
        for txt, code in kf_entries:
            f.write(f"{txt}\t{code}\n")

    # 10. 转换 41_fh.dict.yaml -> xhup.symbols.dict.yaml (符号与字根)
    fh_file = flypy_dir / "41_fh.dict.yaml"
    fh_out = xhup_dicts_dir / "xhup.symbols.dict.yaml"
    print(f"\n[10/11] 正在处理符号与字根: {fh_file.name} ...")
    fh_entries = []
    with open(fh_file, "r", encoding="utf-8") as f:
        for line in f:
            line_s = line.strip()
            if "\t" not in line_s or line_s.startswith("#"):
                continue
            parts = line_s.split("\t")
            txt, code = parts[0], parts[1]
            txt = clean_cc_expr(txt)
            fh_entries.append((txt, code))
    print(f"        符号与字根: {len(fh_entries)} 条 -> {fh_out.name}")
    with open(fh_out, "w", encoding="utf-8", newline="\n") as f:
        f.write(make_rime_header("xhup.symbols", version, "小鹤音形符号及部首字根"))
        for txt, code in fh_entries:
            f.write(f"{txt}\t{code}\n")

    # 11. 转换 82_bq.dict.yaml -> xhup.emoji.dict.yaml (Emoji 表情)
    bq_file = flypy_dir / "82_bq.dict.yaml"
    bq_out = xhup_dicts_dir / "xhup.emoji.dict.yaml"
    print(f"\n[11/11] 正在处理 Emoji 表情: {bq_file.name} ...")
    bq_entries = []
    if bq_file.is_file():
        with open(bq_file, "r", encoding="utf-8") as f:
            for line in f:
                line_s = line.strip()
                if "\t" in line_s and not line_s.startswith("#"):
                    parts = line_s.split("\t")
                    # 在 Rime 中，小鹤表情通常加 / 引导，如 /q -> 🎉
                    txt, code = parts[0], parts[1]
                    bq_entries.append((txt, "/" + code if not code.startswith("/") else code))
        with open(bq_out, "w", encoding="utf-8", newline="\n") as f:
            f.write(make_rime_header("xhup.emoji", version, "小鹤音形斜杠引导表情"))
            for txt, code in bq_entries:
                f.write(f"{txt}\t{code}\n")
        print(f"        Emoji 表情: {len(bq_entries)} 条 -> {bq_out.name}")

    # 12. 更新二简词提示 opencc/short_hints.txt
    ejc_file = flypy_dir / "ejc.wdict.yaml"
    short_hints_file = repo_root / "opencc" / "short_hints.txt"
    if ejc_file.is_file():
        print(f"\n[12/12] 正在提取二简词提示: {ejc_file.name} -> {short_hints_file.name} ...")
        hints_map = {}
        # 先读取现有的保留基础
        if short_hints_file.is_file():
            with open(short_hints_file, "r", encoding="utf-8") as f:
                for line in f:
                    line_s = line.strip()
                    if "\t" in line_s:
                        w, c = line_s.split("\t", 1)
                        hints_map[w] = c

        # 用官方最新二简提示更新/合并
        with open(ejc_file, "r", encoding="utf-8") as f:
            for line in f:
                # 形如: $CC("两位_lw", type("两位"))
                m = re.search(r'\$CC\("([^"_]+)_([a-z]{2})",\s*type\("([^"]+)"\)\)', line)
                if m:
                    word, short_code = m.group(3), m.group(2)
                    hints_map[word] = short_code

        short_hints_file.parent.mkdir(parents=True, exist_ok=True)
        with open(short_hints_file, "w", encoding="utf-8", newline="\n") as f:
            for word in sorted(hints_map.keys()):
                f.write(f"{word}\t{hints_map[word]}\n")
        print(f"        二简词提示已更新，共 {len(hints_map)} 条")

    # 13. 检查用户词库占位文件
    user_file = xhup_dicts_dir / "xhup.user.dict.yaml"
    if not user_file.exists():
        with open(user_file, "w", encoding="utf-8", newline="\n") as f:
            f.write(make_rime_header("xhup.user", version, "用户自用自定义词库"))

    user_top_file = xhup_dicts_dir / "xhup.user.top.dict.yaml"
    if not user_top_file.exists():
        with open(user_top_file, "w", encoding="utf-8", newline="\n") as f:
            f.write(make_rime_header("xhup.user.top", version, "用户置顶词库"))

    # 14. 重新生成 xhup.dict.yaml 汇总文件
    dict_index_path = repo_root / "xhup.dict.yaml"
    print(f"\n[14] 正在更新主词库入口索引: {dict_index_path.name} ...")
    dict_content = f"""# Rime dictionary
# encoding: utf-8
#
# 凇鹤拼音 - 小鹤音形词库总索引
# 来源：官方小鹤音形_清风便携版 {version}
#
# 词库模式说明（对齐官方说明）：
# ① 熟手词库模式（默认推荐）：首选 + 分类词库（次选/随心/表外）+ 一简次选 + 快符
# ② 常规词库模式：① + 全码词
# ③ 初学词库模式：② + 全码字 + 生僻字

---
name: xhup
version: "{version}"

import_tables:
  # --- 用户优先层 ---
  - "xhup_dicts/xhup.user.top"          # 用户置顶码表
  - "xhup_dicts/xhup.user"              # 用户自用词库

  # --- ① 熟手模式基础库（默认启用）---
  - "xhup_dicts/xhup.primary"           # -0- 首选字词（68,572条，官方原生自然序）
  - "xhup_dicts/xhup.secondary"         # 1.1 次选字词（分类词库：次选）
  - "xhup_dicts/xhup.whimsicality"      # 1.1 随心码（分类词库：随心）
  - "xhup_dicts/xhup.off-table"         # 2.2 表外字（分类词库：表外）
  - "xhup_dicts/xhup.single.code"       # 2.1 一简词（一简次选，26个单字/词）
  - "xhup_dicts/xhup.fast.symbols"      # 1.2 快符（分号引导符号）

  # --- ② 常规模式扩展（已有简码的全码词，可按需开启）---
  - "xhup_dicts/xhup.full.code.words"   # 2.3 全码词（约500条）

  # --- ③ 初学模式扩展（全码字与生僻字，默认关闭，初学可开启）---
  # - "xhup_dicts/xhup.full.code.chars"   # 全码字（已有简码，全码有其他字词，约1650条）
  # - "xhup_dicts/xhup.rare.chars"        # 生僻字（约500条）

  # --- 可选附加库 ---
  # - "xhup_dicts/xhup.secondary.simple"  # 二简次选（66个单字，备选）
  # - "xhup_dicts/xhup.symbols"           # 符号与部首字根
  # - "xhup_dicts/xhup.emoji"             # 斜杠引导表情
  # - "xhup_dicts/xhup.ok"                # ok引导两分/三分拆字拼字库（8.8万条）
...
"""
    with open(dict_index_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(dict_content)

    print(f"\n=== 全部码表无损同步完成！===")


def main():
    arg_dir = sys.argv[1] if len(sys.argv) > 1 else None
    repo_root = Path(__file__).resolve().parent.parent.parent
    src_dir = find_source_dir(arg_dir)
    convert_all(src_dir, repo_root)


if __name__ == "__main__":
    main()
