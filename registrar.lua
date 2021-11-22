local lgi = require("lgi")
local Gio = lgi.Gio
local GLib = lgi.GLib
local GObject = lgi.GObject

local M = {}

M.interface_info = Gio.DBusInterfaceInfo {
    name = "com.canonical.AppMenu.Registrar",
    methods = {
        Gio.DBusMethodInfo {
            name = "RegisterWindow",
            in_args = {
                Gio.DBusArgInfo { name = "windowId", signature = "u"},
                Gio.DBusArgInfo { name = "menuObjectPath", signature = "o"},
            },
        },
        Gio.DBusMethodInfo {
            name = "UnregisterWindow",
            in_args = {
                Gio.DBusArgInfo { name = "windowId", signature = "u"},
            },
        },
        Gio.DBusMethodInfo {
            name = "GetMenuForWindow",
            in_args = {
                Gio.DBusArgInfo { name = "windowId", signature = "u"},
            },
            out_args = {
                Gio.DBusArgInfo { name = "service", signature = "s"},
                Gio.DBusArgInfo { name = "menuObjectPath", signature = "o"},
            },
        },
    }
}

-- maps from window id to tables such as { ":1.42", "/test" }
M.data = {}

local function handle_method_call(_, sender, _, _, method, parameters, invocation)
    local window_id = parameters[1]
    local obj_path = parameters[2]
    print("CALL: ", sender, window_id, obj_path) -- debug purposes
    if method == "RegisterWindow" then
        if type(window_id) == "number" and type(obj_path) == "string" then
            M.data[window_id] = { sender, obj_path }
        end
        invocation:return_value(GLib.Variant("()"))
    elseif method == "UnregisterWindow" then
        if type(window_id) == "number" then
            M.data[window_id] = nil
        end
        invocation:return_value(GLib.Variant("()"))
    elseif method == "GetMenuForWindow" then
        local entry = M.data[window_id]
        if entry then
            invocation:return_value(GLib.Variant("(so)", entry))
        else -- invalid arguments, what to do?
            invocation:return_value(GLib.Variant("(so)", {"", "/"}))
        end
    end
end

local function on_bus_acquire(conn, _)
    conn:register_object(
        "/com/canonical/AppMenu/Registrar",
        M.interface_info,
        GObject.Closure(handle_method_call)
    )
end

local function on_name_acquired(_, _)
    M.name_acquired = true
end

local function on_name_lost(_, _)
    M.name_acquired = false
end

function M.start()
    Gio.bus_own_name(
        Gio.BusType.SESSION,
        "com.canonical.AppMenu.Registrar",
        Gio.BusNameOwnerFlags.NONE,
        GObject.Closure(on_bus_acquire),
        GObject.Closure(on_name_acquired),
        GObject.Closure(on_name_lost)
    )
end

-- test
local mainloop = GLib.MainLoop(nil, nil)
M.start()
mainloop:run()
