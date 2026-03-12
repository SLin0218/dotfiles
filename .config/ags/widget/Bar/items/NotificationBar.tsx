import app from "ags/gtk4/app";
import AstalNotifd from "gi://AstalNotifd";
import { createBinding } from "ags";

export default function NotificationBar() {
  const notifd = AstalNotifd.get_default();

  return (
    <button
      onClicked={
        () => app.toggle_window("notification-window")
      }>
      <image iconName={
        createBinding(notifd, "notifications")
          .as((n: any) => n.length > 0
            ? "preferences-system-notifications-symbolic"
            : "notifications-disabled-symbolic")} />
    </button>
  );
}