local dbp = require("dbus_proxy")
local GLib = require("lgi").GLib

--[[
The goal is to convert both menu interfaces to a more inefficient but more
easily hackable structure like this:
{
    { path = {"Menu1", "SubMenu", "SubSubMenu", "Item1"}, id = 69, ... },
    { path = {"Menu1", "AnotherSubMenu", "Item2"}, id = 420, ... },
    ...
}
Already done for appmenu (in the make_flat function), still has to be done for
the gtk interface
--]]

local M = {
    gtk = {},
    appmenu = {},
}

M.registrar = dbp.Proxy:new {
    bus = dbp.Bus.SESSION,
    name = "com.canonical.AppMenu.Registrar",
    interface = "com.canonical.AppMenu.Registrar",
    path = "/com/canonical/AppMenu/Registrar"
}

--[[

APPMENU interface specific functions

--]]

function M.appmenu.make_flat(rawt)
    local function shallow_copy(t)
        local res = {}
        for k,v in pairs(t) do
          res[k] = v
        end
        return res
    end

    local recursive_march, result_final
    recursive_march = function(t, path)
        local result = nil
        if type(t) == "table" then
            result = {}
            for idx, sub in ipairs(t) do
                if type(sub) == "number" then
                    result["id"] = sub
                elseif type(sub) == "table" and sub["label"] then
                    table.insert(path, sub["label"])
                    local result_intermediate = {}
                    for key, value in pairs(sub) do
                        result_intermediate[key] = value
                        result[key] = value
                    end
                    result_intermediate.path = path
                    result_intermediate.id = result.id
                    table.insert(result_final, result_intermediate)
                else
                    local path_copy = shallow_copy(path)
                    result[idx] = recursive_march(sub, path_copy)
                end
            end
        end
        return result
    end
    result_final = {}
    recursive_march(rawt, {})
    return result_final
end

function M.appmenu.get_menu_object(window_id)
    local menuobj, err = M.registrar:GetMenuForWindow(window_id)
    if err or not menuobj then
        print(err)
        return nil
    end
    local name = menuobj[1]
    local objpath = menuobj[2]

    local mymenu = dbp.Proxy:new {
        bus = dbp.Bus.SESSION,
        name = name,
        interface = "com.canonical.dbusmenu",
        path = objpath
    }
    return mymenu
end

function M.appmenu.get_raw_menu(window_id, root, depth)
    local mymenu = M.appmenu.get_menu_object(window_id)
    if not mymenu then return nil end
    return mymenu:GetLayout(root, depth, {})
end

function M.appmenu.get_menu(window_id, root, depth)
    local res = M.appmenu.get_raw_menu(window_id, root, depth)
    return M.appmenu.make_flat(res)
end

function M.appmenu.call_event(window_id, event_id)
    local mymenu = M.appmenu.get_menu_object(window_id)
    if not mymenu then return nil end
    local data = GLib.Variant("s", "muh data") -- FIXME
    local timestamp = os.time(os.date("!*t"))
    mymenu:Event(event_id, "clicked", data, timestamp)
    return true
end

--[[

GTK inteface specfic functions

--]]

local function get_number_array(n)
    local res = {}
    for i=1,n do
        table.insert(res, i)
    end
    return res
end

local number_array = get_number_array(1024)

function M.gtk.get_menu_object(gtk_bus_name, gtk_obj_path)
    return dbp.Proxy:new {
        bus = dbp.Bus.SESSION,
        name = gtk_bus_name,
        interface = "org.gtk.Menus",
        path = gtk_obj_path,
    }
end

function M.gtk.get_action_object(gtk_bus_name, gtk_obj_path)
    return dbp.Proxy:new {
        bus = dbp.Bus.SESSION,
        name = gtk_bus_name,
        interface = "org.gtk.Actions",
        path = gtk_obj_path,
    }
end

function M.gtk.get_raw_menu(gtk_bus_name, gtk_obj_path)
    local mymenu = M.gtk.get_menu_object(gtk_bus_name, gtk_obj_path)
    if not mymenu then return nil end
    return mymenu:Start(number_array)
end

function M.gtk.call_event(action, gtk_bus_name, gtk_obj_path)
    local myaction = M.gtk.get_action_object(gtk_bus_name, gtk_obj_path)
    if not myaction then return nil end
    action = action:gsub("^unity.", "")
    myaction:Activate(action, {}, {})
end


return M
