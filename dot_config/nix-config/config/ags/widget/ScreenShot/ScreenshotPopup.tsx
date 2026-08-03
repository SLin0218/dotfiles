import { Astal, Gtk, Gdk } from "ags/gtk4";
import app from "ags/gtk4/app";
import AstalHyprland from "gi://AstalHyprland";
import GLib from "gi://GLib?version=2.0";
import Gio from "gi://Gio?version=2.0";
import GObject from "gi://GObject";
import Graphene from "gi://Graphene";
import GdkPixbuf from "gi://GdkPixbuf";

// 使用 PPM 格式：无压缩原始像素，生成速度快 10 倍以上
const FULL_TMP = "/dev/shm/ags-screenshot-full.ppm";
const CROP_TMP = "/dev/shm/ags-screenshot.png";

function ensureDir(path: string) {
  try { Gio.File.new_for_path(path).make_directory_with_parents(null); } catch { }
}

function run(cmd: string) {
  try { Gio.Subprocess.new(["bash", "-c", cmd], Gio.SubprocessFlags.NONE); }
  catch (e) { console.error("[Screenshot]", e); }
}

function getOutputPath() {
  const dir = `${GLib.get_home_dir()}/Pictures/Screenshots`;
  ensureDir(dir);
  const ts = GLib.DateTime.new_now_local().format("%Y-%m-%d_%H-%M-%S")!;
  return `${dir}/${ts}.png`;
}

// ─── 区域与窗口选择自定义 Widget ─────────────────────────────────

interface WindowRect { x: number; y: number; w: number; h: number }

const SelectionOverlay = GObject.registerClass(
  class SelectionOverlay extends Gtk.Widget {
    _texture: Gdk.Texture | null = null;
    _mode: "none" | "region" | "window" = "none";

    _sx = 0; _sy = 0; _cx = 0; _cy = 0;
    _dragging = false;

    _windows: WindowRect[] = [];
    _hx = 0; _hy = 0; _hw = 0; _hh = 0;
    _highlighted = false;

    _onDone: ((x: number, y: number, w: number, h: number) => void) | null = null;

    constructor() {
      super();
      this.hexpand = true;
      this.vexpand = true;

      const drag = new Gtk.GestureDrag();
      drag.connect("drag-begin", (_, x, y) => {
        if (this._mode !== "region") return;
        this._sx = x; this._sy = y;
        this._cx = x; this._cy = y;
        this._dragging = true;
        this.queue_draw();
      });
      drag.connect("drag-update", (_, ox, oy) => {
        if (this._mode !== "region") return;
        this._cx = this._sx + ox;
        this._cy = this._sy + oy;
        this.queue_draw();
      });
      drag.connect("drag-end", (_, ox, oy) => {
        if (this._mode !== "region") return;
        this._cx = this._sx + ox;
        this._cy = this._sy + oy;
        this._dragging = false;
        const x = Math.round(Math.min(this._sx, this._cx));
        const y = Math.round(Math.min(this._sy, this._cy));
        const w = Math.round(Math.abs(this._cx - this._sx));
        const h = Math.round(Math.abs(this._cy - this._sy));
        if (w > 5 && h > 5) this._onDone?.(x, y, w, h);
      });
      this.add_controller(drag);

      const motion = new Gtk.EventControllerMotion();
      motion.connect("motion", (_, x, y) => {
        if (this._mode !== "window") return;
        let found = null;
        for (let i = this._windows.length - 1; i >= 0; i--) {
          const w = this._windows[i];
          if (x >= w.x && x <= w.x + w.w && y >= w.y && y <= w.y + w.h) {
            found = w;
            break;
          }
        }
        if (found) {
          this._hx = found.x; this._hy = found.y;
          this._hw = found.w; this._hh = found.h;
          this._highlighted = true;
        } else {
          this._highlighted = false;
        }
        this.queue_draw();
      });
      this.add_controller(motion);

      const click = new Gtk.GestureClick();
      click.connect("pressed", () => {
        if (this._mode === "window" && this._highlighted) {
          if (this._hw > 5 && this._hh > 5) {
            this._onDone?.(this._hx, this._hy, this._hw, this._hh);
          }
        }
      });
      this.add_controller(click);
    }

    loadScreenshot(path: string) {
      try { this._texture = Gdk.Texture.new_from_filename(path); }
      catch (e) { console.error("[Screenshot] texture load:", e); }
      this._dragging = false;
      this._highlighted = false;
      this.queue_draw();
    }

    enableRegionSelection() {
      this._mode = "region";
      this.set_cursor_from_name("crosshair");
      this._dragging = false;
      this._highlighted = false;
      this.queue_draw();
    }

    enableWindowSelection(windows: WindowRect[]) {
      this._mode = "window";
      this._windows = windows;
      this.set_cursor_from_name("crosshair");
      this._dragging = false;
      this._highlighted = false;
      this.queue_draw();
    }

    disableSelection() {
      this._mode = "none";
      this.set_cursor_from_name("default");
      this._dragging = false;
      this._highlighted = false;
      this.queue_draw();
    }

    setOnDone(cb: (x: number, y: number, w: number, h: number) => void) {
      this._onDone = cb;
    }

    vfunc_snapshot(snapshot: Gtk.Snapshot) {
      const W = this.get_width(), H = this.get_height();
      if (this._texture)
        snapshot.append_texture(this._texture, new Graphene.Rect().init(0, 0, W, H));

      const dark = new Gdk.RGBA();
      dark.parse("rgba(0,0,0,0.45)");

      let drawHighlight = false;
      let sx = 0, sy = 0, sw = 0, sh = 0;

      if (this._mode === "region" && this._dragging) {
        drawHighlight = true;
        sx = Math.min(this._sx, this._cx);
        sy = Math.min(this._sy, this._cy);
        sw = Math.abs(this._cx - this._sx);
        sh = Math.abs(this._cy - this._sy);
      } else if (this._mode === "window" && this._highlighted) {
        drawHighlight = true;
        sx = this._hx; sy = this._hy;
        sw = this._hw; sh = this._hh;
      }

      const white = new Gdk.RGBA();
      white.parse("rgba(255,255,255,0.85)");
      const b = 1.5;

      if (drawHighlight) {
        snapshot.append_color(dark, new Graphene.Rect().init(0, 0, W, sy));
        snapshot.append_color(dark, new Graphene.Rect().init(0, sy + sh, W, H - sy - sh));
        snapshot.append_color(dark, new Graphene.Rect().init(0, sy, sx, sh));
        snapshot.append_color(dark, new Graphene.Rect().init(sx + sw, sy, W - sx - sw, sh));

        snapshot.append_color(white, new Graphene.Rect().init(sx, sy, sw, b));
        snapshot.append_color(white, new Graphene.Rect().init(sx, sy + sh - b, sw, b));
        snapshot.append_color(white, new Graphene.Rect().init(sx, sy, b, sh));
        snapshot.append_color(white, new Graphene.Rect().init(sx + sw - b, sy, b, sh));
      } else {
        snapshot.append_color(dark, new Graphene.Rect().init(0, 0, W, H));
      }
    }
  }
);

function cropAndEdit(x: number, y: number, w: number, h: number, logicalW: number, logicalH: number) {
  const pixbuf = GdkPixbuf.Pixbuf.new_from_file(FULL_TMP);
  const scaleX = pixbuf.get_width() / logicalW;
  const scaleY = pixbuf.get_height() / logicalH;

  const cx = Math.max(0, Math.round(x * scaleX));
  const cy = Math.max(0, Math.round(y * scaleY));
  const cw = Math.min(Math.round(w * scaleX), pixbuf.get_width() - cx);
  const ch = Math.min(Math.round(h * scaleY), pixbuf.get_height() - cy);

  if (cw <= 0 || ch <= 0) return;

  const cropped = pixbuf.new_subpixbuf(cx, cy, cw, ch);
  cropped.savev(CROP_TMP, "png", [], []);
  run(`satty -f "${CROP_TMP}" -o "${getOutputPath()}"`);
}

function makeBtn(icon: string, label: string, onClick: () => void) {
  const btn = new Gtk.Button({ cssClasses: ["screenshot-mode-btn"] });
  const box = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 4 });
  box.append(new Gtk.Image({ iconName: icon, pixelSize: 20 }));
  box.append(new Gtk.Label({ label, cssClasses: ["mode-label"] }));
  btn.set_child(box);
  btn.connect("clicked", onClick);
  return btn;
}

// ─── 公开入口：打开截图 ───────────────────────────────────

let screenshotWin: Astal.Window | null = null;

export function openScreenshot() {
  if (screenshotWin) return;

  // 1. 同步截取 PPM 格式，比 PNG 快得多
  try {
    GLib.spawn_command_line_sync(`grim -t ppm "${FULL_TMP}"`);
  } catch (e) {
    console.error("[Screenshot] grim sync failed:", e);
    return;
  }

  // 2. 准备 UI 内容
  const overlay = new SelectionOverlay();
  overlay.loadScreenshot(FULL_TMP);
  overlay.disableSelection();

  const close = () => {
    screenshotWin?.close();
    screenshotWin?.destroy();
    screenshotWin = null;
  };

  const toolbar = new Gtk.Box({
    cssClasses: ["screenshot-toolbar"],
    halign: Gtk.Align.CENTER,
    valign: Gtk.Align.END,
    spacing: 6,
    marginBottom: 16,
  });

  toolbar.append(makeBtn("fullscreen-symbolic", "全屏", () => {
    close();
    run(`satty -f "${FULL_TMP}" -o "${getOutputPath()}"`);
  }));

  toolbar.append(makeBtn("screenshot-region-symbolic", "区域", () => {
    toolbar.visible = false;
    overlay.enableRegionSelection();
  }));

  toolbar.append(makeBtn("screenshot-window-symbolic", "窗口", () => {
    toolbar.visible = false;
    try {
      const hypr = AstalHyprland.get_default();
      const activeWs = hypr.get_focused_workspace();
      const activeMon = hypr.get_monitors().find(m => m.name === activeWs.monitor);
      const mx = activeMon ? activeMon.x : 0;
      const my = activeMon ? activeMon.y : 0;

      const windows = hypr.get_clients()
        .filter(c => c.workspace?.id === activeWs.id && !c.floating && c.mapped)
        .map(c => ({
          x: c.x - mx,
          y: c.y - my,
          w: c.width,
          h: c.height
        }));

      overlay.enableWindowSelection(windows);
    } catch (e) {
      console.error("[Screenshot] fetch windows:", e);
      close();
    }
  }));

  const container = new Gtk.Overlay();
  container.set_child(overlay);
  container.add_overlay(toolbar);

  // 3. 显示窗口
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;
  screenshotWin = new Astal.Window({
    layer: Astal.Layer.OVERLAY,
    exclusivity: Astal.Exclusivity.IGNORE,
    keymode: Astal.Keymode.EXCLUSIVE,
    anchor: TOP | BOTTOM | LEFT | RIGHT,
    application: app,
    visible: true,
    child: container,
  });

  const keyCtrl = new Gtk.EventControllerKey();
  keyCtrl.connect("key-pressed", (_, keyval) => {
    if (keyval === Gdk.KEY_Escape) { close(); return true; }
    return false;
  });
  screenshotWin.add_controller(keyCtrl);

  overlay.setOnDone((x, y, w, h) => {
    const logicalW = overlay.get_width();
    const logicalH = overlay.get_height();
    try {
      close();
      if (logicalW > 0 && logicalH > 0) {
        cropAndEdit(x, y, w, h, logicalW, logicalH);
      }
    } catch (e) {
      console.error("[Screenshot] crop:", e);
      close();
    }
  });
}
