#!/usr/bin/env python

import json
import sys
import dbus
import dbus.mainloop.glib
from gi.repository import GLib

def on_properties_changed(interface_name, changed_properties, invalidated_properties):
    if 'historyLength' in changed_properties:
        print(f"Percentage: {changed_properties['historyLength']}")
    count = changed_properties['historyLength']
    _alt = "notification" if int(count) > 0 else "none"
    data = {"text": count, "alt": _alt, "class": "notification"}
    print(json.dumps(data))
    sys.stdout.flush()

# 设置 GLib 主循环
dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
# mainloop = dbus.mainloop.glib.DBusGMainLoop()

# 创建与用户总线的连接
bus = dbus.SessionBus()

# 监听信号
bus.add_signal_receiver(on_properties_changed,
                         dbus_interface='org.freedesktop.DBus.Properties',
                         signal_name='PropertiesChanged',
                         path='/org/freedesktop/Notifications')

print('{"text":"","alt":"none","class":"notification"}')
sys.stdout.flush()

loop = GLib.MainLoop()
loop.run()
