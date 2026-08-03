"""draw kitty tab"""

# pyright: reportMissingImports=false
# pylint: disable=E0401,C0116,C0103,W0603,R0913

from kitty.fast_data_types import Screen, get_options
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb
from kitty.utils import color_as_int

opts = get_options()


def get_color(color_val, fallback_rgb: int) -> int:
    if color_val is None:
        return as_rgb(fallback_rgb)  # type: ignore
    try:
        return as_rgb(color_as_int(color_val))  # type: ignore
    except Exception:
        return as_rgb(fallback_rgb)  # type: ignore


SUPERSCRIPTS = ["¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹", "¹⁰"]


def draw_tab(
    draw_data: DrawData,  # type: ignore
    screen: Screen,
    tab: TabBarData,  # type: ignore
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,  # type: ignore
) -> int:
    # 1. Draw tab separator (if not the first tab)
    if index > 1:
        old_fg = screen.cursor.fg
        old_bg = screen.cursor.bg
        screen.cursor.fg = as_rgb(0x313244)  # type: ignore
        screen.cursor.bg = 0
        screen.draw("┃")
        screen.cursor.fg = old_fg
        screen.cursor.bg = old_bg

    # Save original cursor styling
    old_fg = screen.cursor.fg
    old_bg = screen.cursor.bg
    old_bold = screen.cursor.bold
    old_italic = screen.cursor.italic

    # 2. Determine indicator and its foreground color
    indicator = ""
    indicator_fg = 0

    if tab.is_active:  # type: ignore
        if tab.num_windows > 1:  # type: ignore
            num = min(tab.num_windows, 10)  # type: ignore
            indicator = f"{SUPERSCRIPTS[num - 1]} "
        else:
            indicator = "󰐾 "
    else:
        if tab.needs_attention:  # type: ignore
            indicator = "󱅫 "
            indicator_fg = as_rgb(color_as_int(opts.color3))  # type: ignore
        elif tab.num_windows > 1:  # type: ignore
            num = min(tab.num_windows, 10)  # type: ignore
            indicator = f"{SUPERSCRIPTS[num - 1]} "
        else:
            indicator = "󰄰 "

    # 3. Calculate max length for title to prevent overflow
    # decoration length: leading space (1) + indicator length + trailing space (1)
    decoration_len = 2 + len(indicator)
    max_allowed_title_len = max_title_length - decoration_len

    title = tab.title  # type: ignore
    if len(title) > max_allowed_title_len:
        title = title[: max(5, max_allowed_title_len - 1)] + "…"

    # 4. Draw tab content
    if tab.is_active:  # type: ignore
        # Active Tab styling: bg = color0, fg for indicator = #c6a0f6, fg for title = color6
        screen.cursor.bg = as_rgb(color_as_int(opts.color0))  # type: ignore
        screen.cursor.fg = as_rgb(0xC6A0F6)  # type: ignore
        screen.draw(" ")
        screen.draw(indicator)

        screen.cursor.fg = as_rgb(color_as_int(opts.color6))  # type: ignore
        screen.draw(title)

        screen.draw(" ")
        screen.cursor.bg = 0
    else:
        # Inactive Tab styling: bg = default (0), fg for indicator = indicator_fg or color0, fg for title = color7
        screen.cursor.bg = 0
        screen.cursor.fg = (
            indicator_fg if indicator_fg else as_rgb(color_as_int(opts.color0))  # type: ignore
        )
        screen.draw(" ")
        screen.draw(indicator)

        screen.cursor.fg = as_rgb(color_as_int(opts.color7))  # type: ignore
        screen.draw(title)

        screen.draw(" ")

    # Restore cursor styling
    screen.cursor.fg = old_fg
    screen.cursor.bg = old_bg
    screen.cursor.bold = old_bold
    screen.cursor.italic = old_italic

    return screen.cursor.x
