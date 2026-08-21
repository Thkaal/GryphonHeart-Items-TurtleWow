

--  Pre difined information related to type.
local GHI_CursorPreDetails = {};
local temp;

temp = {};
temp.texture = "ITEM_CURSOR";
temp.includeOverlay = true;
temp.includeIcon = true;
temp.onCursorChange = function() 
	--GHI_Message(" if slot is locked then unlock");
	local Type,details = GHI_GetCursor();
	if details.ItemOrigFrame and details.ItemOrigFrame.number and details.ItemOrigBag then
		if type(GHI_ContainerData[details.ItemOrigBag][details.ItemOrigFrame.number]) == "table" then
			--GHR_Message("unlocking "..details.ItemOrigFrame.number)
			GHI_ContainerData[details.ItemOrigBag][details.ItemOrigFrame.number].locked = nil;
			GHI_UpdateContainers()
		end
	end
	GHI_ShowSlots(false);
	GHI_HideUnusedActionbars();
end;
GHI_CursorPreDetails["item"] = temp;

temp = {};
temp.texture = "ITEM_CURSOR";
temp.includeOverlay = true;
temp.includeIcon = true;
temp.onCursorChange = function() 
	
end;
GHI_CursorPreDetails["copied_item"] = temp;


temp = {};
temp.texture = "ITEM_CURSOR";
temp.includeOverlay = true;
temp.includeIcon = true;
temp.onCursorChange = function() 
	--GHI_Message(" if slot is locked then unlock");
	
	GHI_HideUnusedActionbars();
	GHI_ShowSlots(false);
end;
GHI_CursorPreDetails["item/ability"] = temp;


temp = {};
temp.texture = "CAST_CURSOR";
temp.includeOverlay = true;
temp.includeIcon = false;
temp.onCursorChange = function() GHI_EditItemButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up");  end;
GHI_CursorPreDetails["edit"] = temp;

temp = {};
temp.texture = "CAST_CURSOR";
temp.includeOverlay = true;
temp.includeIcon = false;
temp.onCursorChange = function() GHI_CopyItemButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up"); end;
GHI_CursorPreDetails["copy"] = temp;

temp = {};
temp.texture = "CAST_CURSOR";
temp.includeOverlay = true;
temp.includeIcon = false;
temp.onCursorChange = function() end;
GHI_CursorPreDetails["choose_item"] = temp;

GHI_CursorPreDetails["inspect"] = {
texture = "INSPECT_CURSOR",
includeOverlay = true,
includeIcon = false,
onCursorChange = function() GHI_InspectButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up");  end;
};



local GHI_CursorDetails = {};

--[[ GHI_SetCursor 
arg:
	Type - string. type of cursor contenst. "none","item", "edit" "copy" etc
	details -  Array. Details of the cursor contenst
returns:
	true if completed
	
Reserved keyword not useable in details:
	r-type :  The type name of cursor
	
]]
function GHI_SetCursor(Type,details)
	if not Type then return false; end
	Type = string.lower(Type);
	
	-- handle change from old
	local oldType = GHI_GetCursor();
	local oldPreDetails = GHI_CursorPreDetails[oldType];
	if not(oldType == "none") then
		local func = oldPreDetails.onCursorChange;
		if type(func) == "function" then
			func();
		end
	end
	
	
	
	GHI_CursorDetails = details;
	--GHI_Message("type: "..Type.." details: "..type(details));
	if not( type(GHI_CursorDetails) == "table") then
		GHI_CursorDetails = {};
		--GHI_Message("no details");
	end
	
	GHI_CursorDetails.r_type = Type;
	GHI_CursorDetails = GHI_CursorDetails;

	-- Keep the legacy cursor-state variable synchronized. Several original GHI
	-- toolbar buttons (Edit/Copy/Inspect/Export) still use this value to decide
	-- whether their mode is active. The newer virtual-cursor implementation had
	-- stopped updating it, leaving those controls in an inconsistent state.
	GHI_CurserType = Type;
	
	local preDetails = GHI_CursorPreDetails[Type];
	if not(type(preDetails) == "table") then
		preDetails = {};
	end
	
	--	cursor
	ClearCursor();
	-- Vanilla/TurtleWoW exposes a dedicated FrameXML helper for the inspect
	-- magnifying-glass cursor.  Using SetCursor("INSPECT_CURSOR") is unreliable
	-- on the 1.12 client, so use the native helper for this mode.
	if Type == "inspect" and type(ShowInspectCursor) == "function" then
		ShowInspectCursor();
	elseif preDetails.texture then
		SetCursor(preDetails.texture);
	else
		if type(ResetCursor) == "function" then
			ResetCursor();
		else
			SetCursor(nil);
		end
	end
	
	--	overlay
	if preDetails.includeOverlay then
		GHIClickOverlayer:Show();
	else
		GHIClickOverlayer:Hide();
	end
	
	--	icon
	if preDetails.includeIcon then
		GHI_CursorIcon:SetScale(0.8);
		if details then
			if details.iconTexture then
				GHI_CursorIconTexture:SetTexture(details.iconTexture);
			else
				GHI_CursorIconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
			end
		end
		GHI_CursorIcon:Show();
	else
		GHI_CursorIcon:Hide();	
	end
	
	--	Specific actions for some types
	if Type == "item" then
		GHI_ShowAllActionbars();
	
	end
	
	
	
	return true;
end

--[[	GHI_ResetCursor
arg:
	nil
returns:
	true
]]
function GHI_ResetCursor()
	local Type = GHI_GetCursor();
	if not(Type == "none") then
		GHI_SetCursor("none");
	end
	return true;
end

function GHI_GetCursor()
	if not(type(GHI_CursorDetails) == "table") then
		return "none",{};
	end
	local Type = GHI_CursorDetails.r_type;
	if not(Type) then
		return "none",{};
	end
	return Type, GHI_CursorDetails;
end


function GHI_GetCursorPreDetails(Type)
	return GHI_CursorDetails[Type];
end

function GHI_AddExternalPreDetails(Type,details)
	if not( type(details) == "table" and type(Type) == "string") then
		return false;
	end
	
	GHI_CursorPreDetails[Type] = details;
	return true;
end


-- TurtleWoW/Vanilla compatibility: GHI items use a virtual cursor rather than
-- Blizzard's native item cursor.  Native OnReceiveDrag handlers therefore do
-- not run when a GHI drag is released over an external UI element.  External
-- modules (mail, etc.) can register a drop handler here; GHI calls the handlers
-- from its own drag-stop path while the virtual cursor details are still live.
local GHI_ExternalCursorDropHandlers = {};

function GHI_RegisterExternalCursorDropHandler(name,func)
    if type(name) ~= "string" or type(func) ~= "function" then return false; end
    GHI_ExternalCursorDropHandlers[name] = func;
    return true;
end

function GHI_UnregisterExternalCursorDropHandler(name)
    if type(name) ~= "string" then return false; end
    GHI_ExternalCursorDropHandlers[name] = nil;
    return true;
end

function GHI_TryExternalCursorDrop()
    local cursorType,details = GHI_GetCursor();
    if cursorType == "none" then return false; end
    local name,func;
    for name,func in pairs(GHI_ExternalCursorDropHandlers) do
        if type(func) == "function" then
            local ok = func(cursorType,details);
            if ok == true then return true; end
        end
    end

    -- GHU loads before GHI because GHI depends on it.  If the mailbox tried to
    -- register its handler before this function existed, do not let load order
    -- make mail drops silently disappear: call the active mailbox directly.
    if type(GHU_Mail) == "table" and type(GHU_Mail.activeObject) == "table" and
       type(GHU_Mail.activeObject.TryExternalCursorDrop) == "function" then
        local ok = GHU_Mail.activeObject:TryExternalCursorDrop(cursorType,details);
        if ok == true then return true; end
    end
    return false;
end

function GHI_GiveFeedback(arg1,arg2,arg3)
	if not( type(GHI_CursorDetails) == "table") or not(type(GHI_CursorDetails.cursorFeedback) == "function") then
		return
	end
	return GHI_CursorDetails.cursorFeedback(arg1,arg2,arg3);
end

