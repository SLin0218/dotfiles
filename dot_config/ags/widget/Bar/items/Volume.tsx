import { createBinding } from "ags"
import Wp from "gi://AstalWp"

export default () => {
  const wp = Wp.get_default();
  const default_speaker = wp.audio.default_speaker;
  return (
    <button iconName={createBinding(default_speaker, "volume_icon")} />
  );
}