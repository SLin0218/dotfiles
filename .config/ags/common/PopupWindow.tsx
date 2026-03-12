import { Astal, Gtk, Gdk } from "ags/gtk4";
import app from "ags/gtk4/app"

function Padding({ winName }: { winName: string }) {
  return (
    <button
      cssClasses={["button-padding"]}
      canFocus={false}
      onClicked={() => app.toggle_window(winName)}
      hexpand
      vexpand
    />
  );
}

function Layout({
  children,
  name,
  position,
}: {
  children?: JSX.Element;
  name: string;
  position: string;
}) {
  switch (position) {
    case "top":
      return (
        <box orientation={Gtk.Orientation.VERTICAL}>
          {children}
          <Padding winName={name} />
        </box>
      );
    case "top_center":
      return (
        <box>
          <Padding winName={name} />
          <box orientation={Gtk.Orientation.VERTICAL} hexpand={false}>
            {children}
            <Padding winName={name} />
          </box>
          <Padding winName={name} />
        </box>
      );
    case "top_left":
      return (
        <box>
          <box orientation={Gtk.Orientation.VERTICAL} hexpand={false}>
            {children}
            <Padding winName={name} />
          </box>
          <Padding winName={name} />
        </box>
      );
    case "top_right":
      return (
        <box>
          <Padding winName={name} />
          <box orientation={Gtk.Orientation.VERTICAL} hexpand={false}>
            {children}
            <Padding winName={name} />
          </box>
        </box>
      );
    case "right":
      return (
        <box vexpand={false} hexpand={false}>
          <Padding winName={name} />
          {children}
        </box>
      );
    case "bottom":
      return (
        <box orientation={Gtk.Orientation.VERTICAL}>
          <Padding winName={name} />
          {children}
        </box>
      );
    case "bottom_center":
      return (
        <box>
          <Padding winName={name} />
          <box orientation={Gtk.Orientation.VERTICAL} hexpand={false}>
            <Padding winName={name} />
            {children}
          </box>
          <Padding winName={name} />
        </box>
      );
    case "bottom_left":
      return (
        <box>
          <box orientation={Gtk.Orientation.VERTICAL} hexpand={false}>
            <Padding winName={name} />
            {children}
          </box>
          <Padding winName={name} />
        </box>
      );
    case "bottom_right":
      return (
        <box>
          <Padding winName={name} />
          <box orientation={Gtk.Orientation.VERTICAL} hexpand={false}>
            <Padding winName={name} />
            {children}
          </box>
        </box>
      );
    //default to center
    default:
      return (
        <centerbox>
          <Padding winName={name} />
          <centerbox orientation={Gtk.Orientation.VERTICAL}>
            <Padding winName={name} />
            {children}
            <Padding winName={name} />
          </centerbox>
          <Padding winName={name} />
        </centerbox>
      );
  }
}

type WindowProps = Astal.Window.ConstructorProps;

type PopupWindowProps = Partial<Astal.Window.ConstructorProps> & {
  children: JSX.Element;
  layout?: string;
  name: string;
  $?: (self: Astal.Window) => void;
};

export default function PopupWindow({
  children,
  layout = "center",
  ...props
}: PopupWindowProps) {
  const { TOP, RIGHT, BOTTOM, LEFT } = Astal.WindowAnchor;
  return (
    <window
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={app}
      anchor={TOP | BOTTOM | RIGHT | LEFT}
      $={(self) => {
        const keyController = new Gtk.EventControllerKey();
        keyController.connect("key-pressed", (controller, keyval) => {
          if (keyval === Gdk.KEY_Escape) {
            app.toggle_window(props.name);
            return true;
          }
          return false;
        });
        self.add_controller(keyController);
        props.$?.(self);
      }}
      {...props}
    >
      <Layout name={props.name} position={layout}>
        {children}
      </Layout>
    </window>
  );
}
