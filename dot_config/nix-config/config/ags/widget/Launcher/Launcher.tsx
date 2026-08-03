import { Astal, Gtk, Gdk } from "ags/gtk4";
import app from "ags/gtk4/app";
import Apps from "gi://AstalApps";
import Hyprland from "gi://AstalHyprland"
import { createState, With, Accessor } from "ags";
import { execAsync } from "ags/process";
import GLib from "gi://GLib";
import Pango from "gi://Pango?version=1.0";

const [launcherMode, setLauncherMode] = createState<"app" | "cliphist">("app");

// Cliphist Support
type ClipItem = {
  id: string;
  content: string;
  isImage: boolean;
};

async function fetchCliphist(): Promise<ClipItem[]> {
  try {
    // 过滤掉不可见的 Null 字符（\000），因为底层 GJS 解析 C-String 时遇到 Null 字符会直接截断后面的所有数据
    const list = await execAsync('bash -c "cliphist -preview-width=40 list"');
    return list.split("\n").filter(Boolean).map(line => {
      const match = line.match(/^(\d+)\s+(.*)$/);
      if (match) {
        const id = match[1];
        let content = match[2];
        if (content.length < 3) {
          return null;
        }
        const isImage = content.includes("[[ binary data");
        if (isImage) {
          const imgMatch = content.match(/\[\[ binary data ([\d.]+\s*[a-zA-Z]+)\s+[a-zA-Z]+\s+(\d+x\d+)\s*\]\]/);
          if (imgMatch) {
            content = `[ Image ${imgMatch[2]} ${imgMatch[1]} ]`;
          } else {
            content = content.replace(/\[\[ binary data (.*) \]\]/, "[ Image $1 ]");
          }
        }
        return { id, content, isImage };
      }
      return null;
    }).filter(Boolean) as ClipItem[];
  } catch (e) {
    console.error(e);
    return [];
  }
}

function CliphistItem({
  clip,
  onClick,
  selectedIndex,
  index,
  focusSearch
}: {
  clip: ClipItem;
  onClick: () => void;
  selectedIndex: Accessor<number>;
  index: number;
  focusSearch?: () => void;
}) {
  const selected = selectedIndex.as((s) => s === index);

  return (
    <button
      cssClasses={selected.as((s) => (s ? ["app-item", "selected"] : ["app-item"]))}
      onClicked={onClick}
      $={(self) => {
        selectedIndex.subscribe(() => {
          if (selectedIndex.peek() === index) {
            GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
              self.grab_focus();
              if (focusSearch) focusSearch();
              return GLib.SOURCE_REMOVE;
            });
          }
        });
      }}
    >
      <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
        <label
          cssClasses={["app-name"]}
          label={clip.isImage ? clip.content : clip.content.substring(0, 100).replace(/\n/g, " ")}
          xalign={0}
          ellipsize={Pango.EllipsizeMode.END}
        />
      </box>
    </button>
  );
}

function CliphistScrollList({
  list,
  selectedIndex,
  onHide,
  focusSearch
}: {
  list: Accessor<Array<ClipItem>>,
  selectedIndex: Accessor<number>,
  onHide: () => void,
  focusSearch?: () => void,
}) {
  return (
    <scrolledwindow
      cssClasses={["app-list"]}
      hscrollbarPolicy={Gtk.PolicyType.NEVER}
      vscrollbarPolicy={Gtk.PolicyType.EXTERNAL}
      vexpand
      $={(self) => {
        self.set_size_request(300, -1);
      }}
    >
      <box orientation={Gtk.Orientation.VERTICAL}>
        <With value={list}>
          {(items: ClipItem[]) => (
            <box orientation={Gtk.Orientation.VERTICAL}>
              {items.map((item: ClipItem, index: number) => (
                <CliphistItem
                  clip={item}
                  selectedIndex={selectedIndex}
                  index={index}
                  focusSearch={focusSearch}
                  onClick={() => {
                    onHide();
                    execAsync(`bash -c "cliphist decode ${item.id} | wl-copy"`).catch(err => {
                      console.error("Failed to copy", err);
                    });
                  }}
                />
              ))}
            </box>
          )}
        </With>
      </box>
    </scrolledwindow>
  );
}

function AppItem({
  app,
  onClick,
  selectedIndex,
  index,
  focusSearch
}: {
  app: Apps.Application;
  onClick: () => void;
  selectedIndex: Accessor<number>;
  index: number;
  focusSearch?: () => void;
}) {
  const selected = selectedIndex.as((s) => s === index);

  return (
    <button
      cssClasses={selected.as((s) => (s ? ["app-item", "selected"] : ["app-item"]))}
      onClicked={onClick}
      $={(self) => {
        selectedIndex.subscribe(() => {
          if (selectedIndex.peek() === index) {
            GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
              // 通过 grab_focus 触发 ScrolledWindow 的自动滚动
              self.grab_focus();
              // 立即将焦点还给输入框，确保用户可以继续键入
              if (focusSearch) focusSearch();
              return GLib.SOURCE_REMOVE;
            });
          }
        });
      }}
    >
      <box>
        <image
          cssClasses={["app-icon"]}
          iconName={app.icon_name || "application-x-executable"}
          pixelSize={48}
        />
        <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
          <label
            cssClasses={["app-name"]}
            label={app.name}
            xalign={0}
            ellipsize={Pango.EllipsizeMode.END}
          />
          {app.description && (
            <label
              cssClasses={["app-description"]}
              label={app.description}
              xalign={0}
              ellipsize={Pango.EllipsizeMode.END}
            />
          )}
        </box>
      </box>
    </button>
  );
}

function ScrollList({
  list,
  selectedIndex,
  onHide,
  focusSearch
}: {
  list: Accessor<Array<Apps.Application>>,
  selectedIndex: Accessor<number>,
  onHide: () => void,
  focusSearch?: () => void,
}) {
  return (
    <scrolledwindow
      cssClasses={["app-list"]}
      hscrollbarPolicy={Gtk.PolicyType.NEVER}
      vscrollbarPolicy={Gtk.PolicyType.EXTERNAL}
      vexpand
    >
      <box orientation={Gtk.Orientation.VERTICAL}>
        <With value={list}>
          {(items) => (
            <box orientation={Gtk.Orientation.VERTICAL}>
              {items.map((item: Apps.Application, index: number) => (
                <AppItem
                  app={item}
                  selectedIndex={selectedIndex}
                  index={index}
                  focusSearch={focusSearch}
                  onClick={() => {
                    item.launch();
                    onHide();
                  }}
                />
              ))}
            </box>
          )}
        </With>
      </box>
    </scrolledwindow>
  );
}

export default function Launcher(gdkmonitor: Gdk.Monitor) {
  const apps = new Apps.Apps();
  const [text, setText] = createState("");
  const [list, setList] = createState(apps.fuzzy_query(""));
  const [selectedIndex, setSelectedIndex] = createState(0);

  const [clipList, setClipList] = createState<ClipItem[]>([]);
  const [clipSelectedIndex, setClipSelectedIndex] = createState(0);
  const [clipFiltered, setClipFiltered] = createState<ClipItem[]>([]);
  const [previewImage, setPreviewImage] = createState<string | null>(null);
  const [previewText, setPreviewText] = createState<string | null>(null);

  let previewTimeout: any = null;
  const loadPreviewFor = (index: number, filtered: ClipItem[]) => {
    if (previewTimeout !== null) {
      clearTimeout(previewTimeout);
      previewTimeout = null;
    }
    setPreviewImage(null);
    setPreviewText(""); // trigger Loading

    previewTimeout = setTimeout(() => {
      previewTimeout = null;
      const item = filtered[index];
      if (item && item.isImage) {
        const currentPath = `/tmp/cliphist-preview-${item.id}.png`;
        execAsync(`bash -c "cliphist decode ${item.id} > ${currentPath}"`).then(() => {
          setPreviewImage(currentPath);
        }).catch(() => {
          setPreviewImage(null);
        });
      } else if (item) {
        execAsync(`bash -c "cliphist decode ${item.id} | tr -d '\\000'"`).then((output) => {
          setPreviewText(output || " ");
        }).catch(() => {
          setPreviewText("Failed to decode cliphist item");
        });
      } else {
        setPreviewText("No content selected");
      }
    }, 150);
  };

  const refreshLaunchData = () => {
    const m = launcherMode.peek();
    setText(""); // 切换模式或打开时重置搜索
    if (m === "app") {
      apps.reload();
      setList(apps.fuzzy_query(""));
      setSelectedIndex(0);
    } else if (m === "cliphist") {
      fetchCliphist().then(items => {
        setClipList(items);
        setClipFiltered(items);
        setClipSelectedIndex(0);
        loadPreviewFor(0, items);
      });
    }
  };

  launcherMode.subscribe(() => {
    refreshLaunchData();
  });

  clipSelectedIndex.subscribe(() => {
    const mode = launcherMode.peek();
    if (mode !== "cliphist") return;
    loadPreviewFor(clipSelectedIndex.peek(), clipFiltered.peek());
  });

  const monitorId = app.get_monitors().indexOf(gdkmonitor);
  const winName = `launcher-${monitorId}`;

  let entryRef: any = null;
  const focusSearch = () => {
    if (entryRef) entryRef.grab_focus();
  };

  text.subscribe(() => {
    const val = text.peek();
    const mode = launcherMode.peek();
    if (mode === "app") {
      const results = apps.fuzzy_query(val);
      setList(results);
      setSelectedIndex(0);
    } else {
      const items = clipList.peek();
      const results = items.filter(item => item.content.toLowerCase().includes(val.toLowerCase()));
      setClipFiltered(results);
      setClipSelectedIndex(0);
      loadPreviewFor(0, results);
    }
  });

  const onHide = () => {
    setText("");
    setSelectedIndex(0);
    setClipSelectedIndex(0);
    setPreviewImage(null);
    setPreviewText(null);
    app.toggle_window(winName);
  };

  const launchSelected = () => {
    const currentList = list.peek();
    const index = selectedIndex.peek();
    if (currentList[index]) {
      currentList[index].launch();
      onHide();
    }
  };

  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

  return (
    <window
      name={winName}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={app}
      visible={false}
      $={(self) => {
        const keyController = new Gtk.EventControllerKey();
        keyController.connect("key-pressed", (controller, keyval) => {
          if (keyval === Gdk.KEY_Escape) {
            onHide();
            return true;
          }
          return false;
        });
        self.add_controller(keyController);

        self.connect("notify::visible", () => {
          if (self.visible) {
            refreshLaunchData();
          }
        });
      }}
    >
      <overlay>
        <button cssClasses={["button-padding"]} onClicked={onHide} hexpand vexpand />
        <box
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.CENTER}
          cssClasses={["launcher"]}
          orientation={Gtk.Orientation.VERTICAL}
        >
          <box cssClasses={["search-box"]}>
            <image iconName="system-search-symbolic" />
            <entry
              hexpand
              placeholderText="Search..."
              text={text}
              $={(self) => {
                self.connect("changed", () => setText(self.text));

                self.connect("activate", () => {
                  const isApp = launcherMode.peek() === "app";
                  const currentList = isApp ? list.peek() : clipFiltered.peek();
                  const index = isApp ? selectedIndex.peek() : clipSelectedIndex.peek();
                  if (currentList.length === 0) return;

                  if (isApp) {
                    launchSelected();
                  } else {
                    onHide();
                    const clipList = currentList as ClipItem[];
                    execAsync(`bash -c "cliphist decode ${clipList[index].id} | wl-copy"`).catch(console.error);
                  }
                });

                entryRef = self;
                const keyController = new Gtk.EventControllerKey();
                keyController.connect("key-pressed", (controller, keyval) => {
                  const isApp = launcherMode.peek() === "app";
                  const currentList = isApp ? list.peek() : clipFiltered.peek();
                  const index = isApp ? selectedIndex.peek() : clipSelectedIndex.peek();
                  const setIdx = isApp ? setSelectedIndex : setClipSelectedIndex;
                  if (currentList.length === 0) return false;

                  if (keyval === Gdk.KEY_Down) {
                    setIdx((index + 1) % currentList.length);
                    return true;
                  }

                  if (keyval === Gdk.KEY_Up) {
                    setIdx((index - 1 + currentList.length) % currentList.length);
                    return true;
                  }

                  return false;
                });
                self.add_controller(keyController);
              }}
            />
          </box>
          <With value={launcherMode}>
            {(mode) => (
              mode === "app" ? (
                <ScrollList
                  list={list}
                  selectedIndex={selectedIndex}
                  onHide={onHide}
                  focusSearch={focusSearch}
                />
              ) : (
                <box cssClasses={["cliphist-layout"]}>
                  <CliphistScrollList
                    list={clipFiltered}
                    selectedIndex={clipSelectedIndex}
                    onHide={onHide}
                    focusSearch={focusSearch}
                  />
                  <box cssClasses={["preview-panel"]} hexpand>
                    <With value={previewImage}>
                      {(img) => img ? (
                        <box
                          halign={Gtk.Align.FILL}
                          valign={Gtk.Align.FILL}
                          hexpand
                          vexpand
                          $={(self: any) => {
                            if (!self._cssProvider) {
                              self._cssProvider = new Gtk.CssProvider();
                              self.get_style_context().add_provider(self._cssProvider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                            }
                            self._cssProvider.load_from_string(`* { background-image: url("file://${img}"); background-size: contain; background-repeat: no-repeat; background-position: center; }`);
                          }}
                        />
                      ) : (
                        <box hexpand vexpand>
                          <With value={previewText}>
                            {(txt) => txt ? (
                              <scrolledwindow hexpand vexpand>
                                <label
                                  label={txt}
                                  halign={Gtk.Align.START}
                                  valign={Gtk.Align.START}
                                  wrap={true}
                                  wrapMode={Pango.WrapMode.WORD_CHAR}
                                  xalign={0}
                                  yalign={0}
                                  selectable={true}
                                  cssClasses={["preview-text"]}
                                />
                              </scrolledwindow>
                            ) : (
                              <label label="Loading..." halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} hexpand vexpand />
                            )}
                          </With>
                        </box>
                      )}
                    </With>
                  </box>
                </box>
              )
            )}
          </With>
        </box>
      </overlay>
    </window>
  );
}

export function toggleLauncher(mode: "app" | "cliphist" = "app") {
  const currentMode = launcherMode.peek();
  const hyprland = Hyprland.get_default();
  const monitor: Hyprland.Monitor | undefined = hyprland.get_monitors().find((monitor) => monitor.focused);

  if (monitor) {
    const winName = `launcher-${monitor.id}`;
    const win = app.get_window(winName);

    // 如果窗口处于打开状态，并且触发了不同的模式，则只刷新数据和切换模式，不要将其隐藏！
    if (win && win.visible && currentMode !== mode) {
      setLauncherMode(mode);
      return;
    }

    setLauncherMode(mode);
    app.toggle_window(winName);
  }
}
