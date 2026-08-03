import { Gtk } from "ags/gtk4"
import { createBinding, For } from "ags"
import Tray from "gi://AstalTray?version=0.1"

export default function TrayPanelButton() {
  const tray = Tray.get_default();
  const trayItems = createBinding(tray, "items")

  return (
    <box spacing={4} cssClasses={["tray_style"]}>
      <For each={trayItems}>
        {(item) => {
          const popover = Gtk.PopoverMenu.new_from_model(item.menuModel);
          return (
            <menubutton
              {...{
                popover,
                $: (self: any) => {
                  popover.insert_action_group("dbusmenu", item.actionGroup);
                  const actionGroupHandler = item.connect("notify::action-group", () => {
                    if (item.actionGroup) {
                      popover.insert_action_group("dbusmenu", item.actionGroup);
                    }
                  });
                  self.connect("destroy", () => {
                    item.disconnect(actionGroupHandler);
                  });
                },
                tooltipText: createBinding(item, "tooltipMarkup"),
              } as any}
            >
              <image gicon={createBinding(item, "gicon")} />
            </menubutton>
          );
        }}
      </For>
    </box>
  );
}