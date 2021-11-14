
## Registrar service

A registrar service is a simple dbus service that implements the interface `org.canonical.AppMenu.Registrar`. It essentially just manages a hashmap that maps from X window IDs to object paths. Thus it only has the following function exposed on dbus: RegisterWindow (add), UnregisterWindow (remove) and GetMenuForWindow (get). 

## Standards for exporting

### Appmenu interface

Works mainly for QT apps like VLC, Dolphin, Okular but apparently also IDEA apps and chromium based browsers.

The apps that use that interface to export their menus are the ones that register on the registrar service. To operate on their layout, you ask the registrar service for the object path and dbus name of the window in question (ie you pass the X window ID to the GetMenuForWindow function of the registrar dbus service). The object that you find on the returned object path and dbus name will hopefully have implemented the `com.canonical.dbusmenu` interface. With that interface you can get the menus layout, perfom actions from the menubars and check for changes in the menubar layout through a signal.

### GTK interface

Works mainly for GTK apps (duh) like GIMP but also Inkscape.

The apps that use that interface will check whether the registrar service is running but won't actually register anything (to my knowledge) on it as they don't implement the given interface. Instead they will only hide their own menubar when they see that a registrar service is running. To operate on their menus, you will have to check the X properties `_GTK_UNIQUE_BUS_NAME` and `_GTK_MENUBAR_OBJECT_PATH` which will hold the name and object path of the object you will operate on if they do export a menu (this is somewhat analogous to the info you got from the registrar service with the appmenu interface). The object you find at that location will hopefully have implemented two interfaces: `org.gtk.Menus` and `org.gtk.Actions`. You can use the Menu interface to get the menus layout and the Actions interface to perform actions from the menu.

## Links
- https://hellosystem.github.io/docs/developer/menu.html
