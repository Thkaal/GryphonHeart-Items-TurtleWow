
--	==================================== Inventory Functions	====================================
--	ID index:
--	100 - 199 main bags
-- 	200 +  secoundary bags
-- 	99 dummy bag for copy item

local GHI_MainBackpackSize = 24;

function GHI_GetContainerInfo(container,slot)
	-- slot = "0" ->  info about the container.
	if not(container) or not(slot) then
		return nil;
	end
	container = tonumber(container);
	slot = (slot);
	if not(container) or not(slot) then
		return nil;
	end
	if not(type(GHI_ContainerData) == "table") then
		GHI_ContainerData = {};
	end
	
	local a = GHI_ContainerData[container]
	if not(type(a)=="table") then
		return nil
	end
	return GHI_ContainerData[container][slot];

end

function GHI_SetContainerInfo(container,slot,info)
	-- slot = "0" ->  info about the container.
	if not(container) or not(slot) then 
		return nil;
	end
	container = tonumber(container);
	slot = (slot);
	if not(container) or not(slot) then 
		return nil;
	end
	if not(type(GHI_ContainerData) == "table") then
		GHI_ContainerData = {};
	end
	
	local a = GHI_ContainerData[container];
	if not(type(a)=="table") then
		GHI_ContainerData[container] = {};
	end
	GHI_ContainerData[container][slot] = info;
	
end

function GHI_GetNumContainers(filter)
	-- filter string
	--	main = "main",1
	-- 	secound  = "secound","sec",2
	--	both = nil, "all","both",0
	if not(filter == nil) then
		filter = string.lower(filter);
	end
	
	local filt = 0;
	
	if filter == "main" or filter == "1" or filter == 1 then
		filt = 1;
	elseif filter == "secound" or filter == "sec" or filter == "2" or filter == 2 then
		filt = 2;
	elseif filter == nil or filter == "all" or filter == "0" or filter == 0 then
		filt = 0;
	else 
		return nil;
	end
	
	local a = GHI_GetContainerList(filt);
	if not(type(a) == "table") then 
		return nil
	end
	return table.getn(a);
	
	
end

function GHI_GetContainerList(filter)
	-- filter string
	--	main = "main",1
	-- 	secound  = "secound","sec",2
	--	both = nil, "all","both",0
	if not(filter == nil) then
		filter = string.lower(filter);
	end
	
	local filt = 0;
	
	if filter == "main" or filter == "1" or filter == 1 then
		filt = 1;
	elseif filter == "secound" or filter == "sec" or filter == "2" or filter == 2 then
		filt = 2;
	elseif filter == nil or filter == "all" or filter == "0" or filter == 0 then
		filt = 0;
	else 
		return nil;
	end
	
	local t = {};
	for index,value in pairs(GHI_ContainerData) do 
		if type(index) == "number" then
			if index >= 101 and index < 200 and (filt == 1  or filt == 0) then
				table.insert(t,index)
			elseif index >= 201 and (filt == 2  or filt == 0) then
				table.insert(t,index);
			end
		end
	end 
	-- sort;
	local s = {};
	s[1] = t[1];
	
	for i=2,table.getn(t) do
		for j=1,table.getn(s) do
			if s[j] > t[i] then
				table.insert(s,j,t[i]);
				break;
			elseif table.getn(s) == j then
				s[j+1] = t[i];
				break;
			end
			
		end		
	end
	
	
	return s;
end

function GHI_GetContainerSize(num)
	local info = GHI_GetContainerInfo(num,0);
	if not(info) or not(info.size) or  not(tonumber(info.size))  then
		if num < 200 then
			return 24;
		else
			return 99;
		end
	else
		return tonumber(info.size);
	end
	
end

function GHI_GetSlotList(container)	--	added in 0.26
	local t = {};
	for index,value in pairs(GHI_ContainerData[container] or {}) do
		if not(index == 0) then
			table.insert(t,index);
		end
	end
	return t;
end


-- 	==================================== 	Container	====================================
function GHI_ToggleBackpack()
	if GHIContainerFrame1:IsShown() then 
		GHIContainerFrame1:Hide(); 
		--GHI_BackpackButton:SetChecked(false);
	else 
		GHIContainerFrame1:Show(); 
		--GHI_BackpackButton:SetChecked(true);
	end
end

function GHI_ContainerHookings()
	orig_updateContainerFrameAnchors = updateContainerFrameAnchors;
	updateContainerFrameAnchors = GHI_UpdateContainer;
	
	--orig_CursorHasItem = CursorHasItem;
	--CursorHasItem = GHI_FCursorHasItem;
	
	orig_StackSplitFrameOkay_Click = StackSplitFrameOkay_Click;
	StackSplitFrameOkay_Click = GHI_StackSplitFrameOkay_Click;
	
	local Old_Script = StackSplitOkayButton:GetScript("OnClick");
	StackSplitOkayButton:SetScript("OnClick",StackSplitFrameOkay_Click);
	
	
	orig_StackSplitFrame_OnHide = StackSplitFrame_OnHide;
	StackSplitFrame_OnHide = GHI_StackSplitFrame_OnHide;
	
	orig_PickupContainerItem = PickupContainerItem;
	PickupContainerItem = GHI_Hooked_PickupContainerItem;
	
	--orig_PickupAction = PickupAction;
	--PickupAction = GHI_PickupAction;
	
end

function GHI_UpdateContainer()
	orig_updateContainerFrameAnchors();
	GHI_updateContainerFrameAnchors();
end

function GHI_ContainerFrame_OnLoad()
	this:RegisterEvent("BAG_UPDATE");
	this:RegisterEvent("BAG_CLOSED");
	this:RegisterEvent("BAG_OPEN");
	this:RegisterEvent("BAG_UPDATE_COOLDOWN");
	this:RegisterEvent("ITEM_LOCK_CHANGED");
	this:RegisterEvent("UPDATE_INVENTORY_ALERTS");
	this:RegisterEvent("DISPLAY_SIZE_CHANGED");
	this.bagsShown = 0;
	this.bags = {};
	if this:GetName() == "GHIContainerFrame1" then
		GHI_ContainerFrame_GenerateFrame(this,GHI_MainBackpackSize,101)
	else
		this.notInit = true;
		--GHI_ContainerFrame_GenerateFrame(this,8,200)
	end
	GHI_updateContainerFrameAnchors();
end

function GHI_ContainerFrame_OnEvent()

	--GHI_Message(this:GetName().." : "..event);
	if ( event == "BAG_UPDATE" ) then
		if ( this:IsShown() and this:GetID() == arg1 ) then
 			GHI_ContainerFrame_Update(this);
		end
	elseif ( event == "ITEM_LOCK_CHANGED" or event == "BAG_UPDATE_COOLDOWN" or event == "UPDATE_INVENTORY_ALERTS" ) then
		if ( this:IsShown() ) then
			GHI_ContainerFrame_Update(this);
		end
	elseif ( event == "DISPLAY_SIZE_CHANGED" ) then
		if ( this:IsShown() ) then
			GHI_updateContainerFrameAnchors();
		end
	end
end

function GHI_ContainerFrame_OnHide()
	if this:GetID() > 200 then
		this:SetID(200)
	end
	
	GHI_updateContainerFrameAnchors();

	if ( this:GetID() == KEYRING_CONTAINER ) then
		UpdateMicroButtons();
		PlaySound("KeyRingClose");
	else
		PlaySound("igBackPackClose");
	end
end

function GHI_ContainerFrame_OnShow()
	
	--[[
	if ( this:GetID() == 0 ) then
		MainMenuBarBackpackButton:SetChecked(1);
	elseif ( this:GetID() <= NUM_BAG_SLOTS ) then 
		local button = getglobal("CharacterBag"..(this:GetID() - 1).."Slot");
		if ( button ) then
			button:SetChecked(1);
		end
	else
		UpdateBagButtonHighlight(this:GetID());
	end]]
	if this.notInit == true then
		this:Hide();
		return;
	end
	
	PlaySound("igBackPackOpen");
	--GHI_Message("Opening "..this:GetName());
	GHI_updateContainerFrameAnchors();
	
	if not(GHI_InitMainBag == true) and this:GetName() == "GHIContainerFrame1" then
		GHI_InitMainBag = true;
		GHI_MaintainMainBags();
	end
	
	
	GHI_ContainerFrame_Update(this) 
end

function GHI_ContainerFrame_GenerateFrame(frame, size, id,item_id)
	frame.size = size;
	local name = frame:GetName();
	local bgTextureTop = getglobal(name.."BackgroundTop");
	local bgTextureMiddle = getglobal(name.."BackgroundMiddle1");
	local bgTextureBottom = getglobal(name.."BackgroundBottom");
	local columns = NUM_CONTAINER_COLUMNS;
	local rows = ceil(size / columns);
	frame.notInit = false;
	-- Not the backpack
	-- Set whether or not its a bank bag
	local bagTextureSuffix = "";
	local itemname,icon = GHI_GetItemInfo(item_id)
	local rc = GHI_GetRightClickInfo(item_id);
	if not(type(rc)=="table") then
		rc = {};
	end
	if rc.Type == "multible" then
		local i = rc.bag_index;
		if i then
			rc = rc[i];
		else 
			rc = {};
		end
	end
	if rc.texture == "-Bank" or rc.texture == "-Keyring" then 
		bagTextureSuffix = rc.texture;
	end
	
	-- Data for custom bags
	--	texture
	--	name
	--	icon
	
	--bagTextureSuffix = "-Bank";
	
	--bagTextureSuffix = "-Keyring";
	
	-- Set textures
	
	
	bgTextureTop:SetTexture("Interface\\ContainerFrame\\UI-Bag-Components"..bagTextureSuffix);
	for i=1, MAX_BG_TEXTURES do
		getglobal(name.."BackgroundMiddle"..i):SetTexture("Interface\\ContainerFrame\\UI-Bag-Components"..bagTextureSuffix);
		getglobal(name.."BackgroundMiddle"..i):Hide();
	end
	bgTextureBottom:SetTexture("Interface\\ContainerFrame\\UI-Bag-Components"..bagTextureSuffix);
	-- Hide the moneyframe since its not the backpack
	getglobal(name.."MoneyFrame"):Hide();	
	
	
	if size == 1 then
		
		local bgTextureTop = getglobal(name.."BackgroundTop");
		local bgTextureMiddle = getglobal(name.."BackgroundMiddle1");
		local bgTextureMiddle2 = getglobal(name.."BackgroundMiddle2");
		local bgTextureBottom = getglobal(name.."BackgroundBottom");
		local bgTexture1Slot = getglobal(name.."Background1Slot");
		
		bgTexture1Slot:Show();
		bgTextureTop:Hide();
		bgTextureMiddle:Hide();
		bgTextureMiddle2:Hide();
		bgTextureBottom:Hide();
		
		frame:SetHeight(70);	
		frame:SetWidth(99);
		getglobal(frame:GetName().."Name"):SetText("");
		--SetBagPortraitTexture(getglobal(frame:GetName().."Portrait"), id);
		local itemButton = getglobal(name.."Item1");
		itemButton:SetID(1);
		itemButton:SetPoint("BOTTOMRIGHT", name, "BOTTOMRIGHT", -10, 5);
		itemButton:Show();

	else
		-- non 1 slot
		local bgTextureTop = getglobal(name.."BackgroundTop");
		local bgTextureMiddle = getglobal(name.."BackgroundMiddle1");
		local bgTextureMiddle2 = getglobal(name.."BackgroundMiddle2");
		local bgTextureBottom = getglobal(name.."BackgroundBottom");
		local bgTexture1Slot = getglobal(name.."Background1Slot");
		
		bgTexture1Slot:Hide();
		bgTextureTop:Show();
		--bgTextureMiddle:Hide();
		--bgTextureMiddle2:Hide();
		--bgTextureBottom:Hide();
		-- 
		
		
		local bgTextureCount, height;
		local rowHeight = 41;
		-- Subtract one, since the top texture contains one row already
		local remainingRows = rows-1;

		-- See if the bag needs the texture with two slots at the top
		local isPlusTwoBag;
		if ( mod(size,columns) == 2 ) then
			isPlusTwoBag = 1;
		end

		-- Bag background display stuff
		if ( isPlusTwoBag ) then
			bgTextureTop:SetTexCoord(0, 1, 0.189453125, 0.330078125);
			bgTextureTop:SetHeight(72);
		else
			if ( rows == 1 ) then
				-- If only one row chop off the bottom of the texture
				bgTextureTop:SetTexCoord(0, 1, 0.00390625, 0.16796875);
				bgTextureTop:SetHeight(86);
			else
				bgTextureTop:SetTexCoord(0, 1, 0.00390625, 0.18359375);
				bgTextureTop:SetHeight(94);
			end
		end
		-- Calculate the number of background textures we're going to need
		bgTextureCount = ceil(remainingRows/ROWS_IN_BG_TEXTURE);
		
		local middleBgHeight = 0;
		-- If one row only special case
		if ( rows == 1 ) then
			bgTextureBottom:SetPoint("TOP", bgTextureMiddle:GetName(), "TOP", 0, 0);
			bgTextureBottom:Show();
			-- Hide middle bg textures
			for i=1, MAX_BG_TEXTURES do
				getglobal(name.."BackgroundMiddle"..i):Hide();
			end
		else
			-- Try to cycle all the middle bg textures
			local firstRowPixelOffset = 9;
			local firstRowTexCoordOffset = 0.353515625;
			for i=1, bgTextureCount do
				bgTextureMiddle = getglobal(name.."BackgroundMiddle"..i);
				
				if ( remainingRows > ROWS_IN_BG_TEXTURE ) then
					-- If more rows left to draw than can fit in a texture then draw the max possible
					height = ( ROWS_IN_BG_TEXTURE*rowHeight ) + firstRowTexCoordOffset;
					bgTextureMiddle:SetHeight(height);
					bgTextureMiddle:SetTexCoord(0, 1, firstRowTexCoordOffset, ( height/BG_TEXTURE_HEIGHT + firstRowTexCoordOffset) );
					bgTextureMiddle:Show();
					remainingRows = remainingRows - ROWS_IN_BG_TEXTURE;
					middleBgHeight = middleBgHeight + height;
				else
					-- If not its a huge bag
					bgTextureMiddle:Show();
					height = remainingRows*rowHeight-firstRowPixelOffset;
					bgTextureMiddle:SetHeight(height);
					bgTextureMiddle:SetTexCoord(0, 1, firstRowTexCoordOffset, ( height/BG_TEXTURE_HEIGHT + firstRowTexCoordOffset) );
					middleBgHeight = middleBgHeight + height;
				end
				
			end
			-- Position bottom texture
			bgTextureBottom:SetPoint("TOP", bgTextureMiddle:GetName(), "BOTTOM", 0, 0);
			bgTextureBottom:Show();
		end
	
	
		-- Set the frame height
		frame:SetHeight(bgTextureTop:GetHeight()+bgTextureBottom:GetHeight()+middleBgHeight);	
		frame:SetWidth(CONTAINER_WIDTH);
		
		if itemname then
			getglobal(frame:GetName().."Name"):SetText(itemname);
			getglobal(frame:GetName().."Name"):SetJustifyH("CENTER");
		else
			getglobal(frame:GetName().."Name"):SetText("GHI");
			getglobal(frame:GetName().."Name"):SetJustifyH("LEFT");
		end
	end
	
	frame:SetID(id);
	
	local portraitButton = getglobal(frame:GetName().."PortraitButton");
	portraitButton:SetID(id);
	
	local portrait = frame:GetName().."Portrait";
	
	
	if not(frame.customIcon) then
		frame.customIcon = CreateFrame("Frame",portrait.."custom",portraitButton,"GHM_RoundIconHalf_Template");
		frame.customIcon:SetPoint("TOPLEFT",portraitButton,"TOPLEFT",0.5,-1.5);
	end
	
	--SetBagPortaitTexture(getglobal(frame:GetName().."Portrait"), 1);
	if icon and itemname then
		if string.find(strlower(icon),"interface\\icons\\") then
			SetPortraitToTexture(portrait, icon);
			frame.customIcon:Hide();
		else
			--GHI_Message("Setting up unofficial icon");
			SetPortraitToTexture(portrait, nil);
			frame.customIcon.SetIcon(frame.customIcon,icon);
			frame.customIcon:Show();
		end
	else
		SetPortraitToTexture(portrait, "Interface\\Buttons\\Button-Backpack-Up");
		frame.customIcon:Hide();
	end

	
	for j=1, size, 1 do
		local index = size - j + 1;
		local itemButton =getglobal(name.."Item"..j);
		itemButton:SetID(j);  --- old: index
		-- Set first button
		if ( j == 1 ) then
			-- Anchor the first item differently if its the backpack frame
			if ( id == 0 ) then
				itemButton:SetPoint("BOTTOMRIGHT", name, "BOTTOMRIGHT", -12, 30);
			else
				itemButton:SetPoint("BOTTOMRIGHT", name, "BOTTOMRIGHT", -12, 9);
			end
			
		else
			if ( mod((j-1), columns) == 0 ) then
				itemButton:SetPoint("BOTTOMRIGHT", name.."Item"..(j - columns), "TOPRIGHT", 0, 4);	
			else
				itemButton:SetPoint("BOTTOMRIGHT", name.."Item"..(j - 1), "BOTTOMLEFT", -5, 0);	
			end
		end

		local texture, itemCount, locked, quality, readable = GetContainerItemInfo(id, index);
		SetItemButtonTexture(itemButton, texture);
		SetItemButtonCount(itemButton, itemCount);
		SetItemButtonDesaturated(itemButton, locked, 0.5, 0.5, 0.5);

		if ( texture ) then
			ContainerFrame_UpdateCooldown(id, itemButton);
			itemButton.hasItem = 1;
		else
			local cooldown = getglobal(name.."Item"..j.."Cooldown");
			if cooldown then cooldown:Hide(); end
			itemButton.hasItem = nil;
		end
		
		itemButton.readable = readable;
		itemButton:Show();
	end
	for j=size + 1, MAX_CONTAINER_ITEMS, 1 do
		getglobal(name.."Item"..j):Hide();
	end
	
	
	
	
	-- Add the bag to the baglist
	--ContainerFrame1.bags[ContainerFrame1.bagsShown + 1] = frame:GetName();
	--updateContainerFrameAnchors();
	--frame:Show();
end




function GHI_updateContainerFrameAnchors() 
	local index = table.getn(ContainerFrame1.bags)+1;
	local frame, xOffset, yOffset, screenHeight;
	local screenWidth = GetScreenWidth();
	local containerScale = 1;
	
	frame = GHIContainerFrame1;
	
	screenHeight = GetScreenHeight() / containerScale;
	-- Adjust the start anchor for bags depending on the multibars
	xOffset = CONTAINER_OFFSET_X / containerScale;
	yOffset = CONTAINER_OFFSET_Y / containerScale;
	
	freeScreenHeight = screenHeight;
	local y = 0;
	if index > 1 then
		y = getglobal(ContainerFrame1.bags[index - 1]):GetTop();
	end
	freeScreenHeight = screenHeight - y - VISIBLE_CONTAINER_SPACING;
	
	if ( index == 1 ) then
		-- First bag
		frame:SetPoint("BOTTOMRIGHT", frame:GetParent(), "BOTTOMRIGHT", -xOffset, yOffset );
	elseif ( freeScreenHeight < frame:GetHeight() ) then
		-- Start a new column
		--column = column + 1;
		--freeScreenHeight = screenHeight - yOffset;
		local x = screenWidth - getglobal(ContainerFrame1.bags[index - 1]):GetRight();
		--GHI_Message("x: "..x);
		frame:SetPoint("BOTTOMRIGHT", frame:GetParent(), "BOTTOMRIGHT", -x-(1 * CONTAINER_WIDTH), yOffset );
	else
		-- Anchor to the previous bag
		frame:SetPoint("BOTTOMRIGHT", ContainerFrame1.bags[index - 1], "TOPRIGHT", 0, CONTAINER_SPACING);	
	end
	
	local prevBag = nil;
	if frame:IsShown() then
		prevBag = frame;
	end
	
	--	1th sec bag
	local frames = {GHIContainerFrame2,GHIContainerFrame3};
	if GHI_GetPlayerEquipmentDisplay then
		local f = GHI_GetPlayerEquipmentDisplay();
		if type(f)=="table" then
			table.insert(frames,f.parent);
		end
	end
	
	for i=1,table.getn(frames) do
		frame = frames[i];
		if frame then
			if frame:IsShown() then
				
				screenHeight = GetScreenHeight() / containerScale;
				-- Adjust the start anchor for bags depending on the multibars
				xOffset = CONTAINER_OFFSET_X / containerScale;
				yOffset = CONTAINER_OFFSET_Y / containerScale;
				
				freeScreenHeight = screenHeight;
				local y = 0;
				if prevBag then
					y = prevBag:GetTop();
				elseif index > 1 then
					y = getglobal(ContainerFrame1.bags[index - 1]):GetTop();
				end
				freeScreenHeight = screenHeight - y - VISIBLE_CONTAINER_SPACING;
				
				if prevBag then
					if ( freeScreenHeight < frame:GetHeight() ) then
						-- Start a new column
						--column = column + 1;
						--freeScreenHeight = screenHeight - yOffset;
						local x = screenWidth - prevBag:GetRight();
						--GHI_Message("x: "..x);
						frame:SetPoint("BOTTOMRIGHT", frame:GetParent(), "BOTTOMRIGHT", -x-(1 * CONTAINER_WIDTH), yOffset );
					else
						-- Anchor to the previous bag
						frame:SetPoint("BOTTOMRIGHT", prevBag, "TOPRIGHT", 0, CONTAINER_SPACING);	
					end
				elseif ( index == 1 ) then
					-- First bag
					frame:SetPoint("BOTTOMRIGHT", frame:GetParent(), "BOTTOMRIGHT", -xOffset, yOffset );
				elseif ( freeScreenHeight < frame:GetHeight() ) then
					-- Start a new column
					--column = column + 1;
					--freeScreenHeight = screenHeight - yOffset;
					local x = screenWidth - getglobal(ContainerFrame1.bags[index - 1]):GetRight();
					--GHI_Message("x: "..x);
					frame:SetPoint("BOTTOMRIGHT", frame:GetParent(), "BOTTOMRIGHT", -x-(1 * CONTAINER_WIDTH), yOffset );
				else
					-- Anchor to the previous bag
					frame:SetPoint("BOTTOMRIGHT", ContainerFrame1.bags[index - 1], "TOPRIGHT", 0, CONTAINER_SPACING);	
				end
				
				prevBag = frame;
				
			end
		end
	end

end 

function GHI_ContainerFrame_Update(frame)   
	if frame.notInit then return end;
	local id = frame:GetID();
	local frameName = frame:GetName();
	--name = "ContainerFrame1";
	--GHI_Message("updating bag: "..frameName.." id: "..id);
	local name,texture, itemCount, locked, quality, readablem, ID;
	--frame.size = 16;
	for j=1, frame.size, 1 do
		local itemButton = getglobal(frameName.."Item"..j);
		local data = GHI_GetContainerInfo(id,j);
		if type(data) == "table" then
			ID = data.ID;
			name,texture = GHI_GetItemInfo(ID);
			--texture = "Interface\\Icons\\INV_Misc_QuestionMark";
			itemCount = data.amount;
			locked = data.locked;
			quality = 0;
			readable = nil;
						
			
		else
			name = nil;
			ID = 0;
			texture = ""
			itemCount = 0;
			locked = nil;
			quality = 0;
			readable = nil;
		end
		--GetContainerItemInfo(1,2);	--GetContainerItemInfo(id, itemButton:GetID());
		
		
		SetItemButtonTexture(itemButton, texture);
		SetItemButtonCount(itemButton, itemCount);
		--locked
		SetItemButtonDesaturated(itemButton, locked, 0.5, 0.5, 0.5);
		itemButton.ID = ID;
		itemButton.number = j;
		
		if ( name ) then
			GHI_ContainerFrame_UpdateCooldown(id, itemButton);
			itemButton.hasItem = 1;
		else
			local cooldown = getglobal(frameName.."Item"..j.."Cooldown");
			if cooldown then cooldown:Hide(); end
			itemButton.hasItem = nil;
		end

		itemButton.readable = readable;
		--local normalTexture = getglobal(name.."Item"..j.."NormalTexture");
		--if ( quality and quality ~= -1) then
		--	local color = getglobal("ITEM_QUALITY".. quality .."_COLOR");
		--	normalTexture:SetVertexColor(color.r, color.g, color.b);
		--else
		--	normalTexture:SetVertexColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
		--end
		
		--[[
		local showSell = nil;
		if ( GameTooltip:IsOwned(itemButton) ) then
			if ( texture ) then
				local hasCooldown, repairCost = GameTooltip:SetBagItem(itemButton:GetParent():GetID(),itemButton:GetID());
				if ( hasCooldown ) then
					itemButton.updateTooltip = TOOLTIP_UPDATE_TIME;
				else
					itemButton.updateTooltip = nil;
				end
				
				if ( InRepairMode() and (repairCost > 0) ) then
					GameTooltip:AddLine(REPAIR_COST, "", 1, 1, 1);
					SetTooltipMoney(GameTooltip, repairCost);
					GameTooltip:Show();
				elseif ( MerchantFrame:IsShown() and not locked) then
					showSell = 1;
				end
				if ( IsShiftKeyDown() ) then
					GameTooltip_ShowCompareItem();
				end
			else
				GameTooltip:Hide();
			end
			if ( IsControlKeyDown() and itemButton.hasItem ) then
				ShowInspectCursor();
			elseif ( showSell ) then
				ShowContainerSellCursor(itemButton:GetParent():GetID(), itemButton:GetID());
			elseif ( readable ) then
				ShowInspectCursor();
			else
				ResetCursor();
			end
		end]]
	
	end
end

function GHI_ContainerFrame_UpdateCooldown(container, button)
	if not(container) or not(button) then
		return
	end
	local cooldown = getglobal(button:GetName().."Cooldown");
	-- TurtleWoW/1.12 may not instantiate the WotLK CooldownFrameTemplate
	-- child used by the original GHI XML. Cooldowns are cosmetic, so allow
	-- the container to function normally when that child is unavailable.
	if not cooldown then
		return
	end
	
	local bag = container;
	local slot = button:GetID();
		
	if  GHI_ContainerData[bag][slot] == nil then
		-- empty slot
		return;
	end
	
	local ID = GHI_ContainerData[bag][slot].ID;
	local rightClick = GHI_GetRightClickInfo(ID)
	local start, duration, enable;
	start = GHI_CooldownData[ID];
	
	if start == nil then start = 0; end
	if start > GetTime() then start = 0 end
	
	if not(type(rightClick)=="table") or not(rightClick.CD) then
		duration = 0;
		enable = 0;
	else
		duration = rightClick.CD;
		enable = 1;
	end
	
	if start + duration < GetTime() then start = 0; end
	
	CooldownFrame_SetTimer(cooldown, start, duration, enable);
	if ( duration > 0 and enable == 0 ) then
		SetItemButtonTextureVertexColor(button, 0.4, 0.4, 0.4);
	end
end

function GHI_UpdateContainers()
	GHI_ContainerFrame_Update(GHIContainerFrame1);
	GHI_ContainerFrame_Update(GHIContainerFrame2);
	GHI_ContainerFrame_Update(GHIContainerFrame3);
	GHI_ClearCountItemCatche();
end

-- 	Multible bags functions
function GHI_NextMainBagPage()
	StackSplitFrame:Hide();
	local bag = GHIContainerFrame1;
	local id = bag:GetID();
	local t = GHI_GetContainerList(1)
	local new_id = id;
	for i = 1,table.getn(t) do
		if t[i] == id then
			if not(i == table.getn(t)) then
				new_id = t[i+1]
						
			end
		end
	end
	
	if t[1] == new_id then
		GHI_BackpackLeftButton:Disable();
	else
		GHI_BackpackLeftButton:Enable();
	end
	if t[table.getn(t)] == new_id then
		GHI_BackpackRightButton:Disable();
	else
		GHI_BackpackRightButton:Enable();
	end
	
	GHI_ContainerFrame_GenerateFrame(bag,24,new_id)
	GHI_updateContainerFrameAnchors(bag);
	GHI_ContainerFrame_Update(bag);
end

function GHI_PrevMainBagPage()
	StackSplitFrame:Hide();
	local bag = GHIContainerFrame1;
	local id = bag:GetID();
	local t = GHI_GetContainerList(1)
	local new_id = id;
	for i = 1,table.getn(t) do
		if t[i] == id then
			if not(i == 1) then
				new_id = t[i-1]
						
			end
		end
	end
	
	if t[1] == new_id then
		GHI_BackpackLeftButton:Disable();
	else
		GHI_BackpackLeftButton:Enable();
	end
	if t[table.getn(t)] == new_id then
		GHI_BackpackRightButton:Disable();
	else
		GHI_BackpackRightButton:Enable();
	end
	
	GHI_ContainerFrame_GenerateFrame(bag,24,new_id)
	GHI_updateContainerFrameAnchors(bag);
	GHI_ContainerFrame_Update(bag);
end

function GHI_SelectSecBag(num,id)
	
	--	num = 1 or 2	
	--	1 if first, 2 if secound,
	--	if nil then 1
	--	id refer to the item that is the bag,
	if not(id) then return end
	local not_num = 1;
	if num == 2 or num == "2" then
		num = 2;
	else
		num = 1;
		not_num = 2;
	end
	local rc = GHI_GetRightClickInfo(id);
	if not(type(rc) == "table") then return end
	if rc.Type == "multible" then
		local i = rc.bag_index;
		if i then
			rc = rc[i];
		else 
			rc = {};
		end
	end
	
	if not(string.lower(rc.Type) == "bag") then return end;
	
	local not_frame = getglobal("GHIContainerFrame"..not_num+1);
	if not_frame then
		
		local info = GHI_GetContainerInfo(not_frame:GetID(),0);
		--GHI_Message(not_frame:GetID().." -> "..type(info));
		if type(info) == "table" then
			
			if info.item_id == id then -- the ietm is already shown
				return;
			end
		end
	end
	
	local bag_id = nil;
	local bags = GHI_GetContainerList(2);
	local len = table.getn(bags);
	if len == 0 then
		bag_id = 201;
	else
		for i = 1,len do
			local info = GHI_GetContainerInfo(bags[i],0);
			if type(info)=="table" then
				
				if info.item_id == id then
					bag_id = bags[i];
					break;
				end
			end
		end
	end 
	if bag_id == nil then
		local last = 200;
		for i = 1,len do
			local n = bags[i];
			if n > last+1 then
				bag_id = last+1;
				break;
			end
			last = n;
		end
		if bag_id == nil then
			bag_id = bags[len]+1;
		end
	end
	local info = GHI_GetContainerInfo(bag_id,0);
	if not(type(info)=="table") then 
		info = {};
	end
	info.item_id = id;
	info.size = rc.size;
	GHI_SetContainerInfo(bag_id,0,info)
	
	
	local frame = getglobal("GHIContainerFrame"..num+1);
	GHI_ContainerFrame_GenerateFrame(frame, rc.size, bag_id,id)
	frame:Show();
	
end

function GHI_MaintainMainBags()
	local l = GHI_GetContainerList(1);
	if table.getn(l) == 0 then
		GHI_ContainerData[101]={};
		l[1] = 101;
	end
	
	
	local bag = GHIContainerFrame1;
	local id = bag:GetID();
	--  Garher bags
	local lastInserted = 0;
	local lastNum = 100;
	local secoundLastBagFilled = false;
	local removed = 0;
		
	for i = 1,table.getn(l) do
		local num = l[i];
		local empty = true;
		local size = GHI_GetContainerSize(num);
		local filledSlots = 0;
		for j = 1,size do
			local info = GHI_GetContainerInfo(num,j);
			if info then
				empty = false;
				filledSlots = filledSlots + 1;
			end
		end
		
		
		if empty == true and not(i == table.getn(l)) then  
			GHI_ContainerData[num] = nil;
			if num == id then
				id = num-1;
			end
		elseif num > lastNum+1 then	-- if jumps (nil bags)  
			--GHI_Message("Moving bag "..num);
			GHI_ContainerData[lastNum+1] = GHI_ContainerData[num];
			GHI_ContainerData[num] = nil;
			lastNum = lastNum+1;
			if num == id then
				id = lastNum;
			end
		else
			lastNum = num;
		end
		--GHI_Message(filledSlots.." > "..(size/2).." and "..i.." == "..table.getn(l)-1)
		if filledSlots > (size/2) and i == table.getn(l) then
			GHI_ContainerData[num+1] = {};	
			removed = 1;
		end
		
		if filledSlots > (size/2) and i == table.getn(l)-1 then
			secoundLastBagFilled = true;	
		end
		--GHI_Message(filledSlots.."== 0 and "..type(secoundLastBagFilled).." == false and "..i.." == "..table.getn(l))
		if filledSlots == 0 and secoundLastBagFilled == false and i == table.getn(l) and not(i==1) then --GHI_Message("remove "..num);
			GHI_ContainerData[num] = nil;
			removed = -1;
		end
		
	end
	
	bag:SetID(id);
	if l[1] == id then
		GHI_BackpackLeftButton:Disable();
	else
		GHI_BackpackLeftButton:Enable();
	end
	if l[table.getn(l)+removed] == id then
		GHI_BackpackRightButton:Disable();
	else
		GHI_BackpackRightButton:Enable();
	end
	
end

--[[ Sec bag limitations
	1 pr stack
	only one of each ID
]]


--- ===============  Duration functions ================

function SetContainerDurationInfo(container,slot,data1,data2)
	if not(container) or not(slot) then 
		return nil;
	end
	container = tonumber(container);
	slot = tonumber(slot);
	if not(container) or not(slot) then 
		return nil;
	end
	if not(type(GHI_ContainerData) == "table") then
		GHI_ContainerData = {};
	end
	
	
	if not(type(GHI_ContainerData[container])=="table") then
		GHI_ContainerData[container] = {};
	end
	if not(type(GHI_ContainerData[container][slot])=="table") then
		GHI_ContainerData[container][slot] = {};
	end
	GHI_ContainerData[container][slot].data1 = data1;
	GHI_ContainerData[container][slot].data2 = data2;

end


function GetContainerDurationInfo(container,slot)
	if not(container) or not(slot) then
		return nil;
	end
	container = tonumber(container);
	slot = tonumber(slot);
	if not(container) or not(slot) then
		return nil;
	end
	if not(type(GHI_ContainerData) == "table") then
		GHI_ContainerData = {};
	end
	
	if not(type( GHI_ContainerData[container])=="table") then
		return nil
	end
	if not(type( GHI_ContainerData[container][slot])=="table") then
		return nil
	end
	
	local data1 = GHI_ContainerData[container][slot].data1;
	local data2 = GHI_ContainerData[container][slot].data2;
	
	return data1,data2;
end

GHI_DurationWatchlist = {};
GHI_DurtaionWlTimeRange = 60*1
function GHI_UpdateDurationWatchlist()
	
	local T = {};
	GHI_DurationWatchlist = {};
	for index1,value1 in pairs(GHI_ContainerData) do 
		if type(value1) == "table" then
			for index2,value2 in pairs(value1) do 
				if type(value2) == "table" then
					if value2.data1 then
						local _,Type = GetDurationInfo(value2.ID)
						--tinsert(GHI_DurationWatchlist,1);
						if Type == "real_time" then
							local Time = GetContainerDurationInfo(index1,index2);
							T = {};
							T.Time = floor(Time);
							T.bag = index1;
							T.slot = index2;
							if Time <= GetTime() then
								--GHI_Message("Delete "..index1..": "..index2);
								GHI_DeleteItem(nil,0,index1,index2);
							elseif Time <= GetTime() + GHI_DurtaionWlTimeRange then
								--GHI_Message("Place on list "..index1..": "..index2.." Time: "..T.Time.." Time left: "..T.Time-GetTime());
								tinsert(GHI_DurationWatchlist,T);
							end
							--tinsert(GHI_DurationWatchlist,T);
						elseif Type == "played_time" then
							local Time = GetContainerDurationInfo(index1,index2);
							Time = Time + GHI_StartedPlayedTime
							T = {};
							T.Time = floor(Time);
							T.bag = index1;
							T.slot = index2;
							if Time <= GetTime() then
								--GHI_Message("Delete "..index1..": "..index2);
								GHI_DeleteItem(nil,0,index1,index2);
							elseif Time <= GetTime() + GHI_DurtaionWlTimeRange then
								--GHI_Message("Place on list "..index1..": "..index2);
								tinsert(GHI_DurationWatchlist,T);
							end
							--tinsert(GHI_DurationWatchlist,T);
						elseif Type == "charges" then
						
						end
					end
				end
			end
		end
	end
end

function GHI_DeleteDurationWatchlistItems()
	local t = floor(GetTime());
	for i = 1,table.getn(GHI_DurationWatchlist) do
		local tab = GHI_DurationWatchlist[i];
		if type(tab) == "table" then 
			if tab.Time == t then 
				
				GHI_DeleteItem(nil,0,tab.bag,tab.slot);
			end
		end
	end
	
end


-- 	On click

function GHI_ContainerFrameItemButton_OnLoad()
	
	
	this:RegisterForDrag("LeftButton", "RightButton");
	this:RegisterForClicks("LeftButtonUp", "RightButtonUp");

end

function GHI_ContainerFrameItemButton_OnDragStop()
    -- The source button receives OnDragStop even though GHI cleared Blizzard's
    -- native cursor.  Give external GHI-aware targets a chance to consume the
    -- virtual item before normal cursor cleanup/deletion behavior occurs.
    if type(GHI_TryExternalCursorDrop) == "function" then
        GHI_TryExternalCursorDrop();
    end
end

function GHI_ContainerFrameItemButton_OnClick(button) 
	if ( button == "LeftButton" ) then
		
		if ( not GHI_IsModifierKeyDown() ) then
			local Type, details = GHI_GetCursor();
			if Type == "item" then
				GHI_PlaceContainerItem(this);
				
			elseif Type=="edit" then
				local bag = this:GetParent():GetID();
				local slot = this.number;
				GHI_StartCreateItem("edit",bag,slot);
				GHI_SetCursor("none");
			elseif Type=="copy" then
				--GHI_Message("Copy 1 "..this:GetName());
				-- See post click function
				
				--[[
				this.SplitStack = function(button, split)
					SplitContainerItem(button:GetParent():GetID(), button:GetID(), split);
				end
				OpenStackSplitFrame(this.count, this, "BOTTOMRIGHT", "TOPRIGHT");
				
				local link = GHI_GenerateLink(this.ID);
				--SWM_Message("Link: '"..link.."'");
				if ( not ChatEdit_InsertLink(link) ) then
					local texture, itemCount, locked = GetContainerItemInfo(this:GetParent():GetID(), this:GetID());
					if ( not locked ) then
						this.SplitStack = function(button, split)
							SplitContainerItem(button:GetParent():GetID(), button:GetID(), split);
						end
						OpenStackSplitFrame(this.count, this, "BOTTOMRIGHT", "TOPRIGHT");
					end
				
					
				end]]
				
				--StackSplitOkayButton
			elseif Type =="copied_item" then
				local bag = this:GetParent():GetID();
				local slot = this.number;
				local id = details.id;
				local amount = details.amount;
				local amountLeft = GHI_PlaceCopiedItem(bag,slot,id,amount,details.renewID);
				if amountLeft > 0  then
					details.amount = amountLeft;
					GHI_SetCursor("copied_item",details);
				else
					GHI_SetCursor("none");
				end
				GHI_UpdateDurationWatchlist();
			elseif Type =="choose_item" then
				local bag = this:GetParent():GetID();
				local slot = this.number;
				local info = GHI_GetContainerInfo(bag,slot);
				
				GHI_GiveFeedback(info.ID);
			elseif Type == "inspect" then
				-- Inspect is a persistent cursor mode. Clicking an item should inspect it,
				-- not fall through to the normal pickup path and cancel the mode.
				-- Refresh the tooltip immediately so both click-to-inspect and hover-to-
				-- inspect behave correctly on TurtleWoW.
				if this.ID and this.ID ~= 0 then
					GHI_ContainerFrameItemButton_OnEnter(this);
				end
			else
				GHI_ResetCursor();
				GHI_PickupContainerItem(this,0);
			end
			
			StackSplitFrame:Hide();
		
		end
	else
		if ( MerchantFrame:IsShown() and MerchantFrame.selectedTab == 2 ) then
			-- Don't sell the item if the buyback tab is selected
			return;
		end
		if ( MerchantFrame:IsShown() and IsShiftKeyDown() ) then
			--GHI_Message("stack");
			-- TODO: Fix it   
			--	is this even being run?
			---this.SplitStack = function(button, split)
			--	SplitContainerItem(button:GetParent():GetID(), button:GetID(), split);
			--	MerchantItemButton_OnClick("LeftButton");
			--end
			--OpenStackSplitFrame(this.count, this, "BOTTOMRIGHT", "TOPRIGHT");
		else
			-- Shift-click is used for auto-looting and socketing
			if not(GHI_GetCursor()=="none") then		
				GHI_ResetCursor();
			else
				local info = GHI_GetContainerInfo(this:GetParent():GetID(), this.number);
				if (type(info) == "table") then
					local ID = info.ID;
					local click = GHI_GetRightClickInfo(ID);
					local isBag = false;
					if type(click) == "table" then
						if click.Type == "multible" then
							local i = click.bag_index;
							if i then
								isBag = true;
							end
						end
						if click.Type == "bag" then
							isBag = true;
						end
					end
					
					if TradeFrame:IsShown() and isBag == false then
						local slot = nil;
						for i=1,6 do
							if GHI_TradeItemsPlayer[i] == nil then
								slot = i;
								break;
							end
						end
						if not(slot == nil) then
							GHI_PickupContainerItem(this,0);  
							GHI_ClickTradeButton(slot);
						end
					else
						--GHI_Message("Use item at "..this:GetParent():GetID().." : "..this.number or "nil");
						GHI_UseItem(this:GetParent():GetID(), this.number);
						
					end
					StackSplitFrame:Hide();
				end
			end
		end
	end
end

function GHI_ContainerFrameItemButton_OnModifiedClick(button)
	--GHR_Message("A");
	if ( button == "LeftButton" ) then
		--GHR_Message("B");
		local Type, details = GHI_GetCursor();
		if ( IsControlKeyDown() ) then
			--DressUpItemLink(GetContainerItemLink(this:GetParent():GetID(), this:GetID()));
		elseif ( IsShiftKeyDown() ) then
			
			local link = GHI_GenerateLink(this.ID);
			--SWM_Message("Link: '"..link.."'");
			if ( not(ChatEdit_InsertLink(link)) and not(GHI_FCCC_InsertLink(link)) ) then
				local texture, itemCount, locked = GetContainerItemInfo(this:GetParent():GetID(), this:GetID());
				if ( not locked ) then
					this.SplitStack = function(button, split)
						SplitContainerItem(button:GetParent():GetID(), button:GetID(), split);
					end
					OpenStackSplitFrame(this.count, this, "BOTTOMRIGHT", "TOPRIGHT");
				end
			
				
			end
		elseif Type=="copy" then
			--GHI_Message("Copy 2 "..this:GetName());
			local ID = this.ID;
			local _,_,_,_,_,_,_,creator = GHI_GetItemInfo(ID);
			if creator == UnitName("player") or  GHI_IsCopyable(ID) == 1 then  --  
				OpenStackSplitFrame(this.count*10, this, "BOTTOMRIGHT", "TOPRIGHT");
				StackSplitOkayButton:SetText("Copy");
				GHI_SetCursor("none");
			else
				GHI_Message("You can not copy this item.");
			end
		end
	end
end


function GHI_PickupContainerItem(frame,amount)
    
	local id = frame:GetParent():GetID();
	local slot = frame.number;
	local data = GHI_GetContainerInfo(id,slot);
	--GHI_Message("picking up "..id.." "..slot.." data: "..type(data));
	
	
	if type(data)=="table" then
		if(data.locked == 1) then return end; 
		if GHI_ContainerData[id][frame.number].locked  == true then
			return;
		end
		local temp = {};
					
		--ClearCursor();
		--SetCursor("ITEM_CURSOR");
		--GHI_Message("Picking up '"..frame.ID.."' Type: "..type(frame.ID));
		local name,icon = GHI_GetItemInfo(frame.ID);
		
		temp.iconTexture = icon;
	
		--GHI_CursorIcon:SetScale(0.8);
		--GHI_CursorIcon:Show();
		--GHI_CurserHasItem = true;
		temp.ItemOrigFrame = frame;
		temp.ItemOrigBag = id;
		temp.ItemAmount = amount;
		temp.id = frame.ID;
		
		GHI_ContainerData[id][frame.number].locked = 1;
		
		--GHIClickOverlayer:Show();
		GHI_ShowSlots(true);
		GHI_SetCursor("item",temp);
		GHI_UpdateContainers()
	end
end

function GHI_PlaceContainerItem(frame)
	
	
	--GHI_ClearCursor();
	local Type,details = GHI_GetCursor();
	local CursorItemAmount = details.ItemAmount;
	local a = details.ItemOrigFrame
	local id = frame:GetParent():GetID();
	
	--GHI_Message("Details = "..type(details).." and a = "..type(a).." Type = "..Type);
	local oldPos = 0;
	if type(a) == "table" then
		oldPos = a.number;
	end
	
	local newPos = frame.number;
	local old_id = details.ItemOrigBag;
	
	local info = (GHI_GetContainerInfo(id,0) or {});
	-- check if item fits in that slot
	if (id < 100 and GHI_IsOfficialItem(details.id) == false) then
		GHI_Message("You can not place that item there.");
		return;
	elseif (GHI_IsOfficialItem(details.id) == true and GHI_IsOfficialItem(info.item_id) == false) then
		GHI_Message("You can not place that item there.");
		return;
	end
	-- check size and weight
	if not(GHI_CanPlaceItem(details.id,details.ItemAmount,id,newPos)==true) then
		return;
	end
	-- check size and weight of reverse
	local info2 = GHI_GetContainerInfo(id,newPos);
	if info2 then
		local other_itemID = info2.ID;
		local other_amount = info2.amount;
		local _,_,_,_,_,_,otherStackSize = GHI_GetItemInfo(other_itemID);
		if not(other_itemID == details.id and (details.ItemAmount + other_amount) <= otherStackSize) then
			local info3 = GHI_GetContainerInfo(old_id,0);
			if (old_id < 100 and GHI_IsOfficialItem(other_itemID) == false) then
				GHI_Message("You can not place that item there.");
				return;
			elseif (GHI_IsOfficialItem(other_itemID) == true and GHI_IsOfficialItem((info3 or {}).item_id) == false) then
				GHI_Message("You can not place that item there.");
				return;
			end
			if other_itemID then
				if not(GHI_CanPlaceItem(other_itemID,other_amount,old_id,oldPos)==true) then
					return;
				end
			end
		end
	end
	
	-- to do. what if old id or old pos is not there?
	
	
	if not(old_id) or not(oldPos) then
		return;
	end
	if GHI_ContainerData[old_id][oldPos].locked == true then 
		--return;
	end
	
	local ID = GHI_ContainerData[old_id][oldPos].ID;
	local _,_,_,_,_,_,stackSize,creater,version,rightClick = GHI_GetItemInfo(ID);
	
	local bagID = GHI_GetBagID(ID);
	if bagID == id then
		GHI_Message("You can not place that item there.");
		return
		
	end
	
	GHI_ContainerData[old_id][oldPos].locked = nil;
	
	if oldPos == newPos and id == old_id then 
		GHI_ResetCursor();
		return;
	end;
	if not(type(GHI_ContainerData[id])=="table") then
		GHI_ContainerData[id] = {};
		
	end
	
	
	if CursorItemAmount == GHI_ContainerData[old_id][oldPos].amount then
		CursorItemAmount = 0;
	end
	--GHI_Message("CIA: "..CursorItemAmount);
	local oldAmount = GHI_ContainerData[old_id][oldPos].amount;
	
	if CursorItemAmount == 0 then --  all from the orriginal slot is on the cursor
		if GHI_ContainerData[id][newPos] == nil then	--  modified OK
			GHI_ContainerData[id][newPos] = GHI_ContainerData[old_id][oldPos];
			GHI_ContainerData[old_id][oldPos] = nil;
		else
			
			if GHI_ContainerData[id][newPos].ID == GHI_ContainerData[old_id][oldPos].ID then
				
				local newAmount = GHI_ContainerData[id][newPos].amount;
				--GHI_Message(newAmount.." + "..oldAmount.." > "..stackSize);
				if newAmount + oldAmount > stackSize then 	--  modified OK
					GHI_ContainerData[id][newPos].amount = stackSize;
					GHI_ContainerData[old_id][oldPos].amount = oldAmount - (stackSize - newAmount);
					
					if GHI_ContainerData[id][newPos].data1 and GHI_ContainerData[old_id][oldPos].data1 then
						local new_data1 = (GHI_ContainerData[id][newPos].data1*newAmount + GHI_ContainerData[old_id][oldPos].data1*(stackSize-newAmount))/(stackSize);
						GHI_ContainerData[id][newPos].data1 = new_data1;
						GHI_ContainerData[id][newPos].data2 = GHI_ContainerData[old_id][oldPos].data2;
					end
				else 	--  modified OK
					GHI_ContainerData[id][newPos].amount = newAmount + oldAmount;
					
					if GHI_ContainerData[id][newPos].data1 and GHI_ContainerData[old_id][oldPos].data1 then
						local new_data1 = (GHI_ContainerData[id][newPos].data1*newAmount + GHI_ContainerData[old_id][oldPos].data1*oldAmount)/(newAmount + oldAmount);
						GHI_ContainerData[id][newPos].data1 = new_data1;
						GHI_ContainerData[id][newPos].data2 = GHI_ContainerData[old_id][oldPos].data2;
					end
					
					GHI_ContainerData[old_id][oldPos] = nil;
				end
				
			else 	--  modified OK
				local temp = GHI_ContainerData[id][newPos]
				GHI_ContainerData[id][newPos] = GHI_ContainerData[old_id][oldPos];
				GHI_ContainerData[old_id][oldPos] = temp;
			end
		end
	else
		if GHI_ContainerData[id][newPos] == nil then 	-- modified OK
			local initAmount = GHI_ContainerData[old_id][oldPos].amount;
			GHI_ContainerData[id][newPos] = {}
			GHI_ContainerData[id][newPos].ID = GHI_ContainerData[old_id][oldPos].ID;
			GHI_ContainerData[id][newPos].data1 = GHI_ContainerData[old_id][oldPos].data1;
			GHI_ContainerData[id][newPos].data2 = GHI_ContainerData[old_id][oldPos].data2;
			GHI_ContainerData[id][newPos].amount = CursorItemAmount;
			
			GHI_ContainerData[old_id][oldPos].amount = (initAmount - CursorItemAmount);
			
			
		else -- item in new pos allready
			if GHI_ContainerData[id][newPos].ID == GHI_ContainerData[old_id][oldPos].ID then
				
				local newAmount = GHI_ContainerData[id][newPos].amount;
				
				if newAmount + CursorItemAmount > stackSize then 	-- modified OK
					GHI_ContainerData[id][newPos].amount = stackSize;
					GHI_ContainerData[old_id][oldPos].amount = oldAmount - (stackSize - newAmount);
					if GHI_ContainerData[id][newPos].data1 and GHI_ContainerData[old_id][oldPos].data1 then
						local new_data1 = (GHI_ContainerData[id][newPos].data1*newAmount + GHI_ContainerData[old_id][oldPos].data1*(stackSize-newAmount))/(stackSize);
						GHI_ContainerData[id][newPos].data1 = new_data1;
						GHI_ContainerData[id][newPos].data2 = GHI_ContainerData[old_id][oldPos].data2;
					end
				else 	-- modified OK
					GHI_ContainerData[id][newPos].amount = newAmount + CursorItemAmount;
					GHI_ContainerData[old_id][oldPos].amount = oldAmount - CursorItemAmount;
					
					if GHI_ContainerData[id][newPos].data1 and GHI_ContainerData[old_id][oldPos].data1 then
						local new_data1 = (GHI_ContainerData[id][newPos].data1*newAmount + GHI_ContainerData[old_id][oldPos].data1*CursorItemAmount)/(newAmount + CursorItemAmount);
						
						GHI_ContainerData[id][newPos].data1 = new_data1;
						GHI_ContainerData[id][newPos].data2 = GHI_ContainerData[old_id][oldPos].data2;
					end
				end
				
			else
				-- do nothing
			end
		
		end
	end
	
	--GHI_CurserItemAmount = 0;
	GHI_ResetCursor();
	GHI_MaintainMainBags();
	GHI_UpdateContainers();
	GHI_UpdateDurationWatchlist();
end

function GHI_PlaceCopiedItem(bag,slot,itemID,amount,renewID)
	local name,_,_,_,_,_,stackSize,creater,version,rightClick = GHI_GetItemInfo(itemID);
	if name == nil then return 0; end;
	if GHI_IsOfficialItem(itemID) == true then return 0 end;
	
	local oldID = itemID;
	if renewID == true then
		local timeID = time() - 1200000000;
		if (timeID <= GHI_LastCreateID) then
			timeID = GHI_LastCreateID + 1;		
		end
		GHI_LastCreateID = timeID;
		local pname = UnitName("Player");
		itemID = pname.."_"..timeID;
	end
	
	--	duration
	local duration,Type,start_event = GetDurationInfo(oldID)
	if Type then
		
		if duration > 0 then
			if renewID == true then
				SetDurationInfo(itemID,duration,Type,start_event)
			end
		end
	end
	
	
	if GHI_ContainerData[bag][slot] == nil then 
		GHI_ContainerData[bag][slot] ={};
		GHI_ContainerData[bag][slot].ID = itemID;
		if amount > stackSize then
			GHI_ContainerData[bag][slot].amount = stackSize;
			amount = amount - stackSize;
		else
			GHI_ContainerData[bag][slot].amount = amount;
			amount = 0;
		end
		
		if Type == "played_time" then
			SetContainerDurationInfo(bag,slot,(GetTime()-GHI_StartedPlayedTime)  +duration,nil);
		elseif 	Type == "real_time" then
			SetContainerDurationInfo(bag,slot,GetTime()+duration,nil);
		end
	elseif GHI_ContainerData[bag][slot].ID == itemID then
		local orig_amount = GHI_ContainerData[bag][slot].amount;
		if (orig_amount + amount) > stackSize then
			GHI_ContainerData[bag][slot].amount = stackSize;
			amount = orig_amount + amount - stackSize;
		else
			GHI_ContainerData[bag][slot].amount = orig_amount + amount;
			amount = 0;
		end
		
		if Type == "played_time" then
			SetContainerDurationInfo(bag,slot,(GetTime()-GHI_StartedPlayedTime)  +duration,nil);
		elseif 	Type == "real_time" then
			SetContainerDurationInfo(bag,slot,GetTime()+duration,nil);
		end
	end
	if renewID == true then
		GHI_ItemData[itemID] = GHI_ItemData[oldID];
		--GHI_Message("Created copy of "..oldID.." as "..itemID);
	end
	
	
	
	GHI_MaintainMainBags();
	GHI_UpdateContainers()
	
	return amount;
	
end


StaticPopupDialogs["GHI_DELETE_ITEM"] = {
	text = DELETE_ITEM,
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		local Type,details = GHI_GetCursor();
		
		GHI_DeleteItem(details.ItemOrigFrame,details.ItemAmount);
		GHI_ResetCursor();
	end,
	OnCancel = function ()
		GHI_ResetCursor();
	end,
	OnUpdate = function ()
		
		if not(GHI_GetCursor() == "item") then
			StaticPopup_Hide("GHI_DELETE_ITEM");
		end
	end,
	timeout = 0,
	whileDead = 1,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1
};

function GHI_DeleteItem(frame,amount,bag,Pos)
	if not(Pos) then
		Pos = frame.number;
	end
	if not(bag) then
		bag = frame:GetParent():GetID();
	end
	local info = GHI_GetContainerInfo(bag,Pos);
	if not(info) then return end;
	local ID = info.ID;
	local IsEmpty = GHI_IsBagEmpty(ID);
	if IsEmpty == false then
		GHI_Message("Please empty the bag before deleting it.");
		return;
	else
	
		if amount == GHI_ContainerData[bag][Pos].amount then amount = 0; end
		
		if amount == 0 then
			GHI_ContainerData[bag][Pos] = nil;
		else
			GHI_ContainerData[bag][Pos].amount = GHI_ContainerData[bag][Pos].amount - amount;
		end
		GHI_MaintainMainBags();
		GHI_UpdateContainers();
		
		-- search frame for item. If not delete item from data, to safe memory
		
		if not(GHI_FindItem(ID)) then
			
			GHI_ItemData[ID] = nil;
		end
	end
end

--[[
function GHI_ClearCursor(Locked)
	if not(Locked) then
		GHI_ContainerData[ 1][GHI_CurserItemOrigFrame.number].locked = nil;
	end
	GHIClickOverlayer:Hide();
	GHI_CursorIcon:Hide();
	GHI_CurserHasItem = false;
	ResetCursor();
	GHI_ContainerFrame_Update(GHIContainerFrame1);
end ]]

function GHI_ClickOverlayOnClick()
	--GHI_Message("click");
	--SWM_Message(arg1);
	local Type,details = GHI_GetCursor();
	
	if Type == "item" then
		if arg1 == "LeftButton" and type(GHI_TryExternalCursorDrop) == "function" and GHI_TryExternalCursorDrop() then
			return;
		elseif arg1 == "RightButton" then
			GHI_ResetCursor();
		elseif arg1 == "LeftButton" then
			
			--GHI_DeleteItem(GHI_CurserItemOrigFrame,GHI_CurserItemAmount);
			local id = details.ItemOrigFrame.ID;
			local name = GHI_GetItemInfo(id);
			
			if name then
				StaticPopup_Show("GHI_DELETE_ITEM",name)
			else
				StaticPopup_Show("GHI_DELETE_ITEM","Unknown")
			end
			
			 
			
		end
	elseif arg1 == "RightButton" then
		GHI_ResetCursor();
	elseif Type == nil or Type == "none" then
		this:Hide();
	end
end

function GHI_IsBagEmpty(id)
	local click = GHI_GetRightClickInfo(id);
	local isBag = false;
	if type(click)=="table" and click.Type == "multible" then
		local i = click.bag_index;
		if i then
			click = click[i];
		else 
			click = {};
		end
	end
	if type(click)=="table" and click.Type == "bag" then
		isBag = true;
		local bag_id = nil;
		local bags = GHI_GetContainerList(2);
		local len = table.getn(bags);
		for i = 1,len do
			local info = GHI_GetContainerInfo(bags[i],0);
			if type(info)=="table" then
				
				if info.item_id == id then
					bag_id = bags[i];
					break;
				end
			end
		end
		if not(bag_id == nil) then
			for i = 1,GHI_GetContainerSize(bag_id) do
				local info = GHI_GetContainerInfo(bag_id,i);
				if type(info) == "table" then
					if info.ID then
						return false, isBag;
					end
				end
			end
		end
	end
	return true,isBag;
end


function GHI_GetBagID(id)
	
	local bags = GHI_GetContainerList(2);
	local len = table.getn(bags);
	for i = 1,len do
		local info = GHI_GetContainerInfo(bags[i],0);
		if type(info)=="table" then
			
			if info.item_id == id then
				return bags[i];
			end
		end
	end
	return 0;
end

function FindItem(name)
	for bag = 0,4 do
		for slot = 1,GetContainerNumSlots(bag) do
			local item = GetContainerItemLink(bag,slot)
			if item and string.find(item,name) then
				return bag,slot;
			end
		end
	end
	
end

function EquipItem(name)
	local b,s = FindItem(name);
	PickupContainerItem(b,s);
	AutoEquipCursorItem();
end

--	Copy or Edit item - cursor
GHI_CurserType = "none";
function GHI_ContainerButtonsOnClick(button)
	if not button then
		button = this:GetName();
	end
	
	if button == "GHI_CreateItemButton" then
		GHI_SetCursor("none");
		GHI_StartCreateItem("create",nil,nil);
	else
		
	end
	if button == "GHI_EditItemButton" then
		
		if GHI_CurserType == "edit" then
			GHI_EditItemButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up");
			GHI_SetCursor("none");
		else
			GHI_EditItemButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Down");
			GHI_SetCursor("edit");
		end
	else
		GHI_EditItemButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up");
	end
	if button == "GHI_CopyItemButton" then
		if GHI_CurserType == "copy" then
			GHI_CopyItemButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up");
			GHI_SetCursor("none");
		else
			GHI_CopyItemButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Down");
			GHI_SetCursor("copy");
		end
	else
		GHI_CopyItemButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up");
	end
	if button == "GHI_HelpButton" then
		local f = GHM_NewFrame(GHI_Help_Menu); 
		f:Show();
		
		local scale = GHI_MiscData["BackpackScale"];
		if type(scale) == "number" then
			f.ForceLabel("icon_scale",scale);
		else
			f.ForceLabel("icon_scale",1.00);
		end
		
		--[[
		local buffs_disabled = GHI_MiscData["DisableBuffs"];
		
		if buffs_disabled == true then
			f.ForceLabel("disable_buffs",1);
		else
			f.ForceLabel("disable_buffs",nil);
		end
		
		local show_msg = GHI_MiscData["show_disable_msg"];
		
		if show_msg == false then
			f.ForceLabel("show_vehicle_warning",nil);
		else
			f.ForceLabel("show_vehicle_warning",1);
			
		end --]]
		
		local show_msg = GHI_MiscData["block_std_emote"];
		
		if show_msg == false then
			f.ForceLabel("block_std_emote",nil);
		else
			f.ForceLabel("block_std_emote",1);
			
		end
		
		f.ForceLabel("hide_empty_slots",GHI_MiscData["hide_empty_slots"]);
		f.ForceLabel("block_area_buff",GHI_MiscData["block_area_buff"]);
		f.ForceLabel("block_area_sound",GHI_MiscData["block_area_sound"]);
	end
	if button == "GHI_ExportItemButton" then
		if GHI_CurserType == "choose_item" then
			GHI_SetCursor("none");
			GHI_ExportItemButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up");
		else
			local t ={};
			t.cursorFeedback = function(id)
				if id then
					local g = GHM_NewFrame(GHI_ExportMenu);
					
					g.ID = id;
					g:Show();
					g.ClearAll();
					g.ExportID = GHI_GenerateID();
					g.ForceLabel("amount",1);
					GHI_SetCursor("none");
				end
			end
			GHI_SetCursor("choose_item",t);
			GHI_ExportItemButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Down");
		end
	else
		GHI_ExportItemButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up");
	end
	if button == "GHI_ImportItemButton" then
		local g = GHM_NewFrame(GHI_ImportMenu);
		g:Show();
		g.ClearAll();
		getglobal(g.GetLabelFrame("code"):GetName().."ScrollText"):SetMaxLetters(0) 
	end
	if button == "GHI_EquipmentDisplayButton" then
		GHI_ShowPlayerEquipmentDisplay();
	end
	if button == "GHI_InspectButton" then
		if GHI_CurserType == "inspect" then
			GHI_InspectButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up");
			GHI_SetCursor("none");
		else
			GHI_InspectButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Down");
			GHI_SetCursor("inspect");
		end
	else
		GHI_InspectButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up");
	end
end

--[[
function GHI_SetCursorFunction(type)
	
	if not(type) then
		return;
	end
	
	
	
	if type == "edit" then
		ClearCursor();
		SetCursor("CAST_CURSOR");
		GHI_CursorIcon:SetScale(0.8);
		GHI_CursorIcon:Hide();
		GHI_CurserHasItem = false;
		GHI_CurserType = type;
		GHIClickOverlayer:Show();
		
		
	elseif type == "copy" then
		ClearCursor();
		SetCursor("CAST_CURSOR");
		GHI_CursorIcon:SetScale(0.8);
		GHI_CursorIcon:Hide();
		GHI_CurserHasItem = false;
		GHI_CurserType = type;
		GHIClickOverlayer:Show();
		
		

	elseif type == "none" then
		SetCursor(nil);
		GHI_CurserType = type;
		GHI_CursorIcon:Hide();
		GHIClickOverlayer:Hide();
	end
	
	
	
end ]]



--	Drop item in case of picking up something else - functions
function GHI_Hooked_PickupContainerItem(bagID, slot)
	
	GHI_ResetCursor()
	
	orig_PickupContainerItem(bagID, slot);
end

function GHI_PickupAction(actionSlot)
	--	Might cause trouble with Combat Lockdown
	
	GHI_ResetCursor();
	
	orig_PickupAction(actionSlot)
end


--[[
function GHI_FCursorHasItem()
	
	if GHI_CurserHasItem then
		return 1;
	else
		return orig_CursorHasItem();
	end
	
end]]



function GHI_GetFreeSpace()
	local t = GHI_GetContainerList(1);
	if not(t) or table.getn(t) == 0 then
		GHI_ContainerData[101] = {};
		return 101,1;
	end
	for i = 1,table.getn(t) do	
		local size = GHI_GetContainerSize(t[i]);
		for j = 1,size do
			if not(GHI_GetContainerInfo(t[i],j)) then
				return t[i],j;
				
			end
		end
	end
	return nil, nil;
end

function GHI_FindItem(ID,all)
	local containers = GHI_GetContainerList();
	local result = {};
	
	for i =1,table.getn(containers) do
		local bag = containers[i];
		local size = GHI_GetContainerSize(bag);
		for j=1,size do
			local info = GHI_GetContainerInfo(bag,j);
			if info then
				if info.ID == ID then
					if all == true then
						local temp = {};
						temp.bag = bag;
						temp.slot = j;
						table.insert(result,temp);
					else
						return bag,j;
					end
				end
			end
		end
	end
	if all == true then
		return result;
	else
		return nil, nil;
	end
end


GHI_CountItemCatche = {};
function GHI_CountItem(ID)
	if type(GHI_CountItemCatche[ID])=="number" then
		return GHI_CountItemCatche[ID];
	end
	local containers = GHI_GetContainerList();
	local c = 0;
	
	for i =1,table.getn(containers) do
		local bag = containers[i];
		local size = GHI_GetContainerSize(bag);
		for j=1,size do
			local info = GHI_GetContainerInfo(bag,j);
			if info then
				if info.ID == ID then
					c = c + info.amount;
					
				end
			end
		end
	end
	
	GHI_CountItemCatche[ID] = c;
	return c;
end

function GHI_ClearCountItemCatche()
	GHI_CountItemCatche = {};
	if GHP then
		GHP:ClearCountItemCatche()
	end
end

function GHI_ClearLocked()
	local containers = GHI_GetContainerList();
	
	for i =1,table.getn(containers) do
		local bag = containers[i];
		local size = GHI_GetContainerSize(bag);
		for j=1,size do
			local info = GHI_GetContainerInfo(bag,j);
			if info then
				info.locked = nil;
				GHI_SetContainerInfo(bag,j,info);
			end
		end
	end
	GHI_UpdateContainers()
end


function GHI_BPIconMove(iconpos)
	if not GHI_BPDrag and not iconpos then return end
	if not(type(GHI_MiscData) == "table") then GHI_MiscData = {}; end
	local xpos,ypos
	if iconpos then 
		xpos = iconpos[1]
		ypos = iconpos[2]
	end
	if not xpos and not ypos then
		local x, y = GetCursorPosition();
	
		local s = GHI_BackpackButton:GetEffectiveScale();
		xpos, ypos = x/s, y/s;
		
		--xpos = xmin-xpos/Minimap:GetEffectiveScale()+70
		--ypos = ypos/Minimap:GetEffectiveScale()-ymin-70

		GHI_MiscData["BackpackPos"] = {xpos,ypos}
	end
	
	if type(GHI_MiscData) == "table" then
		local scale = GHI_MiscData["BackpackScale"];
		if type(scale) == "number" then
			GHI_BackpackButton:SetHeight(37*scale);
			GHI_BackpackButton:SetWidth(37*scale);
			
			GHI_BackpackButtonNormalTexture:SetHeight(64*scale);			
			GHI_BackpackButtonNormalTexture:SetWidth(64*scale);
		end		
	end
	
	
	GHI_BackpackButton:SetPoint("CENTER","UIParent","BOTTOMLEFT",xpos,ypos)
	--GHI_Message("Setting pos: "..xpos.." , "..ypos);
end


--	==================================== Stack Spit
function GHI_StackSplitFrameOkay_Click()
	
	if StackSplitFrame.owner and StackSplitFrame.owner:GetParent() and (strsub(StackSplitFrame.owner:GetParent():GetName() or "",0,3) == "GHI" or strsub(StackSplitFrame.owner:GetParent():GetName() or "",0,3) == "GHP") then
	
		local bag = StackSplitFrame.owner:GetParent(); --GHIContainerFrame1;
		local id = bag:GetID();
		local slot = StackSplitFrame.owner:GetID();
		
		
		local info = GHI_GetContainerInfo(id,slot);
		if StackSplitOkayButton:GetText() == "Copy" then
			--GHI_Message("Picking up "..StackSplitFrame.split.." of "..info.ID);
			local temp = {};
			local name,icon = GHI_GetItemInfo(info.ID);
			temp.iconTexture = icon;
			temp.id = info.ID;
			temp.amount = StackSplitFrame.split;
			temp.renewID = false;
			local rc = GHI_GetRightClickInfo(info.ID);
			if (type(rc) == "table") then
				if rc.Type == "multible" then
					if rc.bag_index then
						temp.renewID = true;
					end
				end
				if rc.Type and(string.lower(rc.Type) == "bag") then 
					temp.renewID = true;
				end
				--GHI_Message("temp.renewID: "..btype(temp.renewID).." type: "..string.lower(rc.Type));
			end
			GHI_SetCursor("copied_item",temp);
			
		else
			if StackSplitFrame.split == info.amount then
				GHI_PickupContainerItem(StackSplitFrame.owner,0);
			else
				GHI_PickupContainerItem(StackSplitFrame.owner,StackSplitFrame.split);
			end
		end
		StackSplitOkayButton:SetText(OKAY);
		
		StackSplitFrame:Hide();
	else
		orig_StackSplitFrameOkay_Click()
	end
end

function GHI_StackSplitFrame_OnHide(self)
	orig_StackSplitFrame_OnHide(self);
	StackSplitOkayButton:SetText("Okay");
end



--	==================================== Item tooltip 	====================================


function GHI_ContainerFrameItemButton_OnEnter(self)
	local button = this;
	
	--GHI_Message(button:GetName());
	local x;
	x = button:GetRight();
	if ( x >= ( GetScreenWidth() / 2 ) ) then
		GameTooltip:SetOwner(button, "ANCHOR_LEFT");
	else
		GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
	end

	GHI_ItemTooltip(self,button.ID) 
	this.UpdateTooltip = nil;

	--local hasCooldown, repairCost = GameTooltip:SetBagItem(button:GetParent():GetID(),button:GetID());
	
	
	--GHI_Message("ID: "..button.ID);
	--[[
	if ( hasCooldown ) then
		button.updateTooltip = TOOLTIP_UPDATE_TIME;
	else
		button.updateTooltip = nil;
	end

	if ( InRepairMode() and (repairCost and repairCost > 0) ) then
		GameTooltip:AddLine(REPAIR_COST, "", 1, 1, 1);
		SetTooltipMoney(GameTooltip, repairCost);
		GameTooltip:Show();
	elseif ( IsControlKeyDown() and button.hasItem ) then
		ShowInspectCursor();
	elseif ( MerchantFrame:IsShown() and MerchantFrame.selectedTab == 1 ) then
		ShowContainerSellCursor(button:GetParent():GetID(),button:GetID());
	elseif ( button.readable ) then
		ShowInspectCursor();
	else
		ResetCursor();
	end]]
end


function GHI_ContainerFrameItemButton_OnUpdate()
	--[[
	if ( this.updateTooltip ) then
		this.updateTooltip = this.updateTooltip - elapsed;
		if ( this.updateTooltip > 0 ) then
			--GHI_Message("C");
			return;
		end
	end
	]]
	
	--if not(GameTooltip:IsOwned(this) ) then GHI_Message("not owned"); end
	
	if ( this.updateTooltipTime ) then
		--this.updateTooltip = this.updateTooltip - elapsed;
		if ( time() - this.updateTooltipTime < 1 ) then
			--GHI_Message("C");
			return;
		end
	end
	this.UpdateTooltip = nil;
	
	--GHI_Message("A");
	if ( GameTooltip:IsOwned(this) ) then --GHI_Message("B");
		GHI_ContainerFrameItemButton_OnEnter(this);
		this.updateTooltipTime = time();
	end
end


function GHI_ItemTooltip(this,ID)
	
	GHI_SetTooltipInfo(GameTooltip,ID,this);
	GameTooltip:Show();
	--[[ if ID == 0 then 			
		GameTooltip:Hide(); 
		return;
	end
	local name,icon,quality,white1,white2,comment,stackSize,creater,version,rightClick,rightClicktext = GHI_GetItemInfo(ID);
	local info = (GHI_GetItemInfo(ID,true) or {});
	
	if name == nil then GameTooltip:Hide(); return; end;
	local bag = 0;
	if this.GetParent then
		bag = this:GetParent():GetID();
	end
	local slot;
	if this.GetID then
		slot = this:GetID();
	end
	
	local color = ITEM_QUALITY_COLORS[quality];
	local qMark = strchar(34);
	
	GameTooltip:ClearLines()
	if not(name == nil) then
		GameTooltip:AddLine(name,color.r,color.g,color.b);
	end
	if not(white1 == nil) then
		GameTooltip:AddLine(white1, 1, 1, 1);
	end
	if not(white2 == nil) then
		GameTooltip:AddLine(white2, 1, 1, 1);
	end
	
	-- GHP info
	if type(GHP)=="table" then
		GHP:ShowItemTooltipWhiteText(ID,bag,slot);
		
	end
	
	-- Requirements
	if type(rightClick) == "table" then
		
		for i = 1,table.getn(rightClick) do
			local rc = rightClick[i];
			if rc.Type and strlower(rc.Type) == "requirement" then
				local Type = rc.req_type;
				local text = rc.req_detail;
				local alias = rc.req_alias;
				
				local forfilled = GHI_CheckReq(Type,text);
				local t = "Requires ";
				
				if type(alias)=="string" and not(alias == "") then
					t = t..alias;
				else
					local suffix =GHI_GetReqSuffix(Type);
					t = t..suffix..text;
				end
				
				
				if forfilled == true then
					GameTooltip:AddLine(t, 1, 1, 1);
				else
					GameTooltip:AddLine(t, 1, 0, 0);
				end
				
			end						
		end
	
	end
	

	if not(comment == nil) then
	  if not(comment == "") then
		GameTooltip:AddLine(qMark..comment..qMark, 1.0, 0.8196079, 0,1);
	  end
	end
	
	if not(rightClicktext == nil) then 
		local color2 = ITEM_QUALITY_COLORS[2];
		GameTooltip:AddLine("Use: "..rightClicktext.."",color2.r,color2.g,color2.b);
	end
	
	if type(rightClick) == "table" then 
	  
		
		if GHI_CooldownData[ID] then
			local CD = rightClick.CD;
			if CD and (GetTime() - GHI_CooldownData[ID] < CD) and (GetTime() - GHI_CooldownData[ID] > 0) then
				local CD_remain = floor(CD - (GetTime() - GHI_CooldownData[ID]));
				
				if CD_remain < 60 then
					GameTooltip:AddLine("Cooldown remaining: "..CD_remain.." sec", 1, 1, 1);
				else
					local CD_Min = floor(CD_remain/60);
					if CD_Min < 60 then
						GameTooltip:AddLine("Cooldown remaining: "..CD_Min.." min", 1, 1, 1);
					else
						local CD_Hour = floor(CD_Min/60);
						if CD_Hour == 1 then
							GameTooltip:AddLine("Cooldown remaining: "..CD_Hour.." hour", 1, 1, 1);
						elseif CD_Hour < 24 then
							GameTooltip:AddLine("Cooldown remaining: "..CD_Hour.." hours", 1, 1, 1);
						else 
							local CD_Days = floor(CD_Hour/24);
							if CD_Days == 1 then
								GameTooltip:AddLine("Cooldown remaining: "..CD_Days.." day", 1, 1, 1);
							else
								GameTooltip:AddLine("Cooldown remaining: "..CD_Days.." days", 1, 1, 1);
							end						
						end
					end				
				end
			end
		end
	end
	
	--	duration
	
	local data1,data2 = GetContainerDurationInfo(bag,slot);
	--GHI_Message("Data1: "..type(data1));
	if data1 then
		local _,Type = GetDurationInfo(ID);
		--GHI_Message("Type: "..Type);
		if Type then
			if Type == "real_time" then
				local time_remain = floor(data1 - GetTime());
					
				if time_remain < 60 then
					GameTooltip:AddLine("Duration: "..time_remain.." sec", 1, 1, 1);
				else
					local time_Min = floor(time_remain/60);
					if time_Min < 60 then
						GameTooltip:AddLine("Duration: "..time_Min.." min", 1, 1, 1);
					else
						local time_Hour = floor(time_Min/60);
						if time_Hour == 1 then
							GameTooltip:AddLine("Duration: "..time_Hour.." hour", 1, 1, 1);
						elseif time_Hour < 24 then
							GameTooltip:AddLine("Duration: "..time_Hour.." hours", 1, 1, 1);
						else 
							local time_Days = floor(time_Hour/24);
							if time_Days == 1 then
								GameTooltip:AddLine("Duration: "..time_Days.." day", 1, 1, 1);
							elseif time_Days < 30 then
								GameTooltip:AddLine("Duration: "..time_Days.." days", 1, 1, 1);
							else
								local time_months = floor(time_Days/30);
								if time_months == 1 then
									GameTooltip:AddLine("Duration: "..time_months.." month", 1, 1, 1);
								else
									GameTooltip:AddLine("Duration: "..time_months.." months", 1, 1, 1);
								end		
							end						
						end
					end				
				end
			elseif Type == "played_time" then
				local time_remain = floor(data1 - (GetTime() - GHI_StartedPlayedTime));
					
				if time_remain < 60 then
					GameTooltip:AddLine("Duration: "..time_remain.." sec", 1, 1, 1);
				else
					local time_Min = floor(time_remain/60);
					if time_Min < 60 then
						GameTooltip:AddLine("Duration: "..time_Min.." min", 1, 1, 1);
					else
						local time_Hour = floor(time_Min/60);
						if time_Hour == 1 then
							GameTooltip:AddLine("Duration: "..time_Hour.." hour", 1, 1, 1);
						elseif time_Hour < 24 then
							GameTooltip:AddLine("Duration: "..time_Hour.." hours", 1, 1, 1);
						else 
							local time_Days = floor(time_Hour/24);
							if time_Days == 1 then
								GameTooltip:AddLine("Duration: "..time_Days.." day", 1, 1, 1);
							elseif time_Days < 30 then
								GameTooltip:AddLine("Duration: "..time_Days.." days", 1, 1, 1);
							else
								local time_months = floor(time_Days/30);
								if time_months == 1 then
									GameTooltip:AddLine("Duration: "..time_months.." month", 1, 1, 1);
								else
									GameTooltip:AddLine("Duration: "..time_months.." months", 1, 1, 1);
								end		
							end						
						end
					end				
				end
			elseif Type == "charges" then
				GameTooltip:AddLine("Duration: "..data1.."/"..data2.." charges", 1, 1, 1);
			end
		end
	end
	
	---	Duration for trade frame items
	if this.GetParent and this:GetParent():GetParent():GetName() == "TradeFrame" then
		local slot = this:GetParent():GetID();
		local a = this:GetName();
		local duration,durationType,data2;
		
		if string.sub(a,0,15) == "TradePlayerItem" and slot then
			duration = GHI_TradeItemsPlayer[slot].duration;
			durationType = GHI_TradeItemsPlayer[slot].durationType;
			data2 = GHI_TradeItemsPlayer[slot].data2;
		elseif string.sub(a,0,15) == "TradeRecipientI" and slot then
			duration = GHI_TradeItemsRecipient[slot].duration;
			durationType = GHI_TradeItemsRecipient[slot].durationType;
			data2 = GHI_TradeItemsRecipient[slot].data2;
		end
		
		if duration and durationType then
			if durationType == "real_time" or durationType == "played_time" then
				
				if duration < 60 then
					GameTooltip:AddLine("Duration: "..duration.." sec", 1, 1, 1);
				else
					local time_Min = floor(duration/60);
					if time_Min < 60 then
						GameTooltip:AddLine("Duration: "..time_Min.." min", 1, 1, 1);
					else
						local time_Hour = floor(time_Min/60);
						if time_Hour == 1 then
							GameTooltip:AddLine("Duration: "..time_Hour.." hour", 1, 1, 1);
						elseif time_Hour < 24 then
							GameTooltip:AddLine("Duration: "..time_Hour.." hours", 1, 1, 1);
						else 
							local time_Days = floor(time_Hour/24);
							if time_Days == 1 then
								GameTooltip:AddLine("Duration: "..time_Days.." day", 1, 1, 1);
							elseif time_Days < 30 then
								GameTooltip:AddLine("Duration: "..time_Days.." days", 1, 1, 1);
							else
								local time_months = floor(time_Days/30);
								if time_months == 1 then
									GameTooltip:AddLine("Duration: "..time_months.." month", 1, 1, 1);
								else
									GameTooltip:AddLine("Duration: "..time_months.." months", 1, 1, 1);
								end		
							end						
						end
					end				
					
				end
			elseif durationType == "charges" then
				GameTooltip:AddLine("Duration: "..data1.."/"..data2.." charges", 1, 1, 1);
			end
		end
	end
	
	
	
	if not(creater==nil) then
		local color2 = ITEM_QUALITY_COLORS[2];
		GameTooltip:AddLine("<Made by "..creater..">",color2.r,color2.g,color2.b);
	end
	
	if GHI_IsOfficialItem(ID) then  -- official item
		GameTooltip:AddLine("Official GH item", 0.7,0,0);
	else
		GameTooltip:AddLine("Custom made item",  0.0, 0.7, 0.5);
	end
	
	if not(GHI_AwaitingRCData[ID] == nil) then
		GameTooltip:AddLine("Not yet transfered", 0.7,0,0);
		if type(GHI_AwaitingRCDataTime[ID]) == "number" then
			local secs = GHI_AwaitingRCDataTime[ID]-time();
			if secs < 0 then secs = 0; end
			local mins = math.floor(secs/60)+1;
			GameTooltip:AddLine("Transfer time less than "..mins.." minutes.", 0.7,0,0);
		end
	end
	
	GameTooltip:Show()  --]]
end 

local function addDuration(tooltip,secs,prefix)
	if secs == 1 then
		tooltip:AddLine(prefix.." "..secs.." "..GHI_SEC_S, 1, 1, 1);
	elseif secs < 60 then
		tooltip:AddLine(prefix.." "..secs.." "..GHI_SECS_S, 1, 1, 1);
	else
		local CD_Min = floor(secs/60);
		if CD_Min == 1 then
			tooltip:AddLine(prefix.." "..CD_Min.." "..GHI_MIN_S, 1, 1, 1);
		elseif CD_Min < 60 then
			tooltip:AddLine(prefix.." "..CD_Min.." "..GHI_MINS_S, 1, 1, 1);
		else
			local CD_Hour = floor(CD_Min/60);
			if CD_Hour == 1 then
				tooltip:AddLine(prefix.." "..CD_Hour.." "..GHI_HOUR_S, 1, 1, 1);
			elseif CD_Hour < 24 then
				tooltip:AddLine(prefix.." "..CD_Hour.." "..GHI_HOURS_S, 1, 1, 1);
			else 
				local CD_Days = floor(CD_Hour/24);
				if CD_Days == 1 then
					tooltip:AddLine(prefix.." "..CD_Days.." "..GHI_DAY_S, 1, 1, 1);
				else
					tooltip:AddLine(prefix.." "..CD_Days.." "..GHI_DAYS_S, 1, 1, 1);
				end						
			end
		end				
	end
end

function GHI_SetTooltipInfo(tooltip,ID,frame)
	if ID == 0 then 			
		tooltip:Hide(); 
		return;
	end
	local name,icon,quality,white1,white2,comment,stackSize,creater,version,rightClick,rightClicktext = GHI_GetItemInfo(ID);
	local info = (GHI_GetItemInfo(ID,true) or {});
	
	if name == nil then tooltip:Hide(); return; end;
	
	
	local bag = 0;
	if frame and frame.GetParent then
		bag = frame:GetParent():GetID();
	end
	local slot = 0;
	if frame and frame.GetID then
		slot = frame:GetID();
	end
	
	local color = ITEM_QUALITY_COLORS[quality];
	local qMark = strchar(34);
	
	tooltip:ClearLines()
	if not(name == nil) then
		tooltip:AddLine(name,color.r,color.g,color.b);
	end
	if not(white1 == nil) then
		tooltip:AddLine(white1, 1, 1, 1);
	end
	if not(white2 == nil) then
		tooltip:AddLine(white2, 1, 1, 1);
	end
	
	-- GHP info
	if type(GHP)=="table" then
		GHP:ShowItemTooltipWhiteText(ID,bag,slot);
		
	end
	
	-- Requirements
	if type(rightClick) == "table" then
		
		for i = 1,table.getn(rightClick) do
			local rc = rightClick[i];
			if rc.Type and strlower(rc.Type) == "requirement" then
				local Type = rc.req_type;
				local text = rc.req_detail;
				local alias = rc.req_alias;
				
				local forfilled = GHI_CheckReq(Type,text);
				local t = GHI_REQUIRES.." ";
				local isAlias = false;
				if type(alias)=="string" and not(alias == "") then
					t = t..alias;
					isAlias = true;
				else
					local suffix = GHI_GetReqSuffix(Type);
					t = t..suffix..text;
				end
				
				if not(isAlias == true and alias == "nil") then
					if forfilled == true then
						tooltip:AddLine(t, 1, 1, 1);
					else
						tooltip:AddLine(t, 1, 0, 0);
					end
				end
			end						
		end
	
	end
	

	if not(comment == nil) then
	  if not(comment == "") then
		tooltip:AddLine(qMark..comment..qMark, 1.0, 0.8196079, 0,1);
	  end
	end
	
	if not(rightClicktext == nil or rightClicktext == "") then 
		local color2 = ITEM_QUALITY_COLORS[2];
		tooltip:AddLine(GHI_USE.." "..rightClicktext.."",color2.r,color2.g,color2.b);
	end
	
	if frame and type(rightClick) == "table" then 
	  
		
		if GHI_CooldownData[ID] then
			local CD = rightClick.CD;
			if CD and (GetTime() - GHI_CooldownData[ID] < CD) and (GetTime() - GHI_CooldownData[ID] > 0) then
				local CD_remain = floor(CD - (GetTime() - GHI_CooldownData[ID]));
				addDuration(tooltip,CD_remain,GHI_CD_LEFT);
				
			end
		end
	end
	
	--	duration
	
	local data1,data2 = GetContainerDurationInfo(bag,slot);
	--GHI_Message("Data1: "..type(data1));
	if frame and data1 then
		local _,Type = GetDurationInfo(ID);
		--GHI_Message("Type: "..Type);
		if Type then
			if Type == "real_time" then
				local time_remain = floor(data1 - GetTime());
				
				addDuration(tooltip,time_remain,GHI_DURATION);
				
			elseif Type == "played_time" then
				local time_remain = floor(data1 - (GetTime() - GHI_StartedPlayedTime));
				addDuration(tooltip,time_remain,GHI_DURATION);
				
			elseif Type == "charges" then
				tooltip:AddLine(GHI_DURATION.." "..data1.."/"..data2.." charges", 1, 1, 1);
			end
		end
	end
	
	---	Duration for trade frame items
	if frame and frame.GetParent and frame:GetParent():GetParent():GetName() == "TradeFrame" then
		local slot = frame:GetParent():GetID();
		local a = frame:GetName();
		local duration,durationType,data2;
		
		if string.sub(a,0,15) == "TradePlayerItem" and slot then
			duration = GHI_TradeItemsPlayer[slot].duration;
			durationType = GHI_TradeItemsPlayer[slot].durationType;
			data2 = GHI_TradeItemsPlayer[slot].data2;
		elseif string.sub(a,0,15) == "TradeRecipientI" and slot then
			duration = GHI_TradeItemsRecipient[slot].duration;
			durationType = GHI_TradeItemsRecipient[slot].durationType;
			data2 = GHI_TradeItemsRecipient[slot].data2;
		end
		
		if duration and durationType then
			if durationType == "real_time" or durationType == "played_time" then
				
				addDuration(tooltip,duration,GHI_DURATION);
			elseif durationType == "charges" then
				tooltip:AddLine(GHI_DURATION.." "..data1.."/"..data2.." charges", 1, 1, 1);
			end
		end
	end
	
	
	
	if not(creater==nil) then
		local color2 = ITEM_QUALITY_COLORS[2];
		tooltip:AddLine("<"..GHI_MADE_BY.." "..creater..">",color2.r,color2.g,color2.b);
	end
	
	if GHI_IsOfficialItem(ID) then  -- official item
		
		local s = GHI_OFFICIAL_MADE;
		if not(GHI_OFFICIAL_MADE) or string.len(strtrim(s)) < 6 then
			s = "Official GH item";
		end
		tooltip:AddLine(GHI_OFFICIAL_MADE, 0.7,0,0);
	else
		local s = GHI_CUSTOM_MADE;
		if not(GHI_CUSTOM_MADE) or string.len(strtrim(s)) < 6 then
			s = "Custom made item";
		end
		tooltip:AddLine(GHI_CUSTOM_MADE,  0.0, 0.7, 0.5);
	end
	
	
	
	
	if not(GHI_AwaitingRCData[ID] == nil) then
		tooltip:AddLine(GHI_NOT_TRANSFERED, 0.7,0,0);
		if type(GHI_AwaitingRCDataTime[ID]) == "number" then
			local secs = GHI_AwaitingRCDataTime[ID]-time();
			if secs < 0 then secs = 0; end
			local mins = math.floor(secs/60)+1;
			tooltip:AddLine(format(GHI_TRANSFER_TIME,mins), 0.7,0,0);
		end
	elseif GHI_GetCursor() == "inspect" then -- inspect data
		tooltip:AddLine(GHI_INSPECT_TT,0.4,0.8,1);
		local rc = GHI_GetRightClickInfo(ID) or {};
		tooltip:AddLine(format("ID: %s",ID),0.4,0.8,1);
		tooltip:AddLine(format(GHI_RC_NUM,table.getn(rc)),0.4,0.8,1);
		local t = {};
		for _,action in pairs(rc) do if type(action) == "table" and action.type_name then
			t[action.type_name] = 1 + (t[action.type_name] or 0);
		end end
		
		for actionType,count in pairs(t) do
			tooltip:AddLine(format("   %s: %s",actionType,count),0.4,0.8,1);
		end
		
		
	end
	
	
end

--	==================================== GHP Related 	====================================
function GHI_CanPlaceItem(itemID,amount,bag,slot) 
	local info = GHI_GetContainerInfo(bag,0);
	local containerID = (info or {}).item_id;
	--GHP:Msg("Testing %s or %s or %s",btype(not(info)),btype(not(containerID)),btype(GHI_IsOfficialItem(containerID) == false));
	if not(info) or not(containerID) or GHI_IsOfficialItem(containerID) == false then -- the container is not offical container
		if GHI_IsOfficialItem(itemID) == true then
			return false;
		else
			return true;
		end
	end
	
	
	
	if type(GHP)=="table" then
		-- check for the item being allowed in the bag
		
		if GHP:IsItemAllowed(bag,slot,containerID,itemID,amount,true) == false then
			return;
		end
	end
	
	return true;
end

function GHI_ProduceItem(ID,amount,ToGHP)
	local currentID = GHI_GetCurrentItem();
	assert(currentID,"GHI_ProduceItem must be executed inside a GHI item script.");
	local name,_,_,_,_,_,stackSize,creator = GHI_GetItemInfo(ID); 
	assert(name,"Could not find item information for "..(ID or "nil"));
	local _,_,_,_,_,_,_,currentCreator = GHI_GetItemInfo(currentID); 
	if GHI_IsOfficialItem(ID) == true then
		if GHI_IsOfficialItem(currentID) == false then
			GHI_Message(GHI_CAN_NOT_PRODUCE_OFFICIAL);
			return
		end
	else
		if not(creator == currentCreator) and GHI_IsCopyable(ID) == false then
			GHI_Message(GHI_CAN_NOT_PRODUCE_ITEM);
		end
	end
	
	-- ===========  Item Info ==============
	--[[
	if not official item then
		look for the item info inside currentID's item info
	
	]]--
	GHI_InsertItem(ID,amount,ToGHP)
end

function GHI_InsertItem(ID,amount,ToGHP)
	
	local bag,space;
	local t;
	if ToGHP and GHP then
		bag,space = GHI_GetGHPFreeSpace();
		t = GHP:FindItem(ID,true,true)
	else
		bag,space = GHI_GetFreeSpace(); 
		t = GHI_FindItem(ID,true); 
	end
	local _,_,_,_,_,_,stackSize = GHI_GetItemInfo(ID);
	
	if not(ID) or not(stackSize) or not(amount) then return; end; 
	local s = 0; 
	if type(t) == "table" then 
		for i=1,table.getn(t) do 
			local info = GHI_GetContainerInfo(t[i].bag,t[i].slot); 
			if info.amount then 
				if info.amount + amount <= stackSize then 
					bag=t[i].bag; 
					space=t[i].slot; 
					s = info.amount; 
					break; 
				end 
			end 
		end 
	end  
	local duration,Type,start_event=GetDurationInfo(ID);  
	while amount > 0 do 
		if bag and space then 
			if  duration and duration > 0 and start_event == "created" then 
				if Type == "played_time" then 
					SetContainerDurationInfo(bag,space,(GetTime()-GHI_StartedPlayedTime)  +duration,nil); 
				elseif Type == "real_time" then 
					SetContainerDurationInfo(bag,space,GetTime()+duration,nil); 
				end 
			end
		end 
		if amount <= stackSize then 
			if bag and space then 
				GHI_ContainerData[bag][space] = {}; 
				GHI_ContainerData[bag][space].ID = ID; 
				GHI_ContainerData[bag][space].amount = amount+s; 
				
				amount = 0; 
			else  
				amount = 0; 
			end 
		else 
			if bag and space then 
				GHI_ContainerData[bag][space] = {}; 
				GHI_ContainerData[bag][space].ID = ID; 
				GHI_ContainerData[bag][space].amount = stackSize; 
				amount = amount - stackSize; 
			else  
				amount = 0; 
			end 
			if ToGHP then
				bag,space = GHI_GetGHPFreeSpace();
			else
				bag,space = GHI_GetFreeSpace(); 
			end
		end   
	end  
	GHI_UpdateContainers();
	
end

function GHI_GetGHPFreeSpace(class)
	if GHP then
		for i = 1,GHP:GetNumberSlots() do
			local slot = GHP:GetSlot(i);
			local slotID = slot:GetID();
			if slot:IsVisible() and slot:RecieveProduced() then
				local info = (GHI_GetContainerInfo(GHP_SLOT_ID,slotID) or {});
				if not(info.ID) then -- if empty
					-- check for classes.
					-- GetAcceptedClasses
				else
					-- if contenst is a bag
						-- look trough the slots of the bag for a free slot
				end
			end
		end
		
		
		
		
	else
		return nil, nil;
	end
end




