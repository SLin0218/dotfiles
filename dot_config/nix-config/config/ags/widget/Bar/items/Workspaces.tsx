import { Gtk } from "ags/gtk4"
import AstalHyprland from "gi://AstalHyprland";
import { createBinding, createState } from "ags";

const ICON_NAME_SELECTED = "radio-checked-symbolic";
const ICON_NAME_UNSELECTED = "radio-symbolic";

function WorkspaceButton({ ws }: { ws: AstalHyprland.Workspace }) {
  const hyprland = AstalHyprland.get_default();
  const iconName = createBinding(hyprland, "focusedWorkspace").as(
    (fw) => (fw?.id === ws.id ? ICON_NAME_SELECTED : ICON_NAME_UNSELECTED)
  );
  const [classNames, setClassNames] = createState([""])
  function onClientChange() {
    setClassNames(hyprland.get_workspace(ws.id)?.clients.length > 0 ? ["focused"] : [""]);
  }
  onClientChange();
  hyprland.connect("client-added", onClientChange);
  hyprland.connect("client-removed", onClientChange);
  hyprland.connect("client-moved", onClientChange);

  return (
    <button
      cssClasses={classNames}
      valign={Gtk.Align.CENTER}
      halign={Gtk.Align.CENTER}
      onClicked={() => ws.focus()}
      iconName={iconName}
    />
  );
}

export default function Workspaces() {
  return (
    <box>
      {Array.from({ length: 10 }, (_, i) => i + 1).map((i) => (
        <WorkspaceButton ws={AstalHyprland.Workspace.dummy(i, null)} />
      ))}
    </box>
  );
}