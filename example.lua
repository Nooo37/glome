-- to have good looking tables in terminal https://github.com/jagt/pprint.lua
local pprint = require("pprint")
local glome = require("glome")

local function menutest(xid)
    local k = glome.appmenu.get_menu(xid, 0, -1)
    pprint(k)
    local id = 12 -- what to call, makes a split in Konsole
    glome.appmenu.call_event(xid, id)
end

local function gtktest(gtk_bus_name, gtk_obj_path)
    local k = glome.gtk.get_menu(gtk_bus_name, gtk_obj_path)
    pprint(k)
    local id = "unity.file-open-location" -- a GIMP specific action
    glome.gtk.call_event(id, gtk_bus_name, gtk_obj_path)
end

-- you can get the info that needs to be passed here with the get.sh script

menutest(52428807) -- takes window id
gtktest(":1.801", "/org/appmenu/gtk/window/0") -- takes gtk bus and object
