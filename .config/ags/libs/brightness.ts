import GObject, { register, getter, setter } from "ags/gobject";
import { monitorFile, readFileAsync } from "ags/file";
import { exec, execAsync } from "ags/process";

const get = (args: string) => Number(exec(`brightnessctl ${args}`));
const screen = exec(`bash -c "ls -w1 /sys/class/backlight | head -1"`);
const kbd = exec(`bash -c "ls -w1 /sys/class/leds | head -1"`);

const ICON_NAME_HIGH = "brightness-high-symbolic";
const ICON_NAME_MEDIUM = "brightness-medium-symbolic";
const ICON_NAME_LOW = "brightness-low-symbolic";

const ICON_NAME_HIGH_KDB = "backlight-high-symbolic";
const ICON_NAME_LOW_KDB = "backlight-low-symbolic";
const ICON_NAME_OFF_KDB = "backlight-off-symbolic";

function getIconNameScreen(v: number) {
  if (v > 0.75) {
    return ICON_NAME_HIGH;
  } else if (v > 0.3) {
    return ICON_NAME_MEDIUM;
  } else {
    return ICON_NAME_LOW;
  }
}

function getIconNameKbd(v: number) {
  if (v === 2) {
    return ICON_NAME_HIGH_KDB;
  } else if (v === 1) {
    return ICON_NAME_LOW_KDB;
  } else {
    return ICON_NAME_OFF_KDB;
  }
}

@register({ GTypeName: "Brightness" })
export default class Brightness extends GObject.Object {
  static instance: Brightness;
  static get_default() {
    if (!this.instance) this.instance = new Brightness();

    return this.instance;
  }

  #kbdMax = get(`--device ${kbd} max`);
  #kbd = get(`--device ${kbd} get`);
  #screenMax = get("max");
  #screen = get("get") / (get("max") || 1);
  #iconNameScreen = getIconNameScreen(this.#screen)
  #iconNameKbd = getIconNameKbd(this.#kbd)

  @getter(Number)
  get kbd() {
    return this.#kbd;
  }

  @getter(String)
  get iconNameScreen() {
    return this.#iconNameScreen
  }

  @getter(String)
  get iconNameKbd() {
    return this.#iconNameKbd
  }

  @setter(Number)
  set kbd(value) {
    if (value < 0 || value > this.#kbdMax) return;

    execAsync(`brightnessctl -d ${kbd} s ${value} -q`).then(() => {
      this.#kbd = value;
      this.notify("kbd");
    });
  }

  @getter(Number)
  get screen() {
    return this.#screen;
  }

  @setter(Number)
  set screen(percent) {
    if (percent < 0) percent = 0;

    if (percent > 1) percent = 1;

    execAsync(`brightnessctl set ${Math.floor(percent * 100)}% -q`).then(() => {
      this.#screen = percent;
      this.notify("screen");
    });
  }

  constructor() {
    super();

    const screenPath = `/sys/class/backlight/${screen}/brightness`;
    const kbdPath = `/sys/class/leds/${kbd}/brightness`;

    monitorFile(screenPath, async (f) => {
      const v = await readFileAsync(f);
      this.#screen = Number(v) / this.#screenMax;
      this.#iconNameScreen = getIconNameScreen(this.#screen)
      this.notify("icon-name-screen")
      this.notify("screen");
    });

    monitorFile(kbdPath, async (f) => {
      const v = await readFileAsync(f);
      this.#kbd = Number(v) / this.#kbdMax;
      this.#iconNameKbd = getIconNameKbd(this.#kbd)
      console.log(this.#iconNameKbd)
      this.notify("icon-name-kbd")
      this.notify("kbd");
    });
  }
}