local invoke = component.invoke
local cl = component.list
local cp = component.proxy
local unicode = unicode or utf8
local gpu = cp(cl("gpu")())
local internet = cp(cl("internet")())
local eeprom = cp(cl("eeprom")())

local function input(x, y)
    local output = ""
    local running = true
    
    while running do
        local e, _, c, _ = computer.pullSignal()
        if e == "key_down" then
            if c == 13 then
                running = false
            elseif c == 88 then
            else
                output = output .. string.char(c)
            end
            
            gpu.set(x, y, ">" .. output)
        end
    end
    
    return output
end

computer.getBootAddress = function()
	local MemoryController = invoke(cl("eeprom")(), "getData")
	return string.sub(MemoryController, 1, 36) --первый адрес в контроллере (1-36 символ)
end

computer.setBootAddress = function(address)
	if string.len(address) == 36 then
		local MemoryController = invoke(cl("eeprom")(), "getData")
		local newData = address .. string.sub(MemoryController, 37, string.len(MemoryController)) --перезапись первых 36 символов
		return invoke(cl("eeprom")(), "setData", newData)
	end
end

local function fillBackground()
	local w, h = gpu.getResolution()
	gpu.fill(1, 1, w, h, " ")
end

local function SetTextInTheMiddle(y,space,text,correct)
	if correct then
		gpu.set(space/2-unicode.len(text)/2+correct,y,text)
	else
		gpu.set(space/2-unicode.len(text)/2,y,text)
	end
end

local function BootWithoutAddress()
    for address in cl("filesystem") do
        if cp(address).getLabel() ~= "tmpfs" then
            if (invoke(address, "exists", "/init.lua") and not invoke(address, "isDirectory", "init.lua")) then
                computer.setBootAddress(address)

				local handle, err
				handle, err = invoke(address, "open", "/init.lua")

				if handle then
					local bootCode = ""
					repeat
						local chunk = invoke(address, "read", handle, math.huge)
						bootCode = bootCode .. (chunk or "")
					until not chunk
					invoke(address, "close", handle)
                    
                    SetTextInTheMiddle(8,50,"Loading OpenOS...")
                    load(bootCode)()
                end
            elseif (invoke(address, "exists", "/OS.lua") and not invoke(address, "isDirectory", "OS.lua")) then
                computer.setBootAddress(address)

				local handle, err
				handle, err = invoke(address, "open", "/OS.lua")

				if handle then
					local bootCode = ""
					repeat
						local chunk = invoke(address, "read", handle, math.huge)
						bootCode = bootCode .. (chunk or "")
					until not chunk
					invoke(address, "close", handle)
                    
                    SetTextInTheMiddle(8,50,"Loading MineOS...")
                    load(bootCode)()
                end
            elseif (invoke(address, "exists", "/c_OS.lua") and not invoke(address, "isDirectory", "c_OS.lua")) then
                computer.setBootAddress(address)

				local handle, err
				handle, err = invoke(address, "open", "/c_OS.lua")

				if handle then
					local bootCode = ""
					repeat
						local chunk = invoke(address, "read", handle, math.huge)
						bootCode = bootCode .. (chunk or "")
					until not chunk
					invoke(address, "close", handle)
                    
                    SetTextInTheMiddle(8,50,"Loading MineOS with \"Custom MineOS\" patch...")
                    load(bootCode)()
                end
            end
        end
    end
end

local function BootWithAddress(address)
    if (invoke(address, "exists", "/init.lua") and not invoke(address, "isDirectory", "init.lua")) then
        computer.setBootAddress(address)

		local handle, err
		handle, err = invoke(address, "open", "/init.lua")

		if handle then
			local bootCode = ""
			repeat
				local chunk = invoke(address, "read", handle, math.huge)
				bootCode = bootCode .. (chunk or "")
			until not chunk
			invoke(address, "close", handle)
                    
            SetTextInTheMiddle(8,50,"Loading OpenOS...")
            load(bootCode)()
        end
    elseif (invoke(address, "exists", "/OS.lua") and not invoke(address, "isDirectory", "OS.lua")) then
        computer.setBootAddress(address)

		local handle, err
		handle, err = invoke(address, "open", "/OS.lua")

		if handle then
			local bootCode = ""
			repeat
				local chunk = invoke(address, "read", handle, math.huge)
				bootCode = bootCode .. (chunk or "")
			until not chunk
			invoke(address, "close", handle)
                    
            SetTextInTheMiddle(8,50,"Loading MineOS...")
            load(bootCode)()
        end
    elseif (invoke(address, "exists", "/c_OS.lua") and not invoke(address, "isDirectory", "c_OS.lua")) then
        computer.setBootAddress(address)

		local handle, err
		handle, err = invoke(address, "open", "/c_OS.lua")

		if handle then
			local bootCode = ""
			repeat
				local chunk = invoke(address, "read", handle, math.huge)
				bootCode = bootCode .. (chunk or "")
			until not chunk
			invoke(address, "close", handle)
                    
            SetTextInTheMiddle(8,50,"Loading MineOS with \"Custom MineOS\" patch...")
            load(bootCode)()
        end
    else
        error("Computer startup error: OS not found!", 0)
    end
end

local function httpBoot()
    gpu.setBackground(0)
	fillBackground()
    
    gpu.set(1, 1, "Enter URL:")
    local url = input(1, 2)
    
    local handle, code, result, reason = internet.request(url), ""
    if handle then
		while true do
            result, reason = handle.read(math.huge)
            if result then
                code = code .. result
            else
                break
            end
		end
        SetTextInTheMiddle(8, 50, "Loading from URL...")
        load(code)()
    end
end

local function bootMenu()
    gpu.setBackground(0)
	fillBackground()
    
    gpu.set(1, 1, "1 - Http boot")
    local counter = 2
    local systems = {}
    for address in cl("filesystem") do
        if (invoke(address, "exists", "/init.lua") and not invoke(address, "isDirectory", "init.lua")) or (invoke(address, "exists", "/OS.lua") and not invoke(address, "isDirectory", "OS.lua")) or (invoke(address, "exists", "/c_OS.lua") and not invoke(address, "isDirectory", "c_OS.lua")) then
            gpu.set(1, counter, counter .. " - ♦[" .. cp(address).getLabel() .. "]" .. address)
        else
            gpu.set(1, counter, counter .. " - [" .. cp(address).getLabel() .. "]" .. address)
        end
        systems[counter] = address
        counter = counter + 1
    end
    
    local index = input(1, counter + 2)
    if index == "1" then
        httpBoot()
    else
        BootWithAddress(systems[tonumber(index)])
    end
end

local function menu()
    gpu.setBackground(0)
	fillBackground()

    gpu.set(1, 1, "1 - Reboot")
    gpu.set(1, 2, "2 - Shutdown")
    gpu.set(1, 3, "3 - Boot menu")
    gpu.set(1, 4, "4 - BSoD")
    gpu.set(1, 5, "5 - Flash EEPROM")
    
    local index = input(1, 7)

    if index == "1" then
        computer.shutdown(true)
    elseif index == "2" then
        computer.shutdown(false)
    elseif index == "3" then
        bootMenu()
    elseif index == "4" then
        error("", 0)
    elseif index == "5" then
        eeprom.set("")
    else
        menu()
    end
end


local function HiMenu()
	gpu.setResolution(50,16)
	gpu.setBackground(0)
	fillBackground()

	gpu.set(11,1,"KKosty4ka's BIOS")
	gpu.set(7,15,"Press F12 to enter the settings menu")
	gpu.set(8,16,"Press any key to skip this message")

	local goToMenu
	while true do
		local e,_,_,k = computer.pullSignal(5)
		if e ~= nil then
			if e=="key_down" then
				if k==88 then
					goToMenu = true
					break
				else
					break
				end
			end
		else
			break
		end
	end
	if goToMenu then
        computer.beep()
		menu()
	else
        BootWithoutAddress()
        gpu.setBackground(0)
        fillBackground()
        SetTextInTheMiddle(8,50,"No bootable device found!")
        
        while true do
            computer.beep()
        end 
    end
end
------------

HiMenu()
