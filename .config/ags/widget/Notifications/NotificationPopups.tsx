import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Notifd from "gi://AstalNotifd"
import Notification from "./Notification"
import GLib from "gi://GLib"
import { createState, For } from "gnim"


export default function NotificationPopups(gdkmonitor: Gdk.Monitor): Astal.Window {
  const { TOP, RIGHT } = Astal.WindowAnchor;
  const [notifications, setNotifications] = createState<number[]>([])
  const notifd = Notifd.get_default()

  notifd.connect("notified", (_, id) => {
    setNotifications([...notifications(), Number(id)])
  });

  function deleteNotification(id: number) {
    setNotifications(notifications().filter((id_) => id_ !== id))
  }

  notifd.connect("resolved", (_, id) => {
    deleteNotification(Number(id))
  })

  let hideTimeout: GLib.Source | null = null
  return <window
    namespace={"notifications-popup"}
    application={app}
    visible={notifications.as((n) => n.length !== 0)}
    margin={10}
    gdkmonitor={gdkmonitor}
    anchor={TOP | RIGHT}
  >
    <box
      spacing={6}
      orientation={Gtk.Orientation.VERTICAL}
    >
      <For each={notifications}>
        {(id) => <Notification
          n={notifd.get_notification(id)!}
          onHover={() => {
            hideTimeout?.destroy();
            hideTimeout = null;
          }}
          onHoverLost={() => {
            hideTimeout = setTimeout(() => {
              deleteNotification(id);
              hideTimeout?.destroy();
              hideTimeout = null;
            }, 5000);
          }}
          $={(self) => {
            hideTimeout = setTimeout(() => {
              deleteNotification(id);
              hideTimeout?.destroy();
              hideTimeout = null;
            }, 5000);
          }}
        />}
      </For>
    </box>
  </window> as Astal.Window
}