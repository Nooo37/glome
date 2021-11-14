#!/bin/sh

# small script to check whether the window under the cursor
# implements the appmenu or gtk menubar interface
# and print the relevant info

# get window id of the window under the mouse
rawid=$(xdotool getmouselocation --shell | grep WINDOW)
id=${rawid#"WINDOW="}

# check for appmenu interface
gdbus call --session -d "com.canonical.AppMenu.Registrar" -o "/com/canonical/AppMenu/Registrar" -m "com.canonical.AppMenu.Registrar.GetMenuForWindow" "$id"

# check for gtk interface
xprop -id "$id" -notype _GTK_UNIQUE_BUS_NAME
xprop -id "$id" -notype _GTK_MENUBAR_OBJECT_PATH

echo "ID: $id"
