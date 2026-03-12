import app from "ags/gtk4/app"
import style from "./style/main.scss"
import windows from "./windows";
import GLib from "gi://GLib?version=2.0";

import { openScreenshot } from "./widget/ScreenShot/ScreenshotPopup";
import { toggleVolume, toggleBrightness } from "./widget/Osd/Osd";

const DATA = GLib.build_filenamev([GLib.get_home_dir(), ".config", "ags"]);

app.start({
  icons: `${DATA}/icons`,
  css: style,
  main() {
    windows.map((win) => app.get_monitors().map(win));
  },
  requestHandler(msg, res) {
    if (msg[0] === "screenshot") {
      openScreenshot();
      res("ok");
    } else if (msg[0] === "volume") {
      toggleVolume();
      res("ok");
    } else if (msg[0] === "brightness") {
      toggleBrightness();
      res("ok");
    } else {
      res("unknown request");
    }
  }
})
