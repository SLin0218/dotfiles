#!/usr/bin/env python

# https://upower.freedesktop.org/docs/Device.html

# state
# 0: Unknown
# 1: Charging
# 2: Discharging
# 3: Empty
# 4: Fully charged
# 5: Pending charge
# 6: Pending discharge

import dbus
import dbus.mainloop.glib
from gi.repository import GLib

def on_properties_changed(interface_name, changed_properties, invalidated_properties):
    if 'Percentage' in changed_properties:
        print("Properties changed:")
        print(f"Percentage: {changed_properties['Percentage']}")
    elif 'State' in changed_properties:
        print("Properties changed:")
        print(f"State: {changed_properties['State']}")

def send_notify():
    pass

# 设置 GLib 主循环
mainloop = dbus.mainloop.glib.DBusGMainLoop()

# 创建与系统总线的连接
bus = dbus.SystemBus(mainloop=mainloop)

# 监听信号
bus.add_signal_receiver(on_properties_changed,
                         dbus_interface='org.freedesktop.DBus.Properties',
                         signal_name='PropertiesChanged',
                         path='/org/freedesktop/UPower/devices/battery_BAT0')
loop = GLib.MainLoop()
loop.run()
