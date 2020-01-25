local invoke = component.invoke
local cl = component.list
local cp = component.proxy
local unicode = unicode or utf8
local gpu = cp(cl("gpu")())

local function input()
    local output = ""
    local e, _, c, _ = computer.pullSignal()
    if e == "key_down" then
        if c == 13 then
            return output
        elseif c ~= 13 then
            output = output .. string.char(char)
        end
    end
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
	local w,h = gpu.getResolution()
	gpu.fill(1,1,w,h," ")
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


local function bootMenu()
    local counter = 1
    for address in cl("filesystem") do
        if (invoke(address, "exists", "/init.lua") and not invoke(address, "isDirectory", "init.lua")) then
            print(address)
        end
    end
end

local function menu()
    gpu.set(1, 1, "1 - Reboot")
    gpu.set(1, 2, "2 - Shutdown")
    gpu.set(1, 3, "3 - Boot menu")
    gpu.set(1, 4, "4 - BSoD")
    
    index = tonumber(input())
    
    if index == 1 then
        computer.shutdown(true)
    elseif index == 2 then
        computer.shutdown(false)
    elseif index == 3 then
        bootMenu()
    elseif index == 4 then
        error("BSoD", 0)
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
	end
	BootWithoutAddress()
	SetTextInTheMiddle(8,50,"No bootable device found! Press F12 to reboot")

	while true do
		local e,_,_,k = computer.pullSignal(0.5)
		if e=="key_down" and k==88 then
			break
		end
		computer.beep()
	end
	computer.shutdown(true) 
end
------------

HiMenu()
