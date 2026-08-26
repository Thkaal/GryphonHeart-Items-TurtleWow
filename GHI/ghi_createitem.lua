
--	==================================== Create item 	==================================== 
local userName = UnitName("player");
GHI_LastCreateID = 0;
function GHI_CreateItem(name,icon,quality,white1,white2,comment,amount,stackSize,copyable,rightClick,rightClicktext,editID,duration,durationWhenTrade,durationRealTime,editable,changeStack)  -- rightClick is an array

	
	local version = 1;
	local ID = GHI_GenerateID();
	
	if editID then
		ID = editID;
	end
	
	if not(icon) then 
		icon = "Interface\\Icons\\INV_Misc_QuestionMark";
	elseif icon == "" then
		icon = "Interface\\Icons\\INV_Misc_QuestionMark";
	end
	
	if amount == nil then amount = 1; end
	if stackSize == nil then stackSize = 1; end
	
	if type(rightClick) == "table" then
		--GHI_Message("editID: "..type(editID).." vesion: "..(rightClick.version or "nil"));
		if editID then
			rightClick.version = (rightClick.version or 0) + 1;
			local v1 = GHI_GetVersions(ID);
			version = v1 + 1;
		else
			rightClick.version = 1;
			version = 1;
		end
		
		-- go trough all scripts and make the scripts into one
		
		for i=1,table.getn(rightClick) do
			local action = rightClick[i];
			if type(action)=="table" then
				if action.Type == "script" then
					if type(action.code) == "table" and table.getn(action.code) > 1 then
						local c = "";
						local i1 = 1;
						while (type(action.code[i1])=="string") do
							c=c..action.code[i1];
							i1 = i1 + 1;
						end
						action.code = {c};
					end
				end
			end
			rightClick[i] = action;
		end
		
	else
		rightClicktext = "";
	end
	
	
	
	GHI_ItemData[ID] = {
		["name"] = name;
		["quality"] = quality;
		["icon"] = icon; --"Interface\\Icons\\INV_BannerPVP_01";
		["white1"] = white1;
		["white2"] = white2;
		["comment"] = comment;
		["creater"] = GHI_PName;
		["stackSize"] = stackSize;
		["rightClick"] = rightClick;
		["rightClicktext"] = rightClicktext;
		["locked"] = 0;
		["version"] = version;
		["copyable"] = copyable;
		["editable"] = editable;
	};
	--GHI_Message("Item created. Id: "..ID);
	
	
	
	local start_event = "created";
	local Type = "played_time";
	
	if durationWhenTrade == 1 then
		start_event = "traded";
	end
	if durationRealTime == 1 then
		Type = "real_time";
	end
	if duration and duration > 0 then
		SetDurationInfo(ID,duration,Type,start_event)
	end
	
	if editID then
		amount = 0;
		if type(changeStack) == "table" then
			GHI_ContainerData[changeStack[1]][changeStack[2]].ID = editID;
		end
		GHI_UpdateContainers();
	else
		--GHI_Message(duration,durationWhenTrade,durationRealTime
	end
	while amount > 0 do
		local freeBagpack,freeSlot = GHI_GetFreeSpace();
		if freeBagpack then
			GHI_ContainerData[freeBagpack][freeSlot] = {};
			GHI_ContainerData[freeBagpack][freeSlot].ID = ID;
			if amount > stackSize then
				GHI_ContainerData[freeBagpack][freeSlot].amount = stackSize;
			else
				GHI_ContainerData[freeBagpack][freeSlot].amount = amount; 
			end
			if  duration and duration > 0 and start_event == "created" then
				if Type == "played_time" then
					SetContainerDurationInfo(freeBagpack,freeSlot,(GetTime()-GHI_StartedPlayedTime)  +duration,nil);
				elseif 	Type == "real_time" then
					SetContainerDurationInfo(freeBagpack,freeSlot,GetTime()+duration,nil);
				end
			end
			
			GHI_MaintainMainBags();
			GHI_UpdateContainers();
			GHI_UpdateDurationWatchlist();
			amount = amount - stackSize;
		else 
			GHI_Message("No free bag space found");
			return;
		end
	end
end

function GHI_GetItemInfo(ID,returnTable)
	local name,icon,quality,white1,white2,comment,stackSize,creater,version,rightClick,rightClicktext;
	local info;
	
	if GHI_IsOfficialItem(ID) == true then
		if not(type(GHI_OfficialItemData[ID])=="table") then
			return nil,"Interface\\Icons\\INV_Misc_QuestionMark",nil;
		else
			info = GHI_OfficialItemData[ID];
		end
	else
		if not(type(GHI_ItemData[ID])=="table") then
			return nil,"Interface\\Icons\\INV_Misc_QuestionMark",nil;
		else
			info = GHI_ItemData[ID];
		end
	end
	if returnTable == true then 
		return info;
	end
	name = info.name;
	icon = info.icon;
	quality = info.quality;
	white1 = info.white1;
	white2 = info.white2;
	comment = info.comment;
	version = info.version;
	stackSize = info.stackSize;
	creater = info.creater;
	rightClick = info.rightClick;
	rightClicktext = info.rightClicktext;
	
	if white1 == nil then white1 = ""; end
	if white2 == nil then white2 = ""; end
	if comment == nil then comment = ""; end	
	
	if not(type(icon)=="string") then
		icon = "Interface\\Icons\\INV_Misc_QuestionMark";
	end
	if stackSize == nil then
		stackSize = 1;	
	elseif tonumber(stackSize) == nil then
		stackSize = 1;
	else
		stackSize = tonumber(stackSize);
	end
	return name,icon,quality,white1,white2,comment,stackSize,creater,version,rightClick,rightClicktext;
end

--[[	returns:
	rc info
	rc text

]]

function GHI_GetRightClickInfo(ID)
	local rightClick,rightClicktext;
	if GHI_IsOfficialItem(ID) == true then
		if not(type(GHI_OfficialItemData[ID])=="table") then
			return nil,nil;
		end
		rightClick = GHI_OfficialItemData[ID].rightClick;
		rightClicktext = GHI_OfficialItemData[ID].rightClicktext;

		return rightClick,rightClicktext;
	else
		if not(type(GHI_ItemData[ID])=="table") then
			return nil,nil;
		end
		rightClick = GHI_ItemData[ID].rightClick;
		rightClicktext = GHI_ItemData[ID].rightClicktext;

		return rightClick,rightClicktext;
	end
end

function GHI_SetRightClickInfo(ID,rc)
	if GHI_IsOfficialItem(ID) == true then
		return
	end
	if not(type(GHI_ItemData[ID])=="table") or not( type(rc) == "table" or type(rc) == nil) then
		return false;
	end
	
	if type(num) == "number" and num > 0 and type(GHI_ItemData[ID].rightClick) == "table" then
		GHI_ItemData[ID].rightClick[num] = rc;
		return true;
	else
		GHI_ItemData[ID].rightClick = rc;
		return true;
	end
end

function GHI_IsOfficialItem(ID)
	if not(tonumber(ID)) then return false end
	if not(tostring(tonumber(ID)) == tostring(ID)) then return false end
	
	if tonumber(ID) < 1000000 then  -- official item
		return true;
	else
		return false;
	end
end

function GHI_UpdateItemVersion(ID)
	if GHI_IsOfficialItem(ID) == true then
		return
	end
	if not(type(GHI_ItemData[ID])=="table") then
		return;
	end
	local a = GHI_ItemData[ID].version;
	if not(a) then
		a = 1;
	elseif not(tonumber(a)) then
		a = 1;
	else
		a = tonumber(a)+1;
	end
	GHI_ItemData[ID].version = a;
end

function GHI_UpdateRcVersion(ID)
	local rc = GHI_GetRightClickInfo(ID);
	if not(type(rc)=="table") then 
		return;
	end
	if rc.version == nil or tonumber(rc.version)==nil then
		rc.version = 1;
	else
		rc.version = rc.version + 1;
	end
	
	GHI_SetRightClickInfo(ID,rc)
end

function GHI_GetVersions(ID)
	if GHI_IsOfficialItem(ID) == true then
		return 0,0;
	end
	if not(type(GHI_ItemData[ID])=="table") then
		return -1,-1;
	end
	local a = GHI_ItemData[ID].version;
	if not(a) then
		a = 0;
	elseif not(tonumber(a)) then
		a = 1;
	else
		a = tonumber(a);
	end
	
	local rc = GHI_GetRightClickInfo(ID);
	if not(type(rc)=="table") then 
		return a,-1;
	end
	if rc.version == nil or tonumber(rc.version)==nil then
		return a,0;
	else
		return a,tonumber(rc.version);
	end
	
	return a,0;
end

function GHI_IsCopyable(ID)
	local c = true;
	if GHI_IsOfficialItem(ID) == true then
		c = false;
	else
		if (type(GHI_ItemData[ID])=="table") then
			c = GHI_ItemData[ID].copyable;
		end
	end
	return c;
end

function GHI_IsEditable(ID)
	if GHI_IsOfficialItem(ID) == true then
		return false;
	else
		if (type(GHI_ItemData[ID])=="table") then
			return GHI_ItemData[ID].editable;
		end
	end
	return false;
end

function GHI_ClearItemCatche()
	-- todo: fix books and fix scripts (see ghi_saveItem in dev version)
	
	for index,value in pairs(GHI_ItemData) do  
		local f = GHI_FindItem(index,false);
		if f == nil then
			GHI_ItemData[index] = nil;
		end
	end
	
	
end


--- ===============  Duration functions ================
function SetDurationInfo(ID,size,Type,start_event)
	if GHI_IsOfficialItem(ID) == true then
		return
	end
	if not(type(GHI_ItemData[ID])=="table") then
		return false;
	end
	GHI_ItemData[ID].duration_size = size;
	GHI_ItemData[ID].duration_Type = Type;
	GHI_ItemData[ID].duration_start_event = start_event;
	
	return true
end

function GetDurationInfo(ID) 
	if not(type(GHI_ItemData[ID])=="table") then
		return nil,nil,nil
	end
	local size = GHI_ItemData[ID].duration_size;
	local Type = GHI_ItemData[ID].duration_Type;
	local start_event = GHI_ItemData[ID].duration_start_event;

	return size,Type,start_event
end





--	Create item GUI functions
--[[
GHI_Quality = 1;
function GHI_QualityDD_Update()

	-- GHI_CreateItemsFrameQualityTextLabel:SetText("|CFF9D9D9D Poor");
	
	for i = 0,6 do
	
		info            = {};
		
		local text = getglobal("ITEM_QUALITY" .. i .. "_DESC");
		local color = ITEM_QUALITY_COLORS[i];
		
		
		info.text       = "|CFF" ..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255) .." ".. text.."|r";
		info.value      = i;
		info.func       = GHI_QualityDDClick;
		UIDropDownMenu_AddButton(info);
		--GHR_DDMText[c1] = info.text;
		--GHR_DDMIndex[c1] = i1;
		

		
		
	end	
	
	
end

function GHI_QualityDDClick()
	
	local color = ITEM_QUALITY_COLORS[this.value];
	GHI_CreateItemsFrameQualityTextLabel:SetText("|CFF" ..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255) .." "..getglobal("ITEM_QUALITY" ..this.value.. "_DESC").."|r"); 
	GHI_Quality = this.value;
end
	 
function GHI_QualityDD_OnClick() 
	
	ToggleDropDownMenu(1, nil, GHI_DropDownMenu, GHI_DropDownMenuButton, 0, 0);
	
end


--GHI_IconChoosenCategory = "Chestpiece";
GHI_IconCurrentTextue = {};
GHI_CreateItem_Texture = "Interface\\Icons\\INV_Misc_QuestionMark";

GHI_IconCatagory = 1;
GHI_IconSubcatagory = 1;
--GHI_CreateItemsFrameIconFrameCatagoryTextLabel:SetText(GHI_IconCategories[GHI_IconCatagory]);
function GHI_CatagoryDD_Update()

	-- GHI_CreateItemsFrameQualityTextLabel:SetText("|CFF9D9D9D Poor");
	
	for i = 1,table.getn(GHI_IconCategories) do
	
		info            = {};
		
		
		info.text       = GHI_IconCategories[i];
		info.value      = i;
		info.func       = GHI_CatagoryDDClick;
		UIDropDownMenu_AddButton(info);
		--GHR_DDMText[c1] = info.text;
		--GHR_DDMIndex[c1] = i1;
		

		
		
	end	
	
	
end

function GHI_CatagoryDDClick()
	
	GHI_IconCatagory = this.value;
	GHI_IconSubcatagory = 1;
	GHI_CreateItemsFrameIconFrameCatagoryTextLabel:SetText(GHI_IconCategories[this.value]);
	GHI_CreateItemsFrameIconFrameSubcatagoryTextLabel:SetText(GHI_IconSubcategories[GHI_IconCategories[this.value] ][GHI_IconSubcatagory]);
	
	GHI_IconScrollBar_Update();	
end
	 
function GHI_CatagoryDD_OnClick() 
	
	ToggleDropDownMenu(1, nil, GHI_DropDownMenu, GHI_DropDownMenuButton, 0, 0);
	
end

function GHI_SubcatagoryDD_Update()

	-- GHI_CreateItemsFrameQualityTextLabel:SetText("|CFF9D9D9D Poor");
	
	for i = 1,table.getn(GHI_IconSubcategories[GHI_IconCategories[GHI_IconCatagory] ]) do
	
		info            = {};
		
		
		info.text       = GHI_IconSubcategories[GHI_IconCategories[GHI_IconCatagory] ][i];
		info.value      = i;
		info.func       = GHI_SubcatagoryDDClick;
		UIDropDownMenu_AddButton(info);
		--GHR_DDMText[c1] = info.text;
		--GHR_DDMIndex[c1] = i1;
		
		
		
	end	
	
	
end

function GHI_SubcatagoryDDClick()
	
	GHI_IconSubcatagory = this.value;
	GHI_CreateItemsFrameIconFrameSubcatagoryTextLabel:SetText(GHI_IconSubcategories[GHI_IconCategories[GHI_IconCatagory] ][this.value]);
	
	
	GHI_IconScrollBar_Update();	
end
	
function GHI_SubcatagoryDD_OnClick() 
	
	ToggleDropDownMenu(1, nil, GHI_DropDownMenu, GHI_DropDownMenuButton, 0, 0);
	
end

function GHI_ClearCreateItem(parent)
	getglobal(parent.."Namebox"):SetText("");
	SetItemButtonTexture(getglobal(parent.."IconButton"),GHI_CreateItem_Texture);
	
	GHI_Quality = 1;
	local color = ITEM_QUALITY_COLORS[GHI_Quality];
	GHI_CreateItemsFrameQualityTextLabel:SetText("|CFF" ..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255) .." "..getglobal("ITEM_QUALITY" ..GHI_Quality.. "_DESC").."|r"); 
	
	
	getglobal(parent.."White1box"):SetText("");
	getglobal(parent.."White2box"):SetText("");
	getglobal(parent.."Commentbox"):SetText("");
	getglobal(parent.."Amountbox"):SetText(1);
	getglobal(parent.."StackSlider"):SetValue(1);
	
	getglobal(parent.."BuffDetailsbox"):SetText("");
	getglobal(parent.."BuffUsebox"):SetText("");
	getglobal(parent.."BuffNamebox"):SetText("");
	getglobal(parent.."BuffCDSlider"):SetValue(1);
	getglobal(parent.."BuffDurationSlider"):SetValue(1);
	getglobal(parent.."BuffCheck1"):SetChecked(1);
	getglobal(parent.."BuffCheck2"):SetChecked(0);
	getglobal(parent.."BuffCheck3"):SetChecked(0);
	SetItemButtonTexture(getglobal(parent.."BuffIconButton"),GHI_CreateItem_Texture);
	
	getglobal(parent.."BookUsebox"):SetText("");
	getglobal(parent.."BookTitlebox"):SetText("");
	
	getglobal(parent.."BagUsebox"):SetText("");
	getglobal(parent.."BagSizeSlider"):SetValue(4);
	GHI_TextureCatagory = 1;
	local TextureType = GHI_TextureTypes[GHI_TextureCatagory];
	GHI_CreateItemsFrameBagTextureDDTextLabel:SetText(TextureType);
	
	getglobal(parent.."ReputationUsebox"):SetText("");
	getglobal(parent.."ReputationCDSlider"):SetValue(1);
	GHI_FactionDDCurrent = 1;
	GHI_CreateItemsFrameReputationFactionDDTextLabel:SetText(GHI_FactionDDText[GHI_FactionDDCurrent]);
	getglobal(parent.."ReputationRepAmountbox"):SetText(1);
	getglobal(parent.."ReputationCheck2"):SetChecked(true);
	
	getglobal(parent.."ScriptUsebox"):SetText("");
	getglobal(parent.."ScriptCDSlider"):SetValue(1);	
	getglobal(parent.."ScriptCodeScrollText"):SetText("");
	getglobal(parent.."ScriptCheck2"):SetChecked(false);
	
end 

--]]
	
function GHI_StartCreateItem(Type,bag,slot)
	-- Type =  "create" or "edit"
	
	if Type == "create" then
		
		--[[
		GHI_ClearCreateItem("GHI_CreateItemsFrame");
		GHI_CreateItemsFrameTitleString:SetText("Create GHI Item");
		GHI_CreateItemsFrameOk:Show();
		GHI_CreateItemsFrameCancel:Show();
		GHI_CreateItemsFrame:Show();
		GHI_CreateItemsFrameEditButtons:Hide(); ]]
		
		local f = GHM_NewFrame(GHI_CreateItem_Menu);
		if f then
			f.ClearAll();
			f.edit = nil;
			f:Show();
		end
		
		
	elseif Type == "edit" then
		--[[
		GHI_ClearCreateItem("GHI_CreateItemsFrame");
				
		local a = GHI_InsertItemForEdit(bag,slot);
		if a == true then
			GHI_CreateItemsFrame:Show();
			GHI_CreateItemsFrameTitleString:SetText("Edit GHI Item");
		end]]
		local info = GHI_GetContainerInfo(bag,slot);
		local ID = info.ID;
		if GHI_IsOfficialItem(ID) == true then
			return
		end
		local name,icon,quality,white1,white2,comment,stackSize,creater,version,rightClick,rightClicktext,editable = GHI_GetItemInfo(ID);
		
		if not(rightClick) then rightClick={}; end
		
		--	to do: Get duratio and copyable info
		local duration,duration_type,start_event = GetDurationInfo(ID);
		local CD = rightClick.CD
		local consumed = rightClick.consumed;
		local copyable = GHI_IsCopyable(ID);
		if copyable == false or copyable == nil then copyable = 0 end;
		
		local editable = GHI_IsEditable(ID)
		
		local newID;
		if not(creater == UnitName("player")) then
			if editable then
				newID = GHI_GenerateID();
			else
				if name then		GHI_Message(name.." is not made by you."); end
				return nil;
			end
		end
		
		--	convert dynamic rc scripts
		if type(rightClick)=="table" then
			for i=1,table.getn(rightClick) do  
				if type(rightClick[i]) == "table" then 
					if rightClick[i]["dynamic_rc"] == true then
						
						if rightClick[i]["dynamic_rc_type"] then
							rightClick[i].Type = rightClick[i]["dynamic_rc_type"];
						end
					end
				end
			end
		end
		--
		
		local f = GHM_NewFrame(GHI_CreateItem_Menu);
		if f then
			f.ClearAll();
			
			f.ForceLabel("name",name);
			f.ForceLabel("quality",quality);
			f.ForceLabel("icon",icon);
			f.ForceLabel("white1",white1);
			f.ForceLabel("white2",white2);
			f.ForceLabel("quote",comment);
			f.ForceLabel("amount",amount);
			f.ForceLabel("stackSize",stackSize);
			f.ForceLabel("copyable",copyable);
			f.ForceLabel("editable",editable);

			f.ForceLabel("RCList",rightClick);
			f.ForceLabel("use",rightClicktext);
			f.ForceLabel("CD",CD);
			f.ForceLabel("consumed",consumed);
			f.edit = newID or ID;
			f.changeStack = nil;
			if newID then
				f.changeStack = {bag,slot}
			end
			
			if start_event == "traded" then 
				f.ForceLabel("durationWhenTrade",1);
			else
				f.ForceLabel("durationWhenTrade",0);
			end
			if duration_type == "real_time" then
				f.ForceLabel("durationRealTime",1);
			else
				f.ForceLabel("durationRealTime",0);
			end
			
			f.ForceLabel("duration",duration);
			
			
			f:Show();
		end
		
	end
end
	

--[[	
	
---	GUI api 		Unused
function GHI_IconScrollBar_Update()
	local lines; -- 1 through 5 of our window to scroll
	local category = tostring(GHI_IconSubcategories[ GHI_IconCategories[GHI_IconCatagory] ][GHI_IconSubcatagory]);
	
	local scrollFrame = getglobal("GHI_CreateItemsFrameIconFrameScrollBar");

	
	if catagory == "" then return; end
	
	lines = floor((table.getn(GHI_StockIcons[ category  ]) / 4)+0.5)-3;
	
	
	if lines == nil then return; end
	
	
	
	FauxScrollFrame_Update(scrollFrame,lines,1,16);
	
	local offset = FauxScrollFrame_GetOffset(scrollFrame);
	--GHI_Message("off: "..offset.." Showing from "..offset*4+1 .." to "..offset*4+16 .." out of "..table.getn(GHI_StockIcons[ "Solid" ]));
	
	
	for i=1,16 do 
		
		local frame = getglobal("GHI_PopupButton"..i);
		local texture = GHI_StockIcons[category][offset*4 + i];
		if texture == nil then
			SetItemButtonTexture(frame, "");
			GHI_IconCurrentTextue[i] = "";
		else
			SetItemButtonTexture(frame, "Interface\\Icons\\"..texture);
			GHI_IconCurrentTextue[i] = "Interface\\Icons\\"..texture;
		end
	end 
	
	
end

function GHI_IconButtonOnClick()
	local i = this:GetID();
	--local MenuFrame = getglobal(((this:GetParent()):GetParent()):GetName().."IconButton")
	
	local MenuFrame = (this:GetParent()).from;
	
	local texture = GHI_IconCurrentTextue[i];
	SetItemButtonTexture(MenuFrame,texture);
	
	--GHI_CreateItem_Texture = texture;
	
end 


GHI_RClickType = 1;
GHI_RClickTypes = {}
function GHI_RClickDD_Update()

	info            = {};
	info.text       = "None";
	info.value      = 1;
	GHI_RClickTypes[info.value] = info.text;
	info.func       = GHI_RClickDDClick;
	UIDropDownMenu_AddButton(info);	

	
	info            = {};
	info.text       = "Buff";
	info.value      = 2;
	GHI_RClickTypes[info.value] = info.text;
	info.func       = GHI_RClickDDClick;
	UIDropDownMenu_AddButton(info);
		
	info            = {};
	info.text       = "Letter / Book";
	info.value      = 3;
	GHI_RClickTypes[info.value] = info.text;
	info.func       = GHI_RClickDDClick;
	UIDropDownMenu_AddButton(info);
	
	info            = {};
	info.text       = "Bag";
	info.value      = 4;
	GHI_RClickTypes[info.value] = info.text;
	info.func       = GHI_RClickDDClick;
	UIDropDownMenu_AddButton(info)
	
	info            = {};
	info.text       = "GHR Reputation";
	info.value      = 5;
	GHI_RClickTypes[info.value] = info.text;
	info.func       = GHI_RClickDDClick;
	UIDropDownMenu_AddButton(info)
	
	info            = {};
	info.text       = "Script";
	info.value      = 6;
	GHI_RClickTypes[info.value] = info.text;
	info.func       = GHI_RClickDDClick;
	UIDropDownMenu_AddButton(info)

	
end

function GHI_RClickDDClick(val)
	if not(val == nil) then
		this.value = val;
	end
	
	GHI_RClickCatagory = this.value;
	local RClickType = GHI_RClickTypes[this.value];
	GHI_CreateItemsFrameRClickTextLabel:SetText(RClickType);
	
	GHI_CreateItemsFrame:SetHeight(30+410);
	GHI_CreateItemsFrameRclickError:Hide();
	
	if RClickType == "Buff" then
		GHI_CreateItemsFrameBuff:Show();
		GHI_CreateItemsFrame:SetHeight(30+690);
	else
		GHI_CreateItemsFrameBuff:Hide();
	end
	if RClickType == "Letter / Book" then
		GHI_CreateItemsFrameBook:Show();
		GHI_CreateItemsFrameBookUsebox:SetText("Read text.");
		GHI_CreateItemsFrame:SetHeight(30+530);
	else
		GHI_CreateItemsFrameBook:Hide();
	end
	
	if RClickType == "Bag" then
		GHI_CreateItemsFrameBag:Show();
		GHI_CreateItemsFrameBagUsebox:SetText("Open Bag.");
		GHI_CreateItemsFrame:SetHeight(30+530);
	else
		GHI_CreateItemsFrameBag:Hide();
	end
	
	if RClickType == "GHR Reputation" then
		if type(GHR_OwnRank) == "number" and  GHR_OwnRank < 4 then 
			GHI_CreateItemsFrameReputation:Show();
			GHI_CreateItemsFrameReputationUsebox:SetText("Increases your reputation.");
			GHI_CreateItemsFrame:SetHeight(30+580);
		else
			GHI_CreateItemsFrameReputation:Hide();
			GHI_CreateItemsFrameRclickErrorTextLabel:SetText(GHI_MISSING_GHR_RANK);
			GHI_CreateItemsFrameRclickError:Show();
			GHI_CreateItemsFrame:SetHeight(30+470);

		end
		
	else
		GHI_CreateItemsFrameReputation:Hide();
	end
	
	if RClickType == "Script" then
		GHI_CreateItemsFrameScript:Show();
		GHI_CreateItemsFrameScriptUsebox:SetText("");
		GHI_CreateItemsFrame:SetHeight(30+605);
	else
		GHI_CreateItemsFrameScript:Hide();
	end
end
	 
function GHI_RClickDD_OnClick() 
	
	ToggleDropDownMenu(1, nil, GHI_DropDownMenu, GHI_DropDownMenuButton, 0, 0);
	
end --]]

--[[ 	Right Click GUI
Buff:
	EditBox		BuffName
	EditBox		BuffDetails
	IconButton		BuffIcon
	EditBox		BuffDurtion
	EditBox		ItemCD
	CheckButton	BuffFilter
	CheckButton	untillCanceled

]]
--[[
function GHI_CreateItemOnOK(parent,returnResult)
	-- if returnResult = true, then return the data for the item instead of creating it. Used by edit item etc.
	
	local name,icon,quality,details,comment,amount,stackSize,rightClick,rightClicktext,copyable;
	
	name = getglobal(parent.."Namebox"):GetText(); if name == "" then GHI_Message("Please enter a item name"); return end;	
	icon = getglobal(parent.."IconButtonIconTexture"):GetTexture();
	quality = GHI_Quality;
	white1 = getglobal(parent.."White1box"):GetText();
	white2 = getglobal(parent.."White2box"):GetText();
	comment = getglobal(parent.."Commentbox"):GetText();
	amount = tonumber(getglobal(parent.."Amountbox"):GetText());
	stackSize = GHI_StackSliderValues[( getglobal(parent.."StackSlider") ):GetValue()];
	
	
	if getglobal(parent.."Check1"):GetChecked() == 1 then
		copyable = true; 
	else 
		copyable = false; 
	end
	
	
	if amount == nil then amount = 1 end;
	
	local createEachAsUnique = false;
	
	if GHI_RClickTypes[GHI_RClickCatagory] == "Buff" then
		rightClick = {};
		rightClick.Type = "buff";
		--rightClick.text = getglobal(parent.."BuffUsebox"):GetText();
		rightClicktext = getglobal(parent.."BuffUsebox"):GetText();
		rightClick.buffName = getglobal(parent.."BuffNamebox"):GetText(); if rightClick.text == "" then GHI_Message("Please enter a buff name"); return end;	
		rightClick.buffDetails = getglobal(parent.."BuffDetailsbox"):GetText();
		rightClick.buffIcon = getglobal(parent.."BuffIconButtonIconTexture"):GetTexture();
		rightClick.buffDuration = GHI_CDSliderValues[getglobal(parent.."BuffDurationSlider"):GetValue()];
		rightClick.CD = GHI_CDSliderValues[getglobal(parent.."BuffCDSlider"):GetValue()];
		rightClick.buffFunction = nil;
		if getglobal(parent.."BuffCheck1"):GetChecked() then
			rightClick.filter = "HELPFUL"
		else
			rightClick.filter = "HARMFUL"
		end
		if getglobal(parent.."BuffCheck2"):GetChecked() then
			rightClick.consumed = 1;
		else
			rightClick.consumed = 0;
		end
		if getglobal(parent.."BuffCheck3"):GetChecked() then
			rightClick.untilCanceled = 1;
		else
			rightClick.untilCanceled = 0;
		end
		

	elseif GHI_RClickTypes[GHI_RClickCatagory] == "Letter / Book" then
		local pageText = {};
		pageText[1] = ""
		rightClick = {};
		rightClick.Type = "book";
		rightClicktext = getglobal(parent.."BookUsebox"):GetText();
		rightClick.CD = 0;
		
		
		rightClick.title = getglobal(parent.."BookTitlebox"):GetText();
		rightClick.pages = 1;
		for i = 1,rightClick.pages do
			rightClick[i] = {};
			rightClick[i].text1 = string.sub(pageText[1],0,127) 
			rightClick[i].text2 = string.sub(pageText[1],128,255) 
			rightClick[i].text3 = string.sub(pageText[1],256,383) 
			rightClick[i].text4 = string.sub(pageText[1],384,511) 
			rightClick[i].text5 = string.sub(pageText[1],512,639) 
			rightClick[i].text6 = string.sub(pageText[1],640,767) 
			rightClick[i].text7 = string.sub(pageText[1],768,895) 
			rightClick[i].text8 = string.sub(pageText[1],896,1023) 
			
		end
	elseif GHI_RClickTypes[GHI_RClickCatagory] == "Bag" then	
		rightClicktext = getglobal(parent.."BagUsebox"):GetText();
		rightClick = {};
		rightClick.Type = "bag";
		rightClick.size = getglobal(parent.."BagSizeSlider"):GetValue();
		local texture = GHI_TextureTypes[GHI_TextureCatagory];
		if not(texture == "Normal") and type(texture)=="string" then
			rightClick.texture = "-"..texture;
		end
		createEachAsUnique = true;
		stackSize = 1;
	elseif GHI_RClickTypes[GHI_RClickCatagory] == "GHR Reputation" then
		rightClicktext = getglobal(parent.."ReputationUsebox"):GetText();
		rightClick = {};
		rightClick.Type = "GHR Reputation";
		rightClick.CD = GHI_CDSliderValues[getglobal(parent.."ReputationCDSlider"):GetValue()];
		
			
		rightClick.faction = GHR_FactionData[GHI_FactionDDCurrent].ID;
		
		rightClick.amount = getglobal(parent.."ReputationRepAmountbox"):GetText();
		rightClick.AddonReqName = "GHR";
		rightClick.AddonReqData = 0.7;
		
		if getglobal(parent.."ReputationCheck2"):GetChecked() then
			rightClick.consumed = 1;
		else
			rightClick.consumed = 0;
		end
	elseif GHI_RClickTypes[GHI_RClickCatagory] == "Script" then
		rightClicktext = getglobal(parent.."ScriptUsebox"):GetText();
		rightClick = {};
		rightClick.Type = "script";
		rightClick.CD = GHI_CDSliderValues[getglobal(parent.."ScriptCDSlider"):GetValue()];
		rightClick.code = {};
		local code = getglobal(parent.."ScriptCodeScrollText"):GetText();
		--local c = 0;
		while not(code == nil) and not(code == "") do
			
			table.insert(rightClick.code,string.sub(code,0,127));
			code = string.sub(code,128);
			--c = c+1;
			--code = string.sub(code,128);
		end
		--HI_Message("Ran "..c.." times");
		
		if getglobal(parent.."ScriptCheck2"):GetChecked() then
			rightClick.consumed = 1;
		else
			rightClick.consumed = 0;
		end
	end
		
	getglobal(parent.."Namebox"):AddHistoryLine(name);
	if not(white1 == "") and not(white1 == nil) then
		getglobal(parent.."White1box"):AddHistoryLine(white1);
	end
	if not(white2 == "") and not(white2 == nil) then
		getglobal(parent.."White2box"):AddHistoryLine(white2);
	end
	if not(comment == "") and not(comment == nil) then
		getglobal(parent.."Commentbox"):AddHistoryLine(comment);
	end
	
	if not(returnResult == true) then
		if createEachAsUnique == false then
			GHI_CreateItem(name,icon,quality,white1,white2,comment,amount,stackSize,copyable,rightClick,rightClicktext)
		else
			for i = 1,amount do 
				GHI_CreateItem(name,icon,quality,white1,white2,comment,1,stackSize,copyable,rightClick,rightClicktext)
			
			end
		end
	
		GHI_ClearCreateItem(parent);
		this:GetParent():Hide();
		return nil;
	else
		return name,icon,quality,white1,white2,comment,amount,stackSize,copyable,rightClick,rightClicktext,amount,createEachAsUnique;
	end

end --]]

--[[ 	Right click actions.

=================  Defualt Right click data    =======================
Type
AddonReqName
AddonReqData
RequirementType  (Profession_'Name' , Race, WealthRank,
RequitementData ( Skill, PlayerRace_PlayerRace, RankLevel,
Text
CD
Details

=================  Type based Details data 	=======================
Buff
	name
	text
	texture
	untilCancelled
	filter
	debuffType 
	consumed
	duration
	cancelable
	Effect (function or text)
	Effect frequency  (0 for once)
	
Book
	Title
	pages
	Page1Text1
	unpack(arg).
	Page1Text5
	Page2Text1
	unpack(arg).
	PageNText5
	
	notes: auto detects if it is a single page or a book
	
Reputation
	FactionID
	Amount
	Player (evt "soulbound")

Container
	DataIndex
	Slots

]]
--[[
GHI_RightClickHelpText = {};
GHI_RightClickHelpText["None"] = "Choose a Right Click action in the menu, or leave it as 'none' to create an item without any right click action.";
GHI_RightClickHelpText["Buff"] = "A buff will be shown just like a normal buff, but can only contain text and no stat changings etc. Please enter the details below.";
GHI_RightClickHelpText["Letter / Book"] = "This right click function makes the item readable. It contenst can be just a few lines, or a whole book. When the item is created, right click on it to read it or edit it. Please enter the detials below (title can be edited later).";
GHI_RightClickHelpText["Bag"] = "A container in wich you can store GH items.";
GHI_RightClickHelpText["GHR Reputation"] = "The user will gain a reputation increase upon right click. Requires the GHR addon to create or use.";
GHI_RightClickHelpText["Script"] = "The script function allows you to enter any lua script as right click action. Note: / macroes does not work.";

GHI_MISSING_GHR_RANK = "To create reputation changes you must have GHR and have a rank of faction officer or higher."

function GHI_ShowRightClickHelp()
	local button = this;
	
	GameTooltip:SetOwner(button, "ANCHOR_LEFT");
		
	GameTooltip:ClearLines()
	
	local RClickType = GHI_RClickTypes[GHI_RClickCatagory];
	
	if not(RClickType) then RClickType = "None" end
	
	GameTooltip:AddLine(GHI_WordWrap(GHI_RightClickHelpText[RClickType],25),  1.0, 1.0, 1.0);
	
	GameTooltip:Show()
	this.UpdateTooltip = nil;
end
--]]
function GHI_WordWrap(st,chars)
	local num = tonumber(chars);
	if not(st) or not(num) then return st end
	
	local done = false;
	local lastSpace = 0;
	local c = 0;
	local spacefound = false;
	local nextBreak = chars;
	while(done == false) do
		if strsub(st,c,c) == " " then
			lastSpace = c;
			spacefound= true;
		end
		
		if c > nextBreak and spacefound then
			st = strsub(st,0,lastSpace).."\n"..strsub(st,lastSpace+1);
			nextBreak = lastSpace + 4 + chars;
			spacefound = false;
		end
		
		
		c = c + 1;
		
		if c > strlen(st) or c > 1000 then
			done = true;
		end
	end
	return st;
	
end

--[[
GHI_TextureType = 1;
GHI_TextureTypes = {}
function GHI_TextureDD_Update()

	info            = {};
	info.text       = "Normal";
	info.value      = 1;
	GHI_TextureTypes[info.value] = info.text;
	info.func       = GHI_TextureDDClick;
	UIDropDownMenu_AddButton(info);	

	
	info            = {};
	info.text       = "Bank";
	info.value      = 2;
	GHI_TextureTypes[info.value] = info.text;
	info.func       = GHI_TextureDDClick;
	UIDropDownMenu_AddButton(info);
		
	info            = {};
	info.text       = "Keyring";
	info.value      = 3;
	GHI_TextureTypes[info.value] = info.text;
	info.func       = GHI_TextureDDClick;
	UIDropDownMenu_AddButton(info);
	
	
end

function GHI_TextureDDClick()
	
	GHI_TextureCatagory = this.value;
	local TextureType = GHI_TextureTypes[this.value];
	GHI_CreateItemsFrameBagTextureDDTextLabel:SetText(TextureType);
		
end


GHI_FactionDDCurrent = 1;
GHI_FactionDDText = {}
GHI_FactionDDIndex = {}
function GHI_FactionDD_Update()
	if not(type(GHR_FactionData) == "table") then return end;
	
	local n1 = 0;
	local c1 = 1; 
	
	for i1 = 2,table.getn(GHR_FactionData) do
	
		info            = {};
		info.text       = GHR_FactionData[i1]["name"];
		info.value      = c1;
		info.func       = GHI_FactionDDClick;
		UIDropDownMenu_AddButton(info);
		GHI_FactionDDText[c1] = info.text;
		GHI_FactionDDIndex[c1] = i1;
		
		c1 = c1 + 1;
		
		
	end	
	
	
end

function GHI_FactionDDClick()
	

	GHI_FactionDDCurrent = GHI_FactionDDIndex[this.value];
	GHI_CreateItemsFrameReputationFactionDDTextLabel:SetText(GHI_FactionDDText[this.value]); 
end	  --]]

function GHI_GenerateID()
	local timeID = time() - 1200000000;
	if (timeID <= GHI_LastCreateID) then
		timeID = GHI_LastCreateID + 1;
	end
	GHI_LastCreateID = timeID;
	return userName.."_"..timeID;
end


--	==================================== Edit item 	==================================== 
--[[
function GHI_InsertItemForEdit(bag,slot)
	
	
	local parent = "GHI_CreateItemsFrame";
	local info = GHI_GetContainerInfo(bag,slot);
	local ID = info.ID;
	if GHI_IsOfficialItem(ID) == true then
		return
	end
	local name,icon,quality,white1,white2,comment,stackSize,creater,version,rightClick,rightClicktext = GHI_GetItemInfo(ID);
	if not(creater == UnitName("player")) then
		if name then		GHI_Message(name.." is not made by you."); end
		return nil;
	end
	
	GHI_CreateItemsFrame.ID = ID;
	GHI_CreateItemsFrame.bag = bag;
	GHI_CreateItemsFrame.slot = slot;
	GHI_CreateItemsFrame.rcInfo = {}; -- preserved  right click info
	
	getglobal(parent.."Namebox"):SetText(name);
	getglobal(parent.."IconButtonIconTexture"):SetTexture(icon);
	getglobal(parent.."White1box"):SetText(white1);
	getglobal(parent.."White2box"):SetText(white2);
	getglobal(parent.."Commentbox"):SetText(comment);
	getglobal(parent.."Amountbox"):SetText(info.amount);
	
	
	getglobal(parent.."Check1"):SetChecked(GHI_IsCopyable(ID));
	
	GHI_Quality = quality;
	local color = ITEM_QUALITY_COLORS[GHI_Quality];
	GHI_CreateItemsFrameQualityTextLabel:SetText("|CFF" ..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255) .." "..getglobal("ITEM_QUALITY" ..GHI_Quality.. "_DESC").."|r"); 
		
	value = 1;
	for i = 1,table.getn(GHI_StackSliderValues) do
		if GHI_StackSliderValues[i] == stackSize then
			value = i;
		end
	end
	getglobal(parent.."StackSlider"):SetValue(value);
	
	
	
	--	right click      GHI_RClickTypes[GHI_RClickCatagory]
	if rightClick then
		if rightClick.Type == "buff" then
			GHI_RClickDDClick(2);
			
			getglobal(parent.."BuffUsebox"):SetText(rightClicktext);
			getglobal(parent.."BuffNamebox"):SetText(rightClick.buffName);
			getglobal(parent.."BuffDetailsbox"):SetText(rightClick.buffDetails);
			getglobal(parent.."BuffIconButtonIconTexture"):SetTexture(rightClick.buffIcon);
			
			value = 1;
			for i = 1,table.getn(GHI_CDSliderValues) do
				if GHI_CDSliderValues[i] == rightClick.buffDuration then
					value = i;
				end
			end
			getglobal(parent.."BuffDurationSlider"):SetValue(value);
			
			value = 1;
			for i = 1,table.getn(GHI_CDSliderValues) do
				if GHI_CDSliderValues[i] == rightClick.CD then
					value = i;
				end
			end
			getglobal(parent.."BuffCDSlider"):SetValue(value);
			
			if rightClick.filter == "HELPFUL" then
				getglobal(parent.."BuffCheck1"):GetChecked(true)
				getglobal(parent.."BuffCheck1TextLabel"):SetText("Helpful");	
			else
				getglobal(parent.."BuffCheck1"):GetChecked(false)
				getglobal(parent.."BuffCheck1TextLabel"):SetText("Harmful");	
			end
			
			if rightClick.consumed == 1 then
				getglobal(parent.."BuffCheck2"):SetChecked(true);
			else
				getglobal(parent.."BuffCheck2"):SetChecked(false);
			end
			if rightClick.untilCanceled == 1 then
				getglobal(parent.."BuffCheck3"):SetChecked(true)
				getglobal(parent.."BuffDurationSlider"):Hide();
				
			else
				getglobal(parent.."BuffCheck3"):SetChecked(false)
				getglobal(parent.."BuffDurationSlider"):Show();
			end
			

		elseif rightClick.Type  == "book" then
			GHI_RClickDDClick(3);
			
			getglobal(parent.."BookUsebox"):SetText(rightClicktext);
			
			local inf = {};
			inf.pages = rightClick.pages;
			
			for i = 1,inf.pages do
				inf[i] = rightClick[i];
			end
				
			GHI_CreateItemsFrame.rcInfo = inf; 
			
			
			getglobal(parent.."BookTitlebox"):SetText(rightClick.title);
			
			
		elseif rightClick.Type  == "bag" then	
			GHI_RClickDDClick(4);
			
			getglobal(parent.."BagUsebox"):SetText(rightClicktext);
			
			getglobal(parent.."BagSizeSlider"):SetValue(rightClick.size);
			
			if type(rightClick.texture) == "string" then
				local texture = string.sub(rightClick.texture,2);
				
				GHI_TextureCatagory = 1;
				for i = 1,table.getn(GHI_TextureTypes) do
					if GHI_TextureTypes[i] == texture then
						GHI_TextureCatagory = i;
					end
				end
			else
				GHI_TextureCatagory = 1;
			end
			
			local TextureType = GHI_TextureTypes[GHI_TextureCatagory];
			GHI_CreateItemsFrameBagTextureDDTextLabel:SetText(TextureType);
			
		elseif rightClick.Type  == "GHR Reputation" then
			GHI_RClickDDClick(5);
			
			getglobal(parent.."ReputationUsebox"):SetText(rightClicktext);
			
			value = 1;
			for i = 1,table.getn(GHI_CDSliderValues) do
				if GHI_CDSliderValues[i] == rightClick.CD then
					value = i;
				end
			end
			getglobal(parent.."ReputationCDSlider"):SetValue(value);
			
			GHI_FactionDDCurrent = 1;
			local n = "";
			for i = 1,table.getn(GHR_FactionData) do
				if GHR_FactionData[i].ID == rightClick.faction then
					--for j = 1,table.getn(GHI_FactionDDText) do
						--if GHI_FactionDDText[j] == GHR_FactionData[i].name then
					GHI_FactionDDCurrent = i;
						--end
					--end
					
				end
			end
		
			GHI_CreateItemsFrameReputationFactionDDTextLabel:SetText(GHI_FactionDDText[GHI_FactionDDCurrent-1]);
			
			
			getglobal(parent.."ReputationRepAmountbox"):SetText(rightClick.amount);
						
			if rightClick.consumed == 1 then
				getglobal(parent.."ReputationCheck2"):SetChecked(true);
			else
				getglobal(parent.."ReputationCheck2"):SetChecked(false);
			end
		elseif rightClick.Type == "script" then
			GHI_RClickDDClick(6);
			getglobal(parent.."ScriptUsebox"):SetText(rightClicktext);
			
			value = 1;
			for i = 1,table.getn(GHI_CDSliderValues) do
				if GHI_CDSliderValues[i] == rightClick.CD then
					value = i;
				end
			end
			getglobal(parent.."ScriptCDSlider"):SetValue(value);
			
			local code = "";
			for i = 1,table.getn(rightClick.code) do
				if type(rightClick.code[i]) == "string" then
					code = code..rightClick.code[i];
				end
			end
						
			getglobal(parent.."ScriptCodeScrollText"):SetText(code);
			
			
			if rightClick.consumed == 1 then
				getglobal(parent.."ScriptCheck2"):SetChecked(true);
			else
				getglobal(parent.."ScriptCheck2"):SetChecked(false);
			end
		end
	end
	
	GHI_CreateItemsFrameEditButtons:Show();
	GHI_CreateItemsFrameOk:Hide();
	GHI_CreateItemsFrameCancel:Hide();
	return true;
end

function GHI_EditItemOnOK(all)
	local ID = GHI_CreateItemsFrame.ID;
	local bag = GHI_CreateItemsFrame.bag;
	local slot = GHI_CreateItemsFrame.slot;
	local info = GHI_GetContainerInfo(bag,slot);
	local name,icon,quality,white1,white2,comment,amount,stackSize,copyable,rightClick,rightClicktext,amount,createEachAsUnique = GHI_CreateItemOnOK("GHI_CreateItemsFrame",true);
	
	if all == false then
		--GHI_Message("new id");
		amount = info.amount;
		
		
		ID = GHI_GenerateID()
		
		if not(icon) then 
			icon = "Interface\\Icons\\INV_Misc_QuestionMark";
		elseif icon == "" then
			icon = "Interface\\Icons\\INV_Misc_QuestionMark";
		end
		
		if amount == nil then amount = 1; end
		if stackSize == nil then stackSize = 1; end
		
		-- insert evt. orig item info
		local rcInfo = GHI_CreateItemsFrame.rcInfo;
		
		if type(rcInfo) == "table" then
			for index,value in pairs(rcInfo) do 
				rightClick[index] = value;
			end
		end
		
		if type(rightClick) == "table" then
			rightClick.version = 1;
		end
		
		GHI_ItemData[ID] = {
			["name"] = name;
			["quality"] = quality;
			["icon"] = icon; --"Interface\\Icons\\INV_BannerPVP_01";
			["white1"] = white1;
			["white2"] = white2;
			["comment"] = comment;
			["creater"] = GHI_PName;
			["stackSize"] = stackSize;
			["rightClick"] = rightClick;
			["rightClicktext"] = rightClicktext;
			["locked"] = 0;
			["version"] = 1;
			["copyable"] = copyable;
		};
		
		GHI_ContainerData[bag][slot] = {};
		GHI_ContainerData[bag][slot].ID = ID;
		GHI_ContainerData[bag][slot].amount = amount; 
		
		local list = GHI_FindItem(ID,true);
		
		for i = 1,table.getn(list) do
			if type(list[i]) == "table" then
				local bag = list[i].bag;
				local slot = list[i].slot;
				local info = GHI_GetContainerInfo(bag,slot);
				if type(info) == "table" then
					if type(info.amount) == "number" then
						local a = info.amount;
						local ID = info.ID;
						while a > stackSize do	
							local temp1 = {}
							temp1.ID = ID;
							temp1.amount = stackSize; 
							a = a - stackSize;
							GHI_SetContainerInfo(bag,slot,temp1); 
							local temp2 = {}
							bag,slot = GHI_GetFreeSpace();
							temp2.ID = ID;
							temp2.amount = a;
							GHI_SetContainerInfo(bag,slot,temp2); 
						end
					end
				end
			end
		end
		
		GHI_MaintainMainBags();
		GHI_UpdateContainers()
			
		
	else
		if not(icon) then 
			icon = "Interface\\Icons\\INV_Misc_QuestionMark";
		elseif icon == "" then
			icon = "Interface\\Icons\\INV_Misc_QuestionMark";
		end
		
		local v1,v2 = GHI_GetVersions(ID)
		
		if stackSize == nil then stackSize = 1; end
		
		-- insert evt. orig item info
		local rcInfo = GHI_CreateItemsFrame.rcInfo;
		
		if type(rcInfo) == "table" then
			if not(type(rightClick)=="table") then
				rightClick={};
			end
			for index,value in pairs(rcInfo) do 
				rightClick[index] = value;
			end
			rightClick["version"] = v2;
			
			if rightClick.Type == "bag" then
				--local s = rightClick.size;
				--local bag_ID = GHI_GetBagID(ID);
				-- TODO: If bag is made smaller, then move items
			end
		end
		
		GHI_ItemData[ID] = {
			["name"] = name;
			["quality"] = quality;
			["icon"] = icon; --"Interface\\Icons\\INV_BannerPVP_01";
			["white1"] = white1;
			["white2"] = white2;
			["comment"] = comment;
			["creater"] = GHI_PName;
			["stackSize"] = stackSize;
			["rightClick"] = rightClick;
			["rightClicktext"] = rightClicktext;
			["locked"] = 0;
			["version"] = v1 + 1;
			["copyable"] = copyable;
		};
		
		local list = GHI_FindItem(ID,true);
		
		for i = 1,table.getn(list) do
			if type(list[i]) == "table" then
				local bag = list[i].bag;
				local slot = list[i].slot;
				local info = GHI_GetContainerInfo(bag,slot);
				if type(info) == "table" then
					if type(info.amount) == "number" then
						local a = info.amount;
						local ID = info.ID;
						while a > stackSize do	
							local temp1 = {}
							temp1.ID = ID;
							temp1.amount = stackSize; 
							a = a - stackSize;
							GHI_SetContainerInfo(bag,slot,temp1); 
							local temp2 = {}
							bag,slot = GHI_GetFreeSpace();
							temp2.ID = ID;
							temp2.amount = a;
							GHI_SetContainerInfo(bag,slot,temp2); 
						end
					end
				end
			end
		end
	
	end
	GHI_ClearCreateItem("GHI_CreateItemsFrame");
	GHI_CreateItemsFrame:Hide();
	GHI_UpdateContainers()
end --]]

--	security

--[[
function strsub3(m,s,e) -- a string.sub that can handle foreign characters etc.
	-- remove [ ]
	msg = strjoin(" ",strsplit("[",m));
	msg = strjoin(" ",strsplit("]",msg));
	msg = strjoin(" ",strsplit("{",msg));
	msg = strjoin(" ",strsplit("}",msg));
	msg = strjoin(" ",strsplit("(",msg));
	msg = strjoin(" ",strsplit(")",msg));
	msg = strjoin(" ",strsplit("%",msg));
	msg = strjoin(" ",strsplit("?",msg));
	msg = strjoin(" ",strsplit("+",msg));
	msg = strjoin(" ",strsplit("*",msg));
	msg = strjoin(" ",strsplit("-",msg));
	msg = strjoin(" ",strsplit("$",msg));
	--msg = strjoin(" ",strsplit("¦",msg));
	
	local m2 = msg;

	if e > string.len(m) then e = string.len(m) end
	
	msg = gsub(msg,strsub(msg,0,s-1),"");
	msg = gsub(msg,strsub(msg,(e+1)-(s-1)),"");
	GHI_Message("strsub2");
	if not(string.len(msg)==(e-s)+1 or string.len(msg)==(e-s)) then
		GHI_Message("Not  OK");
		local re = strsub(msg,0,s-1)
		GHI_Message("Tried to replace "..re.." cut out msg: "..m2);
		for i = 1,string.len(re) do
			if not(strbyte(msg,i)==strbyte(re,i)) then
				GHI_Message("At "..i.." "..strchar(strbyte(re,i)));
			end
		end
	else 
		GHI_Message("OK");
	end
	
	--if msg == " " then msg = "¦"; end
	
	assert(string.len(msg)==(e-s)+1 or string.len(msg)==(e-s),"Unknown character inside strsub2. At "..e.." -> "..(e+1)-(s-1).." of "..string.len(m)..". Result was '"..("temp").."'");
	return msg;
end

function strsub2(m,s,e)
	local msg = strsub(m,s,e);
	assert(string.len(msg)==(e-s)+1 or string.len(msg)==(e-s),"Unknown character inside strsub. At "..e.." -> "..(e+1)-(s-1).." of "..string.len(m)..". Result was '"..("temp").."'");
	return msg;
	
	if e > string.len(m) then e = string.len(m) end
	
	local bytes = {};
	for i=s,e do
		bytes[strbyte(m,i)] = true
	end
	
	GHI_Message("Len: "..string.len(m));
	
	for i = 1,128 do
		if not(bytes[i] == true) then
			--if strfind(m,strchar(i)) then
			local t;
			while (t==nil or (type(t)=="table" and table.getn(t) == 1000)) do
				t = {};
				t = strsplit(strchar(i),m,1000) -- 1024 is max
				
				m = strjoin(" ",t);
				GHI_Message(format("%s (%s) -> %s tables. Msg len is now %s",i,strchar(i) or "nil",table.getn(t),string.len(m)));
			end
			--end
		else
			GHI_Message(format("Ignoring #%s's (%s)",i,strchar(i)));
		end
	end
	
	GHI_Message("Len2: "..string.len(m));
	GHI_Message("Before: '"..m.."'");
	
	m = gsub(m,strsub(m,0,s-1),"");
	m = gsub(m,strsub(m,(e+1)-(s-1)),"");
	
	GHI_Message("After: "..m.."'");
	
	assert(string.len(m)==(e-s)+1 or string.len(m)==(e-s),"Unknown character inside strsub2. At "..e.." -> "..(e+1)-(s-1).." of "..string.len(m)..". Result was '"..("temp").."'");
	
	return m;
	
end
--]]

local crypt = 0
local area = 91;
local msg = UnitName("player") or "";

local function GetCharSeqLen(n) -- charlen as according to http://en.wikipedia.org/wiki/UTF-8
	if n < 192 then
		return 1;
	elseif n < 224 then
		return 2;	
	elseif n < 240 then
		return 3;
	else
		return 4;
	end
end


for i=1,string.len(msg) do
    local n = string.byte(msg,i);
	crypt = mod(crypt + n,127);
end
local Encrypt = function(msg,nonChar)
	-- 33 to 122
	local m = "";
	local ignore = 0;
	local i  = 1;
    while i <= string.len(msg) do
		local n = string.byte(msg,i);
		--GHI_Message("Encrypt. "..i.." : "..n);
		if n == 124 then
			m = m..strsub(msg,i,i+1);		
			i=i+1;
		elseif (n > 190) then
			local csl = GetCharSeqLen(n);
			m = m..strsub(msg,i,i+csl-1);						
			i=i+csl-1;
		else
			local c = n;
			if nonChar then
				n = mod(((n-32)+area) + 42 + i,area)+32;
			else
				n = mod(((n-32)+area) + crypt + i,area)+32;
			end
			
			m = m..string.char(n);
		end
		i=i+1;
    end
	
    return m;
end

local Decrypt = function(msg,nonChar)
    local s = "";
	local ignore = 0;
	local i  = 1;
    while i <= string.len(msg) do
		local n = string.byte(msg,i);
		if n == 124 then
			s = s..strsub(msg,i,i+1);		
			i=i+1;
		elseif (n > 190) then
			local csl = GetCharSeqLen(n);
			s = s..strsub(msg,i,i+csl-1);						
			i=i+csl-1;
		else
			local t = n;
			local plus = area;
			while (plus < i+60) do plus = plus+area; end
			if nonChar then
				n = mod(((n-32)-(42+i)) + plus,area)+32;
			else
				n = mod(((n-32)-(crypt+i)) + plus,area)+32;
			end
			
			s = s..string.char(n);
		end
		i=i+1;
    end
    return s;
end

local function CheckSum(s)
	local c = 0;
	for i = 0,string.len(s) do
		c = bit.bxor(c,string.byte(s,i));
	end
	return c;
end

local escC = "|"
local shortWords = {escC,"\n","{","}","~","\r","=","Interface\\\\Icons\\\\","<HTML><BODY><P>","</P></BODY></HTML>","\"text1\"","\"rightClicktext\"","\"version\"","\"type_name\"","\"scriptBefore","\\n        ","\"exportID\"","IMPORT_REQ","GHI_MiscData.Import","ration_size","\"rightClick\"","\"requireTarget\"","\"scriptAfter\"","\"creater\"","\"amount\"",  "\"copyable\"","\"quality\"","\"white1\"","\"white2\"",	"\"locked\"","\"stackSize\"","\"item\"","\"details\"","\"code\"","\"icon\"","\"consumed\"","\"multible\"","\"Type\"","Interface\\\\\\\\Icons\\\\",} -- "\"\"" 

local function EscIndex(n)
	if n < 15 then
		return escC..string.char(n+48);
	elseif n < 29 then
		return escC..string.char(n+49);
	elseif n < 32 then
		return escC..string.char(n+50);
	else
		return escC..string.char(n+51);
	end
end

local function ApplyEscapeCodes(s)
	for i = 1,table.getn(shortWords) do
		s = gsub(s,shortWords[i],EscIndex(i));
	end
	return s;
end
local function RemoveEscapeCodes(s)
	for i = table.getn(shortWords),1,-1 do
		s = gsub(s,EscIndex(i),shortWords[i]);
	end
	return s;
end

local function TableToString(t,addCheck)
	local s = "{";
	for index,value in pairs(t) do
		-- Lua 5.0 generic-for uses the first loop variable as the
		-- control value passed back to next().  Do not rewrite index here:
		-- doing so makes the following next(t,index) call fail with
		-- "invalid key for `next'".  Format a separate key instead.
		local key = index;
		if type(key)=="string" then
			key = format("\"%s\"",key);
		end
		if type(value)=="table" then
			s = format("%s[%s]=%s,",s,key,TableToString(value,false));
		elseif type(value)=="number" then
			s = format("%s[%s]=%s,",s,key,value);
		elseif type(value)=="nil" then
			s = format("%s[%s]=%s,",s,key,"nil");
		elseif type(value)=="boolean" then
			s = format("%s[%s]=%s,",s,key,btype(value));
		elseif type(value)=="string" then
			value = gsub(value,"\\","\\\\");
			value = gsub(value,"\n","\\n");
			value = gsub(value,"\r","\\r");
			value = gsub(value,"\"","\\\"");
			s = format("%s[%s]=\"%s\",",s,key,value);
		end
	end
	s = format("%s}",s);
	
	
	if not(addCheck == false) then
		s = ApplyEscapeCodes(s)
		s = string.len(s)..","..CheckSum(s)..s;
	end
	return s;
end

local function StringToTable(s)
	-- remove and validate the checksum
	local a = string.find(s,EscIndex(3));
	if not(a) then return {"Corrupt Item Data. Err01. Start: "..strsub(s,0,20)} end
	local meta = string.sub(s,0,a-1);
	if not(meta) then return {"Corrupt Item Data. Err02."} end
	local sum, csum = strsplit(",",meta);
	s = string.sub(s,a);
	sum = tonumber(sum);
	csum = tonumber(csum);
	if not(sum) or not(sum == string.len(s)) then return {"Corrupt Item Data. Err03."}; end
	if not(csum) or not(csum == CheckSum(s)) then return {"Corrupt Item Data. Err04."}; end

	s = RemoveEscapeCodes(s);
	
	s = (s or "{\"Corrupt Item Data. Err05.\"}");
	
	
	T = nil;
	RunScript("T="..s);
	return T or {"Corrupt Item Data. Err06."};
end

-- /script for i= 33,122 do GHI_Message("#"..i); CryptTest(strchar(i)); end
function CryptTest(s,a)
	local c = Encrypt(s,a)
	GHI_Message(c);
	local s2 = Decrypt(c,a)
	GHI_Message(s2);
end

function CryptTest2()
	for i= 33,123 do 
		if i==123 then i=124 end
		local s = strchar(i); 
		local c = Encrypt(s,true)
		local s2 = Decrypt(c,true)
		if not(s==s2) and type(s)=="string" then
			GHI_Message(format("Cryptation error for %s (%s).",s,i));
		end
	end
end

function EscapeTest(s)
	GHI_Message(s);
	GHI_Message(" ");
	s = ApplyEscapeCodes(s);
	GHI_Message(s);
	GHI_Message(" ");
	s = RemoveEscapeCodes(s);
	GHI_Message(s);
end

function TableTest(t)
	GHI_PrintArray(t);
	local s = TableToString(t);
	GHI_Message("non crypt: "..s);
	local s2 = Encrypt(s,true);
	GHI_Message("S: "..s2);
	local r = Decrypt(s2,true);
	GHI_Message("R: "..r);
	
	if not(s==r) then
		for i=1,25 do
			GHI_Message(format("%s: %s - '%s' -> %s - '%s'",i,strbyte(s,i),strchar(strbyte(s,i)),strbyte(r,i),strchar(strbyte(r,i))));
		end
	end
	
	assert(s==r,"Encryptation or decryptation not correct");
	local q = StringToTable(r);
	GHI_PrintArray(q);
end

function CompareStrings(s1,s2)
	local done = false
	for i=1,(min(string.len(s1),string.len(s2))) do
		if done == false and not(strbyte(s1,i) == strbyte(s2,i)) then
			GHI_Message(format("%s: '%s' vs. '%s'",i,strsub(s1,max(1,i-7),i+8),strsub(s2,max(1,i-7),i+8)));
			for j=max(i,3)-2,i+2 do
				GHI_Message(format("%s: %s (%s) vs. %s (%s)",j,strbyte(s1,j),strsub(s1,j,j),strbyte(s2,j),strsub(s2,j,j)));
			end
			GHI_Message(" ");
			done = true;
		end
	end
end

--	==================================== Import Export item 	==================================== 
function GHI_ExportItem(ID,amount,scriptBefore,req,scriptAfter)
	amount = tonumber(amount) or 1;
	local item = GHI_GetItemInfo(ID,true);
	if not(type(item)=="table") then return format(GHI_CAN_NOT_FIND_ITEM,ID or "nil"); end
	
	if not(item.creater == userName or GHI_IsCopyable(ID) == true) then
		return GHI_CAN_NOT_EXPORT;
	end
	local timeID = time() - 1200000000;
	local exportID = userName.."_"..timeID;
	local t = {["amount"]=amount,["ID"]=ID,["item"]=item,["exportID"]=exportID,["scriptBefore"]=scriptBefore,["scriptAfter"]=scriptAfter,["realm"]=GetRealmName(),};
	local s = TableToString(t);
	e = Encrypt(s,true);
	
	-- check the data
	local r = Decrypt(e,true);
	if not(s == r) then
		for i=1,string.len(s) do
			if not(strbyte(s,i) == strbyte(r,i)) then
				--GHI_Message(format("%s: %s - '%s' -> %s - '%s' -> %s - '%s'",i-1,strbyte(s,i-1),strchar(strbyte(s,i-1)),strbyte(e,i-1),strchar(strbyte(e,i-1)),strbyte(r,i-1),strchar(strbyte(r,i-1))));
				--GHI_Message(format("%s: %s - '%s' -> %s - '%s' -> %s - '%s'",i,strbyte(s,i),strchar(strbyte(s,i)),strbyte(e,i),strchar(strbyte(e,i)),strbyte(r,i),strchar(strbyte(r,i))));
				--GHI_Message(format("%s: %s - '%s' -> %s - '%s' -> %s - '%s'",i+1,strbyte(s,i+1),strchar(strbyte(s,i+1)),strbyte(e,i+1),strchar(strbyte(e,i+1)),strbyte(r,i+1),strchar(strbyte(r,i+1))));
			end
		end
		return "Encryption or decryption failed. Err00.";
	end
	local q = StringToTable(r);
	if table.getn(q) == 1 then
		return q[1];
	end
	
	--LAST_CODE = e;
	return e;
	
end


-- TurtleWoW mail transfer helper.  This is intentionally separate from the
-- user-facing Export Item feature: mailing is a transfer, so an item that is
-- not copyable may still be mailed away just as it may be traded away.
-- GHI Mail Export Debug v44
-- Logs export size and right click type to isolate buff-item failures.
function GHI_TransferExportItem(ID,amount)
	amount = tonumber(amount) or 1;
	local item = GHI_GetItemInfo(ID,true);
	if not(type(item)=="table") then return nil,format(GHI_CAN_NOT_FIND_ITEM,ID or "nil"); end
	local timeID = time() - 1200000000;
	local exportID = (UnitName("player") or "player").."_mail_"..timeID;
	local t = {
		["amount"] = amount,
		["ID"] = ID,
		["item"] = item,
		["exportID"] = exportID,
		["scriptBefore"] = "IMPORT_REQ = true;",
		["realm"] = GetRealmName(),
	};
	local raw = TableToString(t);
	local code = Encrypt(raw,true);
	local check = Decrypt(code,true);
	if not(raw == check) then
		return nil,"Could not serialize GHI item for mail.";
	end
	return code;
end

-- Read an export/transfer packet without importing it.  GHU uses this to
-- display the virtual attachment name/icon before the player claims it.
function GHI_PeekExportItem(code)
	if not(type(code)=="string") then return nil; end
	local raw = Decrypt(code,true);
	local t = StringToTable(raw);
	if not(type(t)=="table") or table.getn(t) == 1 then return nil; end
	return t["ID"], t["amount"], t["item"], t["realm"];
end

function GHI_ImportItem(code)
	
	local s = Decrypt(code,true);
	local t = StringToTable(s);
	if not(type(t)=="table") then
		GHI_Message(GHI_CAN_NOT_IMPORT);
		return false;
	elseif (table.getn(t) == 1) then
		GHI_Message(GHI_CAN_NOT_IMPORT);
		GHI_Message(t[1]);
		return false;
	end
	
	IMPORT_REQ = false;
	
	-- before
	G_Import = t;
	--GHI_Message(t["scriptBefore"]);
	GHI_DoScript(t["scriptBefore"]);
	t = G_Import;
	
	-- req
	if (GHI_GetReqResult("LUA Statement","IMPORT_REQ") == true) then
		
	else
		GHI_Message(GHI_CAN_NOT_IMPORT);
		return false;
	end
	
	local item = t["item"];
	local realm = t["realm"];
	-- realm check
	if not(realm == GetRealmName()) then
		item.creater = item.creater.." - "..realm;
	end
	t.item = item;
	
	-- after
	G_Import = t;
	GHI_DoScript(t["scriptAfter"]);
	t = G_Import;
	
	local ID = t["ID"];
	local amount = t["amount"];
	item = t["item"];
	realm = t["realm"];
	
	
	-- version check
	if not(type(GHI_ItemData[ID])== "table") or GHI_ItemData[ID].version <= item.version then
		GHI_ItemData[ID] = item;
	end
	
	-- insert item
	GHI_InsertItem(ID,amount,false);
	GHI_Message(format(GHI_IMPORT_REPORT,amount,GHI_GenerateLink(ID)));
	return true;
end



