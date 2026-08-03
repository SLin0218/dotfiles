import { createBinding } from "ags"
import Gio from "gi://Gio"
import Battery from "gi://AstalBattery";

export default () => {
  const bat = Battery.get_default();
  return (
    <button>
      <box spacing={4}>
        <image
          gicon={createBinding(bat, "battery_icon_name").as(
            (iconName) => Gio.ThemedIcon.new(iconName)
          )}
        />
        <label
          label={createBinding(bat, "percentage").as(
            (p) => `${Math.floor(p * 100)}%`,
          )}
        />
      </box>
    </button>
  );
}