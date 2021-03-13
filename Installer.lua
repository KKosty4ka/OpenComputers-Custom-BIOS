require("component").eeprom.set([[
    local handle, data, chunk = component.proxy(component.list("internet")()).request("https://raw.githubusercontent.com/KKosty4ka/OpenComputers-Custom-BIOS/master/BIOS.lua"), ""
    
    while true do
        chunk = handle.read(math.huge)
        if chunk then
            data = data .. chunk
        else
            break
        end
    end
 
    handle.close()
    load(data)()
]])
