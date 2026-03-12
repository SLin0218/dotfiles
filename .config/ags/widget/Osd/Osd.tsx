import Wp from "gi://AstalWp";
import Battery from "gi://AstalBattery";
import GLib from "gi://GLib";
import { Astal, Gtk } from "ags/gtk4";
import Brightness from "../../libs/brightness";
import { createBinding, createState } from "ags";

const TIMEOUT = 2000;

// 用于全局触发 OSD 显示的状态
const [volumeState, setVolumeState] = createState(false);
const [brightnessState, setBrightnessState] = createState(false);

export function toggleVolume() {
  setVolumeState(!volumeState.peek());
}

export function toggleBrightness() {
  setBrightnessState(!brightnessState.peek());
}

/**
 * 控制器：管理所有显示器上的 OSD 窗口显隐
 */
class OSDController {
  private static instance: OSDController;
  private windows = new Set<Astal.Window>();
  private timerId: number = 0;
  private count = 0; // 当前正在显示的滑块引用计数

  static get_default() {
    if (!this.instance) this.instance = new OSDController();
    return this.instance;
  }

  addWindow(win: Astal.Window) {
    this.windows.add(win);
  }

  show() {
    this.count++;
    if (this.timerId > 0) {
      GLib.source_remove(this.timerId);
      this.timerId = 0;
    }
    for (const win of this.windows) {
      if (!win.visible) win.set_visible(true);
    }
  }

  hide() {
    this.count = Math.max(0, this.count - 1);
    if (this.count === 0) {
      if (this.timerId > 0) GLib.source_remove(this.timerId);

      // 延迟关闭窗口，给 Revealer 留出过渡动画时间
      this.timerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => {
        if (this.count === 0) {
          for (const win of this.windows) {
            win.set_visible(false);
          }
        }
        this.timerId = 0;
        return GLib.SOURCE_REMOVE;
      });
    }
  }
}

interface SliderProps {
  bindable: Brightness | Wp.Endpoint | Battery.Device;
}

function OsdSlider({ bindable }: SliderProps) {
  const osd = OSDController.get_default();

  // 根据 bindable 类型解析绑定和订阅逻辑
  const config = (() => {
    if (bindable instanceof Brightness) {
      return {
        label: createBinding(bindable, "screen").as(s => `${Math.floor(s * 100)}`),
        value: createBinding(bindable, "screen").as(s => s * 100),
        iconName: createBinding(bindable, "iconNameScreen"),
        subscribe: (cb: (timeout: number) => void) => brightnessState.subscribe(() => cb(2000)),
      };
    } else if (bindable instanceof Wp.Endpoint) {
      return {
        label: createBinding(bindable, "volume").as(v => `${Math.floor(v * 100)}`),
        value: createBinding(bindable, "volume").as(v => v * 100),
        iconName: createBinding(bindable, "volumeIcon"),
        subscribe: (cb: (timeout: number) => void) => volumeState.subscribe(() => cb(2000)),
      };
    } else if (bindable instanceof Battery.Device) {
      return {
        label: createBinding(bindable, "percentage").as(p => `${Math.floor(p * 100)}`),
        value: createBinding(bindable, "percentage").as(p => p * 100),
        iconName: createBinding(bindable, "battery_icon_name"),
        subscribe: (cb: (timeout: number) => void) => {
          const id = bindable.connect("notify::percentage", (percentage: number) => {
            if (percentage == 0.3) {
              cb(5000);
            }
          });
          const id2 = bindable.connect("notify::state", () => cb(5000));
          return () => { bindable.disconnect(id); bindable.disconnect(id2); };
        },
      };
    }
    // 理论上不可达，但为了类型安全返回一个哑对象
    return {
      label: createBinding(bindable as any, "screen").as(() => ""),
      value: createBinding(bindable as any, "screen").as(() => 0),
      iconName: createBinding(bindable as any, "screen").as(() => ""),
      subscribe: () => () => { },
    };
  })();

  if (!config) return <box visible={false} />;

  return (
    <revealer
      transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}
      $={(self) => {
        let timerId = 0;
        let isShowing = false;

        const trigger = (timeout: number) => {
          // 防抖处理：如果已经在计时，重置计时器
          if (timerId > 0) {
            GLib.source_remove(timerId);
          } else {
            if (!isShowing) {
              osd.show();
              isShowing = true;
            }
            self.revealChild = true;
            self.set_opacity(1);
          }

          timerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, timeout, () => {
            self.revealChild = false;
            self.set_opacity(0.1);
            osd.hide();
            isShowing = false;
            timerId = 0;
            return GLib.SOURCE_REMOVE;
          });
        };

        config.subscribe(trigger);
      }}
    >
      <box cssClasses={["osd-box"]} orientation={Gtk.Orientation.VERTICAL} spacing={5}>
        <label label={config.label} />
        <slider
          cssClasses={["osd-bar"]}
          orientation={Gtk.Orientation.VERTICAL}
          max={100}
          value={config.value}
          drawValue={false}
          inverted
        />
        <image iconName={config.iconName} cssClasses={["osd-icon"]} />
      </box>
    </revealer>
  );
}

export default function OSD(monitor: number) {
  const osd = OSDController.get_default();

  return (
    <window
      name={`osd-${monitor}`} // 确保每个显示器的窗口名称唯一
      namespace="osd"
      cssClasses={["osd-window-outer"]}
      layer={Astal.Layer.OVERLAY}
      exclusivity={Astal.Exclusivity.IGNORE}
      anchor={Astal.WindowAnchor.LEFT}
      keymode={Astal.Keymode.NONE}
      visible={false}
      monitor={monitor}
      $={(self) => osd.addWindow(self)}
    >
      <box cssClasses={["osd-window"]}>
        {Brightness.get_default() && <OsdSlider bindable={Brightness.get_default()!} />}
        {Wp.get_default()?.audio.defaultSpeaker && <OsdSlider bindable={Wp.get_default()!.audio.defaultSpeaker} />}
        {Battery.get_default() && <OsdSlider bindable={Battery.get_default()!} />}
      </box>
    </window>
  );
}