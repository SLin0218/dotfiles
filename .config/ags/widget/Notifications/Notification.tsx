import { Gtk } from "ags/gtk4";
import Adw from "gi://Adw?version=1";
import Pango from "gi://Pango";
import AstalNotifd from "gi://AstalNotifd";
import GLib from "gi://GLib?version=2.0";
import { createState } from "gnim";

const time = (time: number, format = "%H:%M:%S") =>
  GLib.DateTime.new_from_unix_local(time).format(format);

const isIcon = (icon: string) => {
  const iconTheme = new Gtk.IconTheme();
  return iconTheme.has_icon(icon);
};

const fileExists = (path: string) => GLib.file_test(path, GLib.FileTest.EXISTS);

const urgency = (n: AstalNotifd.Notification) => {
  const { LOW, NORMAL, CRITICAL } = AstalNotifd.Urgency;

  switch (n.urgency) {
    case LOW:
      return "low";
    case CRITICAL:
      return "critical";
    case NORMAL:
    default:
      return "normal";
  }
};

const [hover, setHover] = createState(false)

export default function Notification({
  n,
  showActions = true,
  $,
  onHover,
  onHoverLost,
}: {
  n: AstalNotifd.Notification;
  showActions?: boolean;
  $?(self: Gtk.Box): void;
  onHoverLost?(self: Gtk.Box): void;
  onHover?(self: Gtk.Box): void;
}) {
  return (
    <Adw.Clamp maximumSize={400} cssClasses={["notification-container"]} >
      <box
        name={n.id.toString()}
        $={(self) => {
          $?.(self);
          const motion = new Gtk.EventControllerMotion();
          motion.connect("enter", () => onHover?.(self));
          motion.connect("leave", () => onHoverLost?.(self));
          self.add_controller(motion);
        }}
        hexpand={false}
        vexpand={false}
      >
        <box orientation={Gtk.Orientation.VERTICAL}
          $={(self) => {
            const motion = new Gtk.EventControllerMotion();
            motion.connect("enter", () => setHover(true));
            motion.connect("leave", () => setHover(false));
            self.add_controller(motion);
          }}
        >
          <box cssClasses={["header"]}>
            <image
              cssClasses={["app-icon"]}
              iconName={n.appIcon || "preferences-system-notifications-symbolic"}
            />
            <label
              cssClasses={["app-name"]}
              halign={Gtk.Align.START}
              label={n.appName || "Unknown"}
            />
            <label
              cssClasses={["time"]}
              hexpand
              halign={Gtk.Align.END}
              label={time(n.time)!}
            />
            <button onClicked={() => n.dismiss()}>
              <image iconName={"window-close-symbolic"} />
            </button>
          </box>
          <Gtk.Separator visible orientation={Gtk.Orientation.HORIZONTAL} />
          <box cssClasses={["content"]} spacing={10} >
            {(() => {
              if (n.image && fileExists(n.image)) {
                return (
                  <box valign={Gtk.Align.START} cssClasses={["image"]}>
                    <image file={n.image} overflow={Gtk.Overflow.HIDDEN} iconSize={Gtk.IconSize.LARGE}
                      halign={Gtk.Align.CENTER}
                      valign={Gtk.Align.CENTER}
                    />
                  </box>
                );
              } else if (n.image && isIcon(n.image)) {
                return (
                  <box cssClasses={["image"]} valign={Gtk.Align.START}>
                    <image
                      iconName={n.image}
                      iconSize={Gtk.IconSize.LARGE}
                      halign={Gtk.Align.CENTER}
                      valign={Gtk.Align.CENTER}
                    />
                  </box>
                );
              } else if (n.appIcon) {
                return (
                  <box cssClasses={["image"]} valign={Gtk.Align.START}>
                    <image
                      file={n.appIcon}
                      overflow={Gtk.Overflow.HIDDEN}
                      iconSize={Gtk.IconSize.LARGE}
                      halign={Gtk.Align.CENTER}
                      valign={Gtk.Align.CENTER}
                    />
                  </box>
                );
              } else if (n.desktopEntry) {
                return (
                  <box cssClasses={["image"]} valign={Gtk.Align.START}>
                    <image
                      iconName={n.desktopEntry}
                      overflow={Gtk.Overflow.HIDDEN}
                      iconSize={Gtk.IconSize.LARGE}
                      halign={Gtk.Align.CENTER}
                      valign={Gtk.Align.CENTER}
                    />
                  </box>
                )
              }
              return null;
            })()}
            <box orientation={Gtk.Orientation.VERTICAL}>
              <label
                cssClasses={["summary"]}
                halign={Gtk.Align.START}
                xalign={0}
                label={n.summary}
                ellipsize={Pango.EllipsizeMode.END}
              />
              {n.body && (
                <revealer
                  visible={n.body != " "}
                  revealChild={n.body != " "}>
                  <label
                    cssClasses={["body"]}
                    useMarkup
                    wrap
                    wrapMode={Pango.WrapMode.CHAR}
                    halign={Gtk.Align.FILL}
                    justify={Gtk.Justification.FILL}
                    xalign={0}
                    label={n.body}
                  />
                </revealer>
              )}
            </box>
          </box>
          <revealer revealChild={hover} transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN} transitionDuration={300}>
            {showActions && n.get_actions().length > 0 && (
              <box cssClasses={["actions"]} spacing={6}>
                {n.get_actions().map(({ label, id }) => (
                  <button hexpand onClicked={() => n.invoke(id)}>
                    <label label={label} halign={Gtk.Align.CENTER} hexpand />
                  </button>
                ))}
              </box>
            )}
          </revealer>
        </box>
      </box>
    </Adw.Clamp>
  )
}