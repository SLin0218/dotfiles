import { Gtk, Gdk } from "ags/gtk4";
import { createBinding, With, Accessor } from "ags";
import AstalHyprland from "gi://AstalHyprland";
import AstalApps from "gi://AstalApps";
import Pango from "gi://Pango?version=1.0";

const apps = new AstalApps.Apps();

function lookUpIcon(className: string | null | undefined): string {
  if (!className) return "application-x-executable";

  // 1. 尝试直接在图标主题中查找类名（有些应用图标名和类名一致）
  const display = Gdk.Display.get_default();
  if (display) {
    const iconTheme = Gtk.IconTheme.get_for_display(display);
    if (iconTheme.has_icon(className)) return className;
    if (iconTheme.has_icon(className.toLowerCase())) return className.toLowerCase();
  }

  // 2. 使用 AstalApps 查找对应 WMClass 的应用
  // AstalApps 会自动处理 .desktop 文件中的 StartupWMClass 和 Icon 字段
  const app = apps.fuzzy_query(className)?.[0];
  if (app && app.icon_name) {
    return app.icon_name;
  }

  return "application-x-executable";
}

const AppIcon = ({
  iconName,
  size = 16
}: {
  iconName: Accessor<string | null>,
  size?: number
}) => {
  return (
    <With value={iconName}>
      {() => {
        const lookUpIconName = iconName.as(lookUpIcon)
        return (
          <image
            iconName={lookUpIconName}
            pixelSize={size}
          />
        )
      }}
    </With>
  );
};

export default function Window() {
  const hypr = AstalHyprland.get_default();
  const focused = createBinding(hypr, "focusedClient");

  return (
    <revealer
      transitionType={Gtk.RevealerTransitionType.CROSSFADE}
      transitionDuration={300}
      revealChild={focused.as(Boolean)}
    >
      <button>
        <With value={focused}>
          {client => (
            client && (
              <box spacing={8}>
                <AppIcon iconName={createBinding(client, "class").as(String)} />
                <label
                  maxWidthChars={50}
                  ellipsize={Pango.EllipsizeMode.END}
                  label={createBinding(client, "title").as(String)}
                />
              </box>
            )
          )}
        </With>
      </button>
    </revealer >
  );
}
