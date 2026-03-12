import { Gtk, Gdk } from "ags/gtk4";
import app from "ags/gtk4/app";
import AstalNotifd from "gi://AstalNotifd";
import PopupWindow from "../../common/PopupWindow";
import Notification from "../Notifications/Notification";
import { createBinding, For } from "gnim";

export const WINDOW_NAME = "notification-window";
const notifd = AstalNotifd.get_default();

function NotifsScrolledWindow() {
  return (
    <Gtk.ScrolledWindow vexpand cssClasses={["scroll"]}>
      <box hexpand={false} vexpand={false} spacing={8} orientation={Gtk.Orientation.VERTICAL}>
        <For each={createBinding(notifd, "notifications").as(notifs => notifs.sort((a, b) => Number(b.id) - Number(a.id)))}>
          {
            (n: any) =>
              <revealer revealChild={true} transitionDuration={300} transitionType={Gtk.RevealerTransitionType.CROSSFADE}>
                <Notification n={notifd.get_notification(Number(n.id))!} showActions={false} />
              </revealer>
          }
        </For>
        <box
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.CENTER}
          cssClasses={["not-found"]}
          orientation={Gtk.Orientation.VERTICAL}
          vexpand
          visible={createBinding(notifd, "notifications").as((n) => n.length === 0)}
          spacing={6}
        >
          <image
            iconName="notifications-disabled-symbolic"
            pixelSize={50}
          />
          <label label="Your inbox is empty" cssClasses={["labelSmallBold"]} />
        </box>
      </box>
    </Gtk.ScrolledWindow>
  );
}

function ClearButton() {
  return (
    <button
      cssClasses={["clear"]}
      halign={Gtk.Align.CENTER}
      onClicked={() => {
        notifd.notifications.forEach((n) => n.dismiss());
        app.toggle_window(WINDOW_NAME);
      }}
      sensitive={createBinding(notifd, "notifications").as((n) => n.length > 0)}
    >
      <box spacing={6}>
        <image iconName={"user-trash-full-symbolic"} />
      </box>
    </button>
  );
}

export default function NotificationWindow(_gdkmonitor: Gdk.Monitor) {
  return (
    <PopupWindow
      name={WINDOW_NAME}
      namespace={WINDOW_NAME}
      layout="right"
      margin={10}
    >
      <box
        cssClasses={["notifications-container"]}
        orientation={Gtk.Orientation.VERTICAL}
        vexpand={false}
        hexpand={false}
      >
        <box cssClasses={["window-header"]}>
          <label label="Notifications" />
          <box hexpand />
          <ClearButton />
        </box>
        <Gtk.Separator />
        <NotifsScrolledWindow />
      </box>
    </PopupWindow>
  );
}