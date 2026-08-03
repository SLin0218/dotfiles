import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import Battery from "./items/Battery";
import Tray from "./items/Tray";
import Volume from "./items/Volume";
import Clock from "./items/Clock";
import Workspaces from "./items/Workspaces";
import Window from "./items/Window";
import Network from "./items/Network";
import Brightness from "./items/Brightness";
import NotificationBar from "./items/NotificationBar";

function Start() {
  return (
    <box
      $type="start"
      halign={Gtk.Align.START}
    >
      <Workspaces />
      <Window />
    </box>
  );
}


function End() {
  return (
    <box
      $type="end"
      halign={Gtk.Align.START}
    >
      <Tray />
      <Brightness />
      <Volume />
      <Battery />
      <Network />
      <Clock />
      <NotificationBar />
    </box>
  );
}



export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      layer={Astal.Layer.BOTTOM}
      name="bar"
      class="Bar"
      namespace="bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
      $={(self) => {
        self.set_default_size(1, 1);
      }}
    >
      <centerbox cssName="centerbox">
        <Start />
        <End />
      </centerbox>
    </window>
  )
}
