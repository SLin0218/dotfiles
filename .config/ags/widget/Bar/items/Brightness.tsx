import { createBinding } from "gnim";
import Gio from "gi://Gio?version=2.0";
import BrightnessLib from "../../../libs/brightness";

export default function brightness() {
  const brightness = BrightnessLib.get_default()
  return (
    <button>
      <image gicon={createBinding(brightness, "iconNameScreen").as(
        (iconNameScreen) => Gio.ThemedIcon.new(iconNameScreen)
      )} />
    </button>
  )
}