import { Gtk, Gdk } from "ags/gtk4";
import { createBinding, With, Accessor } from "ags";
import AstalHyprland from "gi://AstalHyprland";
import Pango from "gi://Pango?version=1.0";
import { readFile, monitorFile } from "ags/file";
import { exec } from "ags/process";
import Gio from "gi://Gio?version=2.0";
import GLib from "gi://GLib?version=2.0";

const specialNames = new Map<string, string>();

function readIcons(file: string) {
  const lines = readFile(file).split("\n");
  let iconName;
  let className;
  for (const line of lines) {
    if (line.startsWith("StartupWMClass=")) {
      className = line.split("=")[1];
    }
    if (line.startsWith("Icon=")) {
      iconName = line.split("=")[1];
    }
    if (className && iconName) {
      specialNames.set(className, iconName);
      break;
    }
  }
}

const applicationDirs = ["/usr/share/applications/", `${GLib.get_home_dir()}/.local/share/applications/`];
for (const applicationDir of applicationDirs) {
  const content = exec(`ls ${applicationDir}`);
  for (const f of content.split("\n")) {
    readIcons(`${applicationDir}${f}`)
  }

  monitorFile(applicationDir, (file: string, event: Gio.FileMonitorEvent) => {
    if (event !== Gio.FileMonitorEvent.DELETED) {
      readIcons(file);
    }
  })
}




function lookUpIcon(iconName: string | null | undefined): string {
  // 添加空值检查
  if (!iconName) {
    return "application-x-executable";
  }

  const display = Gdk.Display.get_default();
  if (!display) {
    console.error("No display found");
    return "application-x-executable";
  }
  const iconTheme = Gtk.IconTheme.get_for_display(display);
  if (iconTheme.has_icon(iconName)) {
    return iconName;
  }

  if (specialNames.has(iconName)) {
    return specialNames.get(iconName)!;
  }

  // 如果找不到图标，返回一个默认图标
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
        if (lookUpIconName.apply(String).endsWith("svg")) {
          return <image
            file={lookUpIconName}
            pixelSize={size}
          />
        } else {
          return <image
            iconName={lookUpIconName}
            pixelSize={size}
          />
        }
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
                <label maxWidthChars={50} ellipsize={Pango.EllipsizeMode.END} label={createBinding(client, "title").as(String)} />
              </box>
            )
          )}
        </With>
      </button>
    </revealer >
  );
}