


--	==================================== 	Trade frame	====================================
function GHI_TradeHookings()
	-- Restored original GHI virtual-item trade integration for TurtleWoW/1.12.
	-- The server trade slots remain normal WoW slots; GHI overlays/synchronizes its
	-- own virtual items between clients exactly as the original addon intended.
	local eventFrame = GHI_MF or this;
	if eventFrame then
		eventFrame:RegisterEvent("TRADE_CLOSED");
		eventFrame:RegisterEvent("TRADE_ACCEPT_UPDATE");

    if not GHI_TradeEventHooked then
        local oldOnEvent = eventFrame:GetScript("OnEvent");

        eventFrame:SetScript("OnEvent", function()

            if event == "TRADE_ACCEPT_UPDATE" then

                GHI_TradeFrame_PlayerAcceptState = tonumber(arg1) or 0;
                GHI_TradeFrame_RecipientAcceptState = tonumber(arg2) or 0;

            elseif event == "TRADE_CLOSED" then

                -- TRADE_CLOSED may fire more than once.
                if not GHI_TradeFinalized then

                    if GHI_TradeFrame_PlayerAcceptState == 1
                    and GHI_TradeFrame_RecipientAcceptState == 1 then

                        GHI_TradeFinalized = true;
                        GHI_AcceptTrade();

                    else
                        -- Trade was cancelled/closed without both accepting.
                        -- The virtual items were never removed, so only unlock them.
                        GHI_TradeItemsPlayer = {};
                        GHI_TradeItemsRecipient = {};
                        GHI_TradeLinksSend = {};

                        GHI_ClearLocked();
                        GHI_UpdateContainers();

                        GHI_TradeFrame_PlayerAcceptState = 0;
                        GHI_TradeFrame_RecipientAcceptState = 0;
                    end
                end
            end

            if oldOnEvent then
                oldOnEvent();
            end
        end);

        GHI_TradeEventHooked = true;
    end

	end


	-- Avoid double-hooking if this routine is reached more than once.
	if ClickTradeButton ~= GHI_ClickTradeButton then
		Orig_ClickTradeButton = ClickTradeButton;
		ClickTradeButton = GHI_ClickTradeButton;
	end

	if TradeFrame_UpdatePlayerItem ~= GHI_TradeFrame_UpdatePlayerItem then
		Orig_TradeFrame_UpdatePlayerItem = TradeFrame_UpdatePlayerItem;
		TradeFrame_UpdatePlayerItem = GHI_TradeFrame_UpdatePlayerItem;
	end

	if TradeFrame_UpdateTargetItem ~= GHI_TradeFrame_UpdateRecipientItem then
		Orig_TradeFrame_UpdateRecipientItem = TradeFrame_UpdateTargetItem;
		TradeFrame_UpdateTargetItem = GHI_TradeFrame_UpdateRecipientItem;
	end

	local function HookPlayerButton(button)
		if not button then return; end
		local oldEnter = button:GetScript("OnEnter");
		button:SetScript("OnEnter", function()
			if oldEnter then oldEnter(); end
			if this and this.GetParent and this:GetParent() then
				GHI_TradeItemButtonOnEnter(this:GetParent():GetID());
			end
		end);

		local oldUpdate = button:GetScript("OnUpdate");
		button:SetScript("OnUpdate", function()
			if oldUpdate then oldUpdate(); end
			GHI_TradeItemButtonOnUpdate(arg1 or 0);
		end);
	end

	local function HookRecipientButton(button)
		if not button then return; end
		local oldEnter = button:GetScript("OnEnter");
		button:SetScript("OnEnter", function()
			if oldEnter then oldEnter(); end
			if this and this.GetParent and this:GetParent() then
				GHI_RecipientTradeItemButtonOnEnter(this:GetParent():GetID());
			end
		end);

		local oldUpdate = button:GetScript("OnUpdate");
		button:SetScript("OnUpdate", function()
			if oldUpdate then oldUpdate(); end
			GHI_RecipientTradeItemButtonOnUpdate(arg1 or 0);
		end);
	end

	local i;
	for i = 1, 7 do
		HookPlayerButton(getglobal("TradePlayerItem"..i.."ItemButton"));
		HookRecipientButton(getglobal("TradeRecipientItem"..i.."ItemButton"));
	end

	if TradeFrame then
		local oldShow = TradeFrame:GetScript("OnShow");
        TradeFrame:SetScript("OnShow", function()
            GHI_TradeItemsPlayer = {};
            GHI_TradeItemsRecipient = {};
            GHI_TradeLinksSend = {};
            GHI_RecipientHasGHI = false;

            GHI_TradeFrame_PlayerAcceptState = 0;
            GHI_TradeFrame_RecipientAcceptState = 0;
            GHI_TradeFinalized = false;

            if oldShow then oldShow(); end
        end);
	end
end

function GHI_ClickTradeButton(slot)
	
	local Type,details = GHI_GetCursor();
		
	if (GetTradePlayerItemInfo(slot)) then --normal item
		if Type == "item" then
			if not(GHI_RecipientHasGHI == true) then
				GHI_Message(RecipientHasGHIError);
				return;
			end
			local bagSlot = details.ItemOrigFrame:GetID();
			local bag = details.ItemOrigFrame:GetParent():GetID();
				
			local ID = GHI_ContainerData[bag][bagSlot].ID;
			
			local amount = tonumber(GHI_CurserItemAmount);
			
			local isBag = GHI_IsBagEmpty(ID)
			if isBag == false then
				--GHI_Message(IsBagError);
				--return;
			end
			
			-- remove the old one
			Orig_ClickTradeButton(slot)	
			
			
			if amount == 0 then
				amount = GHI_ContainerData[bag][bagSlot].amount;
			end
			
			GHI_SetTradeButton(slot,ID,amount);
			
			GHI_TradeItemsPlayer[slot] = {};
			GHI_TradeItemsPlayer[slot].ID = ID;
			GHI_TradeItemsPlayer[slot].amount = amount;
			GHI_TradeItemsPlayer[slot].OrriginalFrame = details.ItemOrigFrame;
			GHI_TradeItemsPlayer[slot].ItemOrigBag = details.ItemOrigBag;
			
			
			GHI_ResetCursor();
			--	Lock the slot again
			GHI_ContainerData[bag][bagSlot].locked = true;
			GHI_UpdateContainers()
		else
			Orig_ClickTradeButton(slot)
		end
		
	elseif GHI_TradeItemsPlayer[slot] then  -- GHI item
		if Type == "item" then
			if not(GHI_RecipientHasGHI == true) then
				GHI_Message(RecipientHasGHIError);
				return;
			end
			local bagSlot = details.ItemOrigFrame:GetID();
			local bag = details.ItemOrigFrame:GetParent():GetID();
			
			local ID = GHI_ContainerData[bag][bagSlot].ID;
			local origFrame = details.ItemOrigFrame;
			local amount = tonumber(details.ItemAmount);
			local isBag = GHI_IsBagEmpty(ID)
			if isBag == false then
				--GHI_Message(IsBagError);
				--return;
			end
			
			if amount == 0 then
				amount = GHI_ContainerData[bag][bagSlot].amount;
			end
			
			GHI_PickupGHITradeItem(slot)
			
			GHI_SetTradeButton(slot,ID,amount);
			
			GHI_TradeItemsPlayer[slot] = {};
			GHI_TradeItemsPlayer[slot].ID = ID;
			GHI_TradeItemsPlayer[slot].amount = amount;
			GHI_TradeItemsPlayer[slot].OrriginalFrame = origFrame;
			GHI_TradeItemsPlayer[slot].ItemOrigBag = details.ItemOrigBag;
			
			GHI_ContainerData[bag][bagSlot].locked = true;
			GHI_UpdateContainers()
			
		else 
			--local cursorItem = CursorHasItem();
			
			local a = GHI_TradeItemsPlayer[slot];
			GHI_TradeItemsPlayer[slot] = nil;
			Orig_ClickTradeButton(slot);
			GHI_TradeItemsPlayer[slot] = a;
			
			GHI_PickupGHITradeItem(slot);
			
			--if not(cursorItem) then
			GHI_ClearTradeButton(slot);
            local player = GHI_TradePlayer;

            if not player or player == "" then
                player = TradeFrameRecipientNameText:GetText();
            end
			GHI_SendData("Trade<"..slot.."",0,player);  -- removes the GHI item for reciepient.
			--end
		end
	else									-- no items
		if Type == "item" then
			if not(GHI_RecipientHasGHI == true) then
				GHI_Message(RecipientHasGHIError);
				return;
			end
			
			local bagSlot = details.ItemOrigFrame:GetID();
			local bag = details.ItemOrigFrame:GetParent():GetID();
			local ID = GHI_ContainerData[bag][bagSlot].ID;
			
			local amount = tonumber(details.ItemAmount);
			local amount2;
			local BagId = GHI_GetBagID(ID)
			--GHI_Message((BagId)or "nil");
			--GHI_Message(btype(not(BagId == 0)).." and not( "..btype(tonumber(GHI_RecipientGHIVersion)).." and "..btype((tonumber(GHI_RecipientGHIVersion) >= 0.24) )); 
			--if BagId and not(BagId == 0) and not( tonumber(GHI_RecipientGHIVersion) and (tonumber(GHI_RecipientGHIVersion) >= 0.24) )  then
			local isBag = GHI_IsBagEmpty(ID)
			if isBag == false then   --todo: needs testing
				--GHI_Message(IsBagError);
				--return;
			end
			
			if amount == 0 then
				amount2 = GHI_ContainerData[bag][bagSlot].amount;
			else
				amount2 = amount;
			end
			
			
			
			
			
			GHI_TradeItemsPlayer[slot] = {};
			GHI_TradeItemsPlayer[slot].ID = ID;
			GHI_TradeItemsPlayer[slot].amount = amount2;
			
			GHI_TradeItemsPlayer[slot].OrriginalFrame = details.ItemOrigFrame;
			GHI_TradeItemsPlayer[slot].ItemOrigBag = details.ItemOrigBag;
			
			GHI_SetTradeButton(slot,ID,amount2,BagId);
			
			GHI_ResetCursor();
			--GHI_Message("Locking "..bag.." : "..bagSlot);
			GHI_ContainerData[bag][bagSlot].locked = true;
			GHI_UpdateContainers()
		else
			Orig_ClickTradeButton(slot)
		end
	end
	
	if not(slot == 7) then
		GHI_CancelAcceptTrade();
	end

	
end

function GHI_ClearTradeButton(slot)
	local itemButton = getglobal("TradePlayerItem"..slot.."ItemButton");
	
	SetItemButtonTexture(itemButton, "");
	SetItemButtonCount(itemButton, 1);
	
	getglobal(((itemButton:GetParent()):GetName()).."Name"):SetText("");
	
	getglobal("GHI_PlayerTradeType"..slot):Hide();
	getglobal("GHI_PlayerTradeType"..slot.."Label"):SetText("");
end

function GHI_SetTradeButton(slot,ID,amount,BagId)
	local name,texture = GHI_GetItemInfo(ID);
	if not(name) then return; end
	
	local itemButton = getglobal("TradePlayerItem"..slot.."ItemButton");
		
	if amount == nil then amount = 1 end;
	
	
	SetItemButtonTexture(itemButton, texture);
	SetItemButtonCount(itemButton, amount);
	
	local itemType;
	if GHI_IsOfficialItem(ID) then  -- official item
		itemType = "|CFF" ..string.format("%.2x",0.7*255) .. string.format("%.2x",0*255) .. string.format("%.2x",0*255) .."Official GH item|r"
	else
		itemType = "|CFF" ..string.format("%.2x",0.0*255) .. string.format("%.2x",0.7*255) .. string.format("%.2x",0.5*255) .."Custom made item|r"
	end
	getglobal("GHI_PlayerTradeType"..slot):Show();
	getglobal("GHI_PlayerTradeType"..slot.."Label"):SetText(itemType);
	
	getglobal(((itemButton:GetParent()):GetName()).."Name"):SetText(name);
	
	--.."\nOfficial item");
	
	
	--- Send data to Recipient
	local player = TradeFrameRecipientNameText:GetText();
	
	local send = false;
	for index,value in pairs(GHI_TradeLinksSend) do 
		if value == ID then
			send = true;
			--GHI_Message("Link already send");
		end
	end
	
	if not(GHI_IsOfficialItem(ID)) and send == false then
		table.insert(GHI_SendItemsID,1,ID);
		table.insert(GHI_TradeLinksSend,ID);
		GHI_SendLink(name,player);
		
	end
	GHI_SendData("Trade<"..slot.."",ID.."-"..amount,player);
	
	-- todo Send duration for "on trade" event
	local bag_slot = GHI_TradeItemsPlayer[slot].OrriginalFrame:GetID();
	local bag = GHI_TradeItemsPlayer[slot].ItemOrigBag;
	
	local data1,data2 = GetContainerDurationInfo(bag,bag_slot);
	local size,Type,start_event = GetDurationInfo(ID);
	if Type then
		
		local duration = 0;
		if data1 then
			if Type == "real_time" then
				duration = floor(data1 - GetTime());
					
				
			elseif Type == "played_time" then
				duration = floor(data1 - (GetTime() - GHI_StartedPlayedTime));
					
				
			elseif Type == "charges" then
				duration = data1;
			end
		elseif start_event == "traded" then
			duration = floor(size);
		end
		GHI:SendMessage("WHISPER",player, false, "TradeDuration", slot,duration,Type,data2,bagContenst);
		GHI_TradeItemsPlayer[slot].duration = duration;
		GHI_TradeItemsPlayer[slot].durationType = Type;
		GHI_TradeItemsPlayer[slot].data2 = data2;
		
	end
	
	
	-- Send info for bag contenst
	local BagDetails ={};
	local bagSize = GHI_GetContainerSize(BagId);
	for i = 1,bagSize do
		local info = GHI_GetContainerInfo(BagId,i);
		--info.ID;
		--info.amount;
		if info then
			BagDetails[i] = info;
			ID = info.ID;
			
			-- duration
			local data1,data2 = GetContainerDurationInfo(BagId,i);
			local size,Type,start_event = GetDurationInfo(ID);
			if Type then
				
				local duration = 0;
				if data1 then
					if Type == "real_time" then
						duration = floor(data1 - GetTime());
							
						
					elseif Type == "played_time" then
						duration = floor(data1 - (GetTime() - GHI_StartedPlayedTime));
							
						
					elseif Type == "charges" then
						duration = data1;
					end
				elseif start_event == "traded" then
					duration = floor(size);
				end
				
				GHI_Message("event: "..(start_event or "nil").." duration: "..duration);
				
				BagDetails[i].duration = duration;
				BagDetails[i].durationType = Type;
				BagDetails[i].data2 = data2;
			end
		end
		
		
		
		
		--  check if link send
		local send = false;
		for index,value in pairs(GHI_TradeLinksSend) do 
			if value == ID then
				send = true;
				--GHI_Message("Link already send");
			end
		end
		
		-- send links
		if not(GHI_IsOfficialItem(ID)) and send == false then
			table.insert(GHI_SendItemsID,1,ID);
			table.insert(GHI_TradeLinksSend,ID);
			local name = GHI_GetItemInfo(ID);
			GHI_SendLink(name,player);
			
		end
		
		-- close bag if open
		if GHIContainerFrame2:GetID()==BagId then
			GHIContainerFrame2:Hide();
		end
		if GHIContainerFrame3:GetID()==BagId then
			GHIContainerFrame3:Hide();
		end
		
	end
	
	
	GHI:SendMessage("WHISPER",player,false,"TradeBagInfo",slot,BagDetails)
	
	--GHI_Message("Sended "..ID.." to "..player);
end

function GHI_PickupGHITradeItem(slot)
	if not(GHI_TradeItemsPlayer[slot] == nil) then
		--ClearCursor();
		--SetCursor("ITEM_CURSOR");
		local temp = {};
		local name,icon = GHI_GetItemInfo(GHI_TradeItemsPlayer[slot].ID);
		temp.iconTexture = icon;
		temp.ID = GHI_TradeItemsPlayer[slot].ID;
		--GHI_CursorIcon:SetScale(0.8);
		--GHI_CursorIcon:Show();
		--GHI_CurserHasItem = true;
		temp.ItemOrigFrame = GHI_TradeItemsPlayer[slot].OrriginalFrame;
		temp.ItemOrigBag = GHI_TradeItemsPlayer[slot].ItemOrigBag;
		--GHI_Message("Getting original frame: "..type(temp.ItemOrigFrame));
		temp.ItemAmount = 	GHI_TradeItemsPlayer[slot].amount;
		GHI_SetCursor("item",temp);
		
		--GHIClickOverlayer:Show();
		
		GHI_TradeItemsPlayer[slot] = nil;
	end
end

function GHI_TradeFrame_UpdatePlayerItem(slot)
	
	if not(GHI_TradeItemsPlayer[slot]) then
		Orig_TradeFrame_UpdatePlayerItem(slot)
		if slot < 7 then
			getglobal("GHI_PlayerTradeType"..slot):Hide();
		end
	end
end

function GHI_TradeItemButtonOnEnter(slot)
	if (GHI_TradeItemsPlayer[slot]) then
		
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
		
		local ID = GHI_TradeItemsPlayer[slot].ID;
		GHI_ItemTooltip(this,ID)
		
		CursorUpdate();
	end
end

function GHI_TradeItemButtonOnUpdate(elapsed)
	if ( this.updateTooltip ) then
		this.updateTooltip = this.updateTooltip - elapsed;
		if ( this.updateTooltip > 0 ) then
			return;
		end
	end

	if ( GameTooltip:IsOwned(this) ) then
		GHI_TradeItemButtonOnEnter(this:GetParent():GetID());
	end
end

function GHI_RecieveTradeItem(slot,data,player)
	
	slot = tonumber(slot);
	if tonumber(data) == 0 then
		GHI_ClearRecipientButton(slot);
		GHI_TradeItemsRecipient[slot] = {};
		return;
	end
	
	local a = string.find(data,"-");
	--GHR_Message(slot);
	
	if not(a) then return end
	local ID = string.sub(data,0,a-1);
	local amount = tonumber(string.sub(data,a+1));
	
	if not(ID) or not(amount) then return end;
	--GHI_Message(ID..": "..amount);
	GHI_SetRecipientButton(slot,ID,amount)
	
	GHI_TradeItemsRecipient[slot] = {};
	GHI_TradeItemsRecipient[slot].ID = ID;
	GHI_TradeItemsRecipient[slot].amount = amount;
	
end

function GHI_RecieveTradeDuration(slot,duration,durationType,data2)
	
	slot = tonumber(slot);
	GHI_TradeItemsRecipient[slot].duration = duration;
	GHI_TradeItemsRecipient[slot].durationType = durationType;
	GHI_TradeItemsRecipient[slot].data2 = data2;
	
	
end

function GHI_SetRecipientButton(slot,ID,amount)
	local name,texture = GHI_GetItemInfo(ID);
	if not(name) then return; end
	
	
	local itemButton = getglobal("TradeRecipientItem"..slot.."ItemButton");
	
	if amount == nil then amount = 1 end;
	
	
	SetItemButtonTexture(itemButton, texture);
	SetItemButtonCount(itemButton, amount);
	
	local itemType;
	if GHI_IsOfficialItem(ID) then  -- official item
		itemType = "|CFF" ..string.format("%.2x",0.7*255) .. string.format("%.2x",0*255) .. string.format("%.2x",0*255) .."Official GH item|r"
	else
		itemType = "|CFF" ..string.format("%.2x",0.0*255) .. string.format("%.2x",0.7*255) .. string.format("%.2x",0.5*255) .."Custom made item|r"
	end
	
	getglobal(((itemButton:GetParent()):GetName()).."Name"):SetText(name);
	
	getglobal("GHI_RecipientTradeType"..slot):Show();
	getglobal("GHI_RecipientTradeType"..slot.."Label"):SetText(itemType);
	
	GHI_CancelAcceptTrade();
end

function GHI_ClearRecipientButton(slot)
	local itemButton = getglobal("TradeRecipientItem"..slot.."ItemButton");
	
	SetItemButtonTexture(itemButton, "");
	SetItemButtonCount(itemButton, 1);
	
	getglobal(((itemButton:GetParent()):GetName()).."Name"):SetText("");
	
	getglobal("GHI_RecipientTradeType"..slot):Hide();
	getglobal("GHI_RecipientTradeType"..slot.."Label"):SetText("");
	GHI_CancelAcceptTrade();
	
end

function GHI_RecipientTradeItemButtonOnEnter(slot)
	if (GHI_TradeItemsRecipient[slot]) then
		
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
		
		local ID = GHI_TradeItemsRecipient[slot].ID;
		GHI_ItemTooltip(this,ID)
		
		CursorUpdate();
	end
end

function GHI_RecipientTradeItemButtonOnUpdate(elapsed)
	if ( this.updateTooltip ) then
		this.updateTooltip = this.updateTooltip - elapsed;
		if ( this.updateTooltip > 0 ) then
			return;
		end
	end

	if ( GameTooltip:IsOwned(this) ) then
		GHI_RecipientTradeItemButtonOnEnter(this:GetParent():GetID());
	end
end

function GHI_TradeFrame_UpdateRecipientItem(slot)
	
	if not(GHI_TradeItemsRecipient[slot]) then
		Orig_TradeFrame_UpdateRecipientItem(slot)
		if slot < 7 then
			getglobal("GHI_RecipientTradeType"..slot):Hide();
		end
	end
	if slot == 1 then
		GHI_RecipientHasGHI = false;
		local player = TradeFrameRecipientNameText:GetText();
		GHI_SendData("AddonVersionReq",nil,player)
		GHI_TradePlayer = player;
	end
end


function GHI_RecieveTradeBagDetails(slot,details)
	GHI_TradeItemsRecipient[slot].bagDetails = details;
	
end

GHI_TradeOverFlow = {}

function GHI_CancelAcceptTrade()
	local n = GetPlayerTradeMoney();
	SetTradeMoney(1); 
	SetTradeMoney(n);
end

function GHI_AcceptTrade()
	local player = TradeFrameRecipientNameText:GetText();
	--GHR_Message(player);
	--  Delete items traded away
	local ID,amount;
	for i = 1,6 do
		if GHI_TradeItemsPlayer[i] then
			ID = GHI_TradeItemsPlayer[i].ID;
			amount = GHI_TradeItemsPlayer[i].amount;
			
			if ID and amount then
				local amountLeft = amount;
				local bag, slot;
				
				local slot = GHI_TradeItemsPlayer[i].OrriginalFrame:GetID();
				local bag = GHI_TradeItemsPlayer[i].ItemOrigBag;
				
				local slotAmount = GHI_ContainerData[bag][slot].amount;
						
				if amountLeft < slotAmount then
					GHI_ContainerData[bag][slot].amount = slotAmount - amountLeft;
					amountLeft = 0;
				else
					GHI_ContainerData[bag][slot] = nil;
					amountLeft = amountLeft - slotAmount;
				end
				
				while amountLeft > 0 do
					
					bag, slot = GHI_FindItem(ID);
					if bag and slot then
						local slotAmount = GHI_ContainerData[bag][slot].amount;
						
						if amountLeft < slotAmount then
							GHI_ContainerData[bag][slot].amount = slotAmount - amountLeft;
							amountLeft = 0;
						else
							GHI_ContainerData[bag][slot] = nil;
							amountLeft = amountLeft - slotAmount;
						end
					else
						GHI_Message("Could not find all items");
						break;
					end
					
				end
				
				-- if bag then delete it from the bag array
				if not(GHI_FindItem(ID)) then
			
					--  GHI_ItemData[ID] = nil;  Dont remove the item data. The recipient is still about to ask for it
					local bagID = GHI_GetBagID(ID);
					if not(bagID == 0) then
						GHI_ContainerData[bagID] = {};
					end
				end
			end			
		end
	end
	
	
	
	
	-- insert recieved items.
	local ID,amount,bag,space;
	local msgFlag = 0;
	
	for i = 1,6 do
		if GHI_TradeItemsRecipient[i] then
			ID = GHI_TradeItemsRecipient[i].ID;
			amount = GHI_TradeItemsRecipient[i].amount;
			
			if ID and amount then
				
				--	Get item data from the recipient, by sending own version number of the item data.
				if not(GHI_IsOfficialItem(ID)) then
					
					local v1,v2 = GHI_GetVersions(ID);
					GHI:SendMessage("WHISPER",player,false,"ItemDataVersions",ID,v1,v2)
				end
				
				--	Insert bags
				local bagDetails = GHI_TradeItemsRecipient[i].bagDetails;
				
				local bag_id = nil;
				local bags = GHI_GetContainerList(2);
				local len = table.getn(bags);
				if len == 0 then
					bag_id = 201;
				else
					for i = 1,len do
						local info = GHI_GetContainerInfo(bags[i],0);
						if type(info)=="table" then
							
							if info.item_id == ID then
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
				
				if type(bagDetails) == "table" and not(bagDetails == {}) then -- handle multi items in bag?
					GHI_SetContainerInfo(bag_id,0,{["item_id"]=ID});
					for index,value in pairs(bagDetails) do 
						--GHI_Message(index..": "..(value.ID or "nil"));
						
						--	Get item data from the recipient, by sending own version number of the item data.
						if not(GHI_IsOfficialItem(value.ID)) then
							local v1,v2 = GHI_GetVersions(value.ID);
							GHI:SendMessage("WHISPER",player,false,"ItemDataVersions",value.ID,v1,v2)
						end
						
						--	to do: set duration
						local data1;
						local duration = value.duration;
						local Type = value.durationType;
						if Type == "real_time" then
							data1 = floor(duration + GetTime());
								
							
						elseif Type == "played_time" then
							data1 = floor(duration + (GetTime() - GHI_StartedPlayedTime));
								
							
						elseif Type == "charges" then
							data1 = duration;
						end
						if data1 then
							value.data1 = data1;
							value.duration = nil;
						end
						
						GHI_SetContainerInfo(bag_id,index,value);
					end
				end
				
				
				--	Insert
				bag,space = GHI_GetFreeSpace();
				if bag and space then
					GHI_ContainerData[bag][space] = {};
					GHI_ContainerData[bag][space].ID = ID;
					GHI_ContainerData[bag][space].amount = amount;
					
					-- Duration
					local duration = GHI_TradeItemsRecipient[i].duration;
					local durationType = GHI_TradeItemsRecipient[i].durationType;
					local data2 = GHI_TradeItemsRecipient[i].data2;
					if durationType == "real_time" then
						duration = GetTime()  + duration;
					elseif durationType == "played_time" then
						duration = (GetTime()-GHI_StartedPlayedTime)  +duration;
					end
					SetContainerDurationInfo(bag,space,duration,data2);
				else
					if msgFlag == 0 then
						GHI_Message("Your bags are full, please clear out your bags");
					end
					local array = {}
					array.ID = ID;
					array.amount = amount;
					table.insert(GHI_TradeOverFlow,array);
				end
			end			
		end
	end
	
	GHI_MaintainMainBags();
	GHI_UpdateContainers()
	
	GHI_TradeFrame_PlayerAcceptState = 0;
	GHI_TradeFrame_RecipientAcceptState = 0;
	
	GHI_TradeItemsPlayer = {}
	GHI_TradeItemsRecipient = {}
	GHI_TradeLinksSend = {};
	GHI_ClearLocked();
	
end
