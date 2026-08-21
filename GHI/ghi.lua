GHI_Version = GetAddOnMetadata("GHI", "Version");

-- Vanilla/TurtleWoW modifier-key helper used by GHI item controls.
function GHI_IsModifierKeyDown()
	if type(IsModifierKeyDown) == "function" then return IsModifierKeyDown(); end
	local shift = type(IsShiftKeyDown) == "function" and IsShiftKeyDown();
	local ctrl = type(IsControlKeyDown) == "function" and IsControlKeyDown();
	local alt = type(IsAltKeyDown) == "function" and IsAltKeyDown();
	return (shift and true) or (ctrl and true) or (alt and true) or false;
end



local function GHI_EnsureSavedTables()
	if not(type(GHI_ContainerData) == "table") then GHI_ContainerData = {{}}; end
	if not(type(GHI_ItemData) == "table") then GHI_ItemData = {}; end
	if not(type(GHI_CooldownData) == "table") then GHI_CooldownData = {}; end
	if not(type(GHI_MiscData) == "table") then GHI_MiscData = {}; end
	if not(type(GHI_ActionBarData) == "table") then GHI_ActionBarData = {}; end
	if not(type(GHI_ChatData) == "table") then GHI_ChatData = {}; end
	if not(type(GHI_EquipmentDisplayData) == "table") then GHI_EquipmentDisplayData = {}; end
end

GHI_EnsureSavedTables();
GHI_PName = UnitName("player");

function GHI_OnLoad()
	
	
	this:RegisterEvent("ADDON_LOADED");
	this:RegisterEvent("VARIABLES_LOADED"); 
	
	this:RegisterEvent("PLAYER_ENTERING_WORLD");	
	this:RegisterEvent("TIME_PLAYED_MSG");
	this:RegisterEvent("SPELLS_CHANGED");
	this:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE");
	this:RegisterEvent("CHAT_MSG_ADDON");
	
	
	-- UNIT_ENTERING_VEHICLE	
	--UNIT_EXITED_VEHICLE
	
	SlashCmdList["GHI"] = GHI_ChatCommand;
	SLASH_GHI1 = "/GHI";
	
	local Old_Script = WorldFrame:GetScript("OnUpdate");
	WorldFrame:SetScript("OnUpdate", function() if Old_Script then Old_Script(); end GHI_OnWF(); end);
	--GHI_Orig_WorldFrame_OnUpdate = WorldFrame_OnUpdate;
	--WorldFrame_OnUpdate = GHI_WorldFrame_OnUpdate;

	--GHI_Orig_WorldFrame_OnUpdate = WorldFrame:GetScript("OnUpdate");
	---WorldFrame:SetScript("OnUpdate", GHI_WorldFrame_OnUpdate);
	
	tinsert(UISpecialFrames,"GHIContainerFrame1");
	tinsert(UISpecialFrames,"GHIContainerFrame2");
	tinsert(UISpecialFrames,"GHIContainerFrame3");
	
	GHI_ContainerHookings();
	GHI_ItemLinkHookings();
	GHI_CommunicationHookings();
	GHI_TradeHookings();
	GHI_BuffHookings();
	if GHI_ActionbarHookings then GHI_ActionbarHookings(); end;
	GHI_ChatLogHookings(); --]]
end

GHI_GivenDisabledMessage = false;
GHI_GivenEnabledMessage = false;
GHI_StartedPlayedTime = nil;
GHI_Reload = true;
GHI_DoDebug = true;

local events = {};
function GHI_RegEvent(event,func)
	if not(type(events[event])=="table") then
		events[event] = {};
		GHI_MF:RegisterEvent(event);
	end
	table.insert(events[event],func);
end

function GHI_OnEvent()
	
	
	--[[if GHI_MiscData["disabled"] == true then
		if GHI_GivenDisabledMessage == false then
			GHI_GivenDisabledMessage = true;
			GHI_GivenEnabledMessage = false;
			GHI_Message("GHI is disabed by admin.");
		end
		if not(event=="CHAT_MSG_ADDON" and arg1 == "GHI_EnableGHI") then
			return
		end
	else
		if GHI_GivenEnabledMessage == false then
			GHI_GivenDisabledMessage = false;
			GHI_GivenEnabledMessage = true;
			GHI_Message("GHI is enabled by admin.");
		end
	end--]]
	
	
	
	if(event=="ADDON_LOADED" and arg1=="GHI") then
		GHI_ClearLocked();
		GHI_EffectHookings();
		GHI_Message(GHI_LOADED);
	elseif(event=="CHAT_MSG_ADDON" and  arg3=="WHISPER") then
	
		--GHI_RecieveData(arg1,arg2,arg4);
	elseif(event=="PLAYER_AURAS_CHANGED") then
		-- Legacy GHI buff-frame integration was replaced by GHU_BuffDisplay.
		-- Keep this branch harmless if another module registers the event.
		if GHU_BuffFrame_Update then GHU_BuffFrame_Update(); end;
	elseif(event=="PLAYER_TARGET_CHANGED") then
		GHI_CheckTarget();
	elseif(event=="SPELLS_CHANGED") then
		GHI_Reload = false;
	elseif(event=="CHAT_MSG_CHANNEL_NOTICE") then
		-- Turtle/1.12: recheck the current zone General channel when channel
		-- membership changes.  Do not invoke a dummy area-effect broadcast.
		if GHI_EnsureAreaChannel then GHI_EnsureAreaChannel(false); end;
	elseif(event=="PLAYER_ENTERING_WORLD") then
		if GHI_EnsureAreaChannel then GHI_EnsureAreaChannel(false); end;
		
		GHI_HideUnusedActionbars();
		
		if GHI_StartedPlayedTime == nil then 
			RequestTimePlayed();
		end
	elseif(event=="TIME_PLAYED_MSG") then 
		if GHI_StartedPlayedTime == nil then
			GHI_StartedPlayedTime = GetTime() - arg1;	
		end
	elseif(event=="VARIABLES_LOADED") then
		GHI_EnsureSavedTables();
		
		GHI_BPIconMove(GHI_MiscData["BackpackPos"]);
		GHI_CheckOfficialData();
		GHI_CompOnAddonsLoaded();
		GHI_ClearItemCatche();
		GHI_ReloadDone();
		GHI_VariabledLoaded = true;
		
		if not(GHI_MiscData["DisableBuffs"] == true) then
			--GHI_EnableBuffHookings();
		end
		
		if GHI_MiscData["block_std_emote"] == nil then GHI_MiscData["block_std_emote"] = true end
		
		--[[local bag,slot = GHI_FindItem("GHP Alpha Test_100");
		if bag and slot then
			GHI_UseItem(bag,slot);
		end--]]
	elseif event == "CHAT_MSG_ADDON" then
		if GHI5_OnAddonMessage then GHI5_OnAddonMessage(arg1,arg2,arg3,arg4); end
	end

	if OnTradeEvent then OnTradeEvent(); end
	
	if type(events[event]) == "table" then
		for _,func in pairs(events[event]) do
			func();                     
		end
	end
end

function GHI_ChatCommand(msg)
	local a,b =  strsplit(" ",msg);
	if strlower(a)=="reload" then
		GHI_ReloadUI();
	elseif strlower(a) == "ping" then
		GHI_SendPing(b);
	elseif strlower(a) == "channel" then
		if GHI_EnsureAreaChannel then GHI_EnsureAreaChannel(true); end;
	else
		GHI_ToggleBackpack();
	end
end

function GHI_Message(msg)
	local info = ChatTypeInfo["LOOT"];
	DEFAULT_CHAT_FRAME:AddMessage(msg, info.r, info.g, info.b, info.id);
end

function GHI_Debug(msg,num)
	if GHI_DoDebug ==true then
		if num == 2 then
			DEFAULT_CHAT_FRAME:AddMessage(msg,0.5,0.1,0.9,0);
		else
			GHI_Message(msg);
		end
	end
end

-- ============================ Timers ============================
GHI_LastWF = 0;
GHI_Count = 0;
GHI_Count2 = 0;

--[[
function WorldFrame_OnUpdate(self, elapsed)
	GHI_OnWF();
	GHI_Orig_WorldFrame_OnUpdate(self, elapsed);
end ]]

function GHI_OnWF()
	local diff = time() - GHI_LastWF;
	GHI_Count = GHI_Count+1;
	GHI_LastWF = time();
	if diff > 0 then
		-- GHI_Message(GHI_Count);
		GHI_Count = 0;
		GHI_EachSec();
		GHI_Count2 = GHI_Count2 + 1;
		if mod(GHI_Count2,10) == 0 then
			GHI_EachTenSec()
		end
		if GHI_Count2 >= 60 then
			GHI_EachMin();
			GHI_Count2 = 0;
		end
	end
	GHI_EachFrame();
end

local OldAA = 0;
function GHI_EachFrame()
	local x, y = GetCursorPosition();
	
	local s = GHI_CursorIcon:GetEffectiveScale();
	x, y = x/s, y/s;
	
	GHI_CursorIcon:SetPoint("TOPLEFT","UIParent","BOTTOMLEFT", (x ), (y ));  --   * 1.25 ?
	
	
	a = GHI_ItemTextFrameScrollFrame:GetVerticalScrollRange();
	if not(a == OldAA) then
		if GHI_IconsInPage.state then
			--GHI_Message(GHI_IconsInPage.state);
			if(GHI_IconsInPage.state > 0) then
				if GHI_IconsInPage.buffer then
					GHI_RecieveLineCalculationBuffer(GHI_IconsInPage.state);
				else
					GHI_RecieveLineCalculation(GHI_IconsInPage.state);
				end
			end
		end
		
		
	end
	OldAA = a;
	
	GHI_AfterHyberlink()
end


function GHI_EachSec()
	GHI_CheckTimeoutedMsg()
	
	
	GHI_SendBufferData();
	GHI_InThisSec = 0;
	GHI_OutThisSec = 0;
	
	GHI_RunActionsInQueue()
	GHI_LastInc = {}
	
	
	
	GHI_DeleteDurationWatchlistItems()
	GHI_CheckUpdateWatcher();
	
	GHI_CheckTarget()
end

function GHI_EachTenSec()
	GHI_MessageErrorsExpected_B = GHI_MessageErrorsExpected_A;
	GHI_MessageErrorsExpected_A = {};
	
end

function GHI_EachMin()
	GHI_UpdateDurationWatchlist();
	GHI_SpamCountReset();
end


function GHI_ConvertToNum(str)
	local num = tonumber(str)
	if num then
		if tostring(num) == str then
			return num;
		end
	end
	return str;
end

function GHI_CheckOfficialData()
	--[[
	if not(type(GHI_OfficialItemData) == "table") then
		GHI_OfficialItemData = GHI_RawOfficialItemData;
	elseif not(GHI_OfficialItemData["version"]) then
		GHI_OfficialItemData = GHI_RawOfficialItemData;
	elseif not(tonumber(GHI_OfficialItemData["version"])) then
		GHI_OfficialItemData = GHI_RawOfficialItemData;
	elseif GHI_RawOfficialItemData["version"] > GHI_OfficialItemData["version"] then
		GHI_OfficialItemData = GHI_RawOfficialItemData;
	else
	
	end
	if not(GHD_AddSharedArray == nil) then
		GHD_AddSharedArray("GHI_OfficialItemData");
	end
	
	if not(GHI_MiscData["BetaManualCreated"] == true) and GHI_CountItem(1) == 0 then
		local bag,slot = GHI_GetFreeSpace();
		--GHI_Message("Found "..bag..", "..slot);
		--GHI_PlaceCopiedItem(bag,slot,1,1)
		local info = {};
		info.ID = 1;
		info.amount = 1;
		--GHI_SetContainerInfo(bag,slot,info)
		GHI_MiscData["BetaManualCreated"] = true;
		GHI_Message(GHI_MANUAL_CREATED);
	end --]]
end

function btype(b)
	if b == true then
		return "true";
	elseif b == false then
		return "false";
	else
		return type(b);
	end
end



function GHI_ChatLogHookings()
	local i = 1;

	while(getglobal("ChatFrame"..i)) do
		local f = getglobal("ChatFrame"..i);
		f.Orig_AddMessage = f.AddMessage;
		f.AddMessage = GHI_AddMessage;--getglobal("GHI_AddMessage"..i);
		
		i = i+1;
	end
	
end

GHI_MessageLog = {};
function GHI_AddMessage(f,msg,r,g,b,id)
	
	
	f:Orig_AddMessage(msg,r,g,b,id)
	local name = f:GetName();
	if not(type(GHI_MessageLog[name])=="table")then GHI_MessageLog[name] ={}; end
	GHI_MessageLog[name][f:GetCurrentLine()]={}
	GHI_MessageLog[name][f:GetCurrentLine()].msg =msg;
	GHI_MessageLog[name][f:GetCurrentLine()].r = r;
	GHI_MessageLog[name][f:GetCurrentLine()].g = g;
	GHI_MessageLog[name][f:GetCurrentLine()].b = b;
	GHI_MessageLog[name][f:GetCurrentLine()].id = id;
	GHI_MessageLog[name].lastLine = f:GetCurrentLine();
	

end

function GHI_ReloadUI()
	
	GHI_ChatData = GHI_MessageLog;
	ReloadUI();
end

function GHI_ReloadDone()
	if type(GHI_ChatData) == "table" then
		for index,value in pairs(GHI_ChatData) do 
			if type(value) == "table" then
				local f = getglobal(index);
				local i = value.lastLine;
				if type(i)=="number" then
					i=i+1;
					for d = 1,128 do
						
						if i >= 128 then i = 0; end
						local data = value[i];
						if type(data) == "table" then
							f:AddMessage(data.msg,data.r,data.g,data.b,data.id);
						end
						i =i +1;
					end
				end
			end
		end
		GHI_ChatData = nil;
	end
end


function GHI_ColorString(s,r,g,b)
	if not(s) or s=="" then return ""; end;
	if not(r) or not(g) or not(b) then return ""; end;
	return "|CFF"..string.format("%.2x",r*255) .. string.format("%.2x",g*255) .. string.format("%.2x",b*255)..s.."|r";

end

---	temp
GHI_Spacing = "    ";

function GHI_SpMessage(msg,spaces)
	
	if not(msg == nil or (type(msg) == "table")) then
		
		local space = "";
		if not(spaces == nil) then
			for i = 1,spaces do
				space = space..GHI_Spacing
			end
		end
		
		DEFAULT_CHAT_FRAME:AddMessage(space..msg, 1, 0.2, 0.0);
	end
end


function GHI_PrintArray(ArrayName)
	local Array
	if type(ArrayName) == "table" then
		Array = ArrayName;
	else
		Array = getglobal(ArrayName);
	end
	if not(type(Array) == "table") then return end;
	if type(ArrayName) == "string" then
		GHI_SpMessage("Printing "..(ArrayName));	
	else
		GHI_SpMessage("Printing "..( "unknown"));
	end
	for index1,value1 in pairs(Array) do 
		
		if type(value1) == "table" then
			if type(index1)=="number" then
				GHI_SpMessage("["..index1.."] {",0);
			else
				GHI_SpMessage("[\""..index1.."\"] {",0);
			end
			for index2,value2 in pairs(value1) do 
				
				if type(value2) == "table" then
					if type(index2)=="number" then
						GHI_SpMessage("["..index2.."] {",0);
					else
						GHI_SpMessage("[\""..index2.."\"] {",0);
					end
					for index3,value3 in pairs(value2) do 
						if type(value3) == "table" then
							GHI_SpMessage("["..index3.."] {",2);
							for index4,value4 in pairs(value3) do 
								if type(value4) == "table" then
									GHI_SpMessage("["..index4.."] {",3);
									for index5,value5 in pairs(value4) do 
										if type(value5) == "table" then
											GHI_SpMessage("["..index5.."] {",4);
											for index6,value6 in pairs(value5) do 
												if type(value6) == "table" then
													GHI_Message("More than 6 arrays");
												elseif type(value6) == "number" or type(value6) == "string" then
													GHI_SpMessage("["..index6.."] = "..value6,5);
												else
													GHI_SpMessage("["..index6.."] = type: "..type(value6),5);
												end
												
											end
											GHI_SpMessage("}",4);
										elseif type(value5) == "number" or type(value5) == "string" then
											GHI_SpMessage("["..index5.."] = "..value5,4);
										else
											GHI_SpMessage("["..index5.."] = type: "..type(value5),4);
										end
										
									end
									GHI_SpMessage("}",3);
								elseif type(value4) == "number" or type(value4) == "string" then
									GHI_SpMessage("["..index4.."] = "..value4,3);
								else
									GHI_SpMessage("["..index4.."] = type: "..type(value4),3);
								end
								
							end
							GHI_SpMessage("}",2);
						elseif type(value3) == "number" or type(value3) == "string" then
							GHI_SpMessage("["..index3.."] = "..value3,2);
						else
							GHI_SpMessage("["..index3.."] = type: "..type(value3),2);
						end
						
					end
					GHI_SpMessage("}",1);
				elseif type(value2) == "number" or type(value2) == "string" then
					GHI_SpMessage("["..index2.."] = "..value2,1);
				else
					GHI_SpMessage("["..index2.."] = type: "..type(value2),1);
				end
			end
			GHI_SpMessage("}",0);
		elseif type(value1) == "number" or type(value1) == "string" then
			GHI_SpMessage("["..index1.."] = "..value1,0);
		else
			GHI_SpMessage("["..index1.."] = type: "..type(value1),0);
		end
	end
	
	
	
end


function Get(array,...)
	if not(type(array)=="table") then return array end
	for _,index in pairs(arg) do
		array = array[index];
		if not(type(array)=="table") then
			break;
		end
	end
	return array;
end

function Set(array,...) -- last argument is the value to set as.
	for i,index in pairs(arg) do
		
		if not(type(array[index]) == "table") then
			assert(array[index]==nil or i==(table.getn(arg)-1),"Set error. Value "..index.." is already written as "..type(array[index]));
			array[index] = {};
		end
		
		if i == table.getn(arg)-1 then 
			array[index] = (arg)[i+1];
			break;
		else
			array = array[index]
		end
	end
	
end

