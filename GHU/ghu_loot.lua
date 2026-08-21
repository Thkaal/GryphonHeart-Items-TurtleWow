

GHU_Loot = CreateFrame("frame");
GHU_Loot.__index = GHU_Loot;
GHU_Loot.hooked ={};

-- 	standard
function GHU_Loot:Create(varName)
		
	setglobal(varName,GHU_Loot); 
	
	local obj = {}             -- our new object
	setmetatable(obj, getglobal(varName))  -- make GHU_Loot handle lookup
	
	-- obj.variable = value
	
	setglobal(varName,obj);
	
	obj:InitHooks(varName);  
	
	GHU_Loot:SetScript("OnEvent", function() GHU_Loot:OnEvent(); end);
	GHU_Loot:RegisterEvent("LOOT_SLOT_CLEARED");
	
	
end
	
function GHU_Loot:Hook(funcName,varName)
	
	if not(type(self.orig)=="table") then self.orig ={}; end
	assert(type(self[funcName])=="function","No function found for "..funcName);
	self.orig[funcName] = getglobal(funcName);
		
	local hookObject = getglobal(varName);
	hookObject.hooked[funcName] = function(...)
		gself = getglobal(varName);
		local hookTarget = getglobal(varName);
		return hookTarget[funcName](hookTarget, unpack(arg));
	end
	setglobal(funcName,getglobal(varName)["hooked"][funcName]);
end

function GHU_Loot:InitHooks(varName)
	if not(self.isHooked) then
		local obj = getglobal(varName);
		
		self:Hook("GetNumLootItems",varName)
		self:Hook("GetLootSlotInfo",varName)
		self:Hook("LootSlotIsItem",varName)
		self:Hook("LootSlotIsCoin",varName)
		self:Hook("LootSlot",varName)
		self:Hook("CloseLoot",varName);
		self:Hook("LootItem_OnEnter",varName);
		
		
		LootCloseButton:SetScript("OnClick",function() OverRule = true; HideUIPanel(LootFrame); OverRule = false; end);
		local Old_Script = WorldFrame:GetScript("OnUpdate");
		WorldFrame:SetScript("OnUpdate", function() if Old_Script then Old_Script(); end; self:OnWF(); end);
	
		self.isHooked = true;
	end
end

function GHU_Loot:OnEvent()
	--GHI_Message("Loot event");
	LootFrame_Update(); 
end

-- Hooking
function GHU_Loot:OnWF()
	self.wfCount = (self.wfCount or 0)+1;
	if self.wfCount == 10 then
		local x,y = GetPlayerMapPosition("player");
		if not(x==self.prevX) or not(y==self.prevY) then
			if not(self:StayOpenOnMove()) and self.orig.GetNumLootItems() == 0 then
				OverRule = true; HideUIPanel(LootFrame); OverRule = false;
			end
		end
		
		self.wfCount = 0;
		self.prevX = x;
		self.prevY = y;
	end
end

function GHU_Loot:CloseLoot()
	self = gself; -- give self info for hooked functions
	if not(GHU_Loot:IsLootEmpty() == true) and not(OverRule==true) then
		-- keep the loot screen open
		LootFrame:Show(); 
	else
		self.orig.CloseLoot();
		self.loot = {};
		self.stayOpen = nil;
		GHI_Message("Loot reset");
	end
end



function GHU_Loot:GetNumLootItems()
	self = gself; -- give self info for hooked functions
	
	return self.orig.GetNumLootItems() + self:GetNumTotalGHULoot();
end

function GHU_Loot:GetLootSlotInfo(slot)
	self = gself; -- give self info for hooked functions
	GHI_Message("GetLootSlotInfo for "..slot);
	if slot <= self:GetNumTotalGHULoot() then
		--GHP:Msg("Returned custom item");
		local t = self.loot[slot];
		
		return t.texture,t.name,t.amount,t.quality,nil;
		
	end
	--GHP:Msg("Info for #%s, orig index %s",slot,slot - self:GetNumTotalGHULoot());
	return self.orig.GetLootSlotInfo(slot - self:GetNumTotalGHULoot());
end

function GHU_Loot:LootSlotIsItem(slot)
	self = gself; -- give self info for hooked functions
	if slot <= self:GetNumTotalGHULoot() then
		return true;
	end
	
	return self.orig.LootSlotIsItem(slot - self:GetNumTotalGHULoot());
	
end

function GHU_Loot:LootSlotIsCoin(slot)
	self = gself; -- give self info for hooked functions
	if slot <= self:GetNumTotalGHULoot() then
		return true;
	end
	
	return self.orig.LootSlotIsCoin(slot - self:GetNumTotalGHULoot());
	
end

function GHU_Loot:LootSlot(slot)
	self = gself; -- give self info for hooked functions
	if slot <= self:GetNumTotalGHULoot() then
		
		return false;
	end

	return self.orig.LootSlot(slot - self:GetNumTotalGHULoot()); --GHR_Message("Update");
end

function GHU_Loot:LootItem_OnEnter(frame)
	self = gself; -- give self info for hooked functions
	local slot = ((LOOTFRAME_NUMBUTTONS - 1) * (LootFrame.page - 1)) + frame:GetID();
	if slot <= self:GetNumTotalGHULoot() then
		if ( LootSlotIsItem(slot) ) then
			local t = self.loot[slot];
			if type(t)=="table" and type(t.tooltipFunc)=="function" then
				GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
				GameTooltip:AddLine("Testing.", 0.7,0,0);	
				GameTooltip:Show()
				if tooltipArg1 == "self" then
					--t.tooltipFunc(frame,t.tooltipArg2);
				else
					--t.tooltipFunc(t.tooltipArg1,t.tooltipArg2);
				end
				frame.UpdateTooltip = nil;
				CursorUpdate(frame);
			end		
		end
	end
	return self.orig.LootItem_OnEnter(frame);
	
end



function GHU_Loot:ConfirmLootSlot(slot)
	self = gself; -- give self info for hooked functions
	if slot <= self:GetNumTotalGHULoot() then
		return false;
	end
	return self.orig.ConfirmLootSlot(slot - self:GetNumTotalGHULoot());
end
function GHU_Loot:ConfirmLootRoll(slot)
	self = gself; -- give self info for hooked functions
	if slot <= self:GetNumTotalGHULoot() then	
		return false;
	end
	return self.orig.ConfirmLootRoll(slot - self:GetNumTotalGHULoot());
end
function GHU_Loot:GetLootSlotLink(slot)
	self = gself; -- give self info for hooked functions
	if slot <= self:GetNumTotalGHULoot() then	
		return false;
	end
	return self.orig.GetLootSlotLink(slot - self:GetNumTotalGHULoot());
end
function GHU_Loot:GiveMasterLoot(slot,index)
	self = gself; -- give self info for hooked functions
	if slot <= self:GetNumTotalGHULoot() then	
		return false;
	end
	return self.orig.GiveMasterLoot(slot - self:GetNumTotalGHULoot(),index);
end


--- other
function GHU_Loot:IsLootEmpty()
	return (self:GetNumUnlooted() == 0);
end
function GHU_Loot:StayOpenOnMove()
	return self.stayOpen;
end



function GHU_Loot:OpenLootFrame(portraitFrame,stayOpenOnMove)
	self.loot = {};
	self.stayOpen = stayOpenOnMove;
	if type(portraitFrame) == "table" then
		SetLootPortrait(portraitFrame);
	end
		
	LootFrame.page = 1;
	ShowUIPanel(LootFrame);
end

function GHU_Loot:GetNumTotalGHULoot()
	return table.getn(self.loot or {});
end

function GHU_Loot:GetNumUnlooted()
	local c = 0;
	local t = self.loot or {};
	for i=1,table.getn(t) do
		if type(t[i])=="table" then
			c = c+1;
		end
	end
	return c;
end

function GHU_Loot:AddLoot(name,texture,amount,quality,clickFunc,clickArg1,clickArg2,itemlink,tooltipFunc,tooltipArg1,tooltipArg2)
	local err = "Illigal input to AddLoot: %s. type: %s."
	assert(type(name)=="string" or type(name)=="number",format(err,"name",type(name)));
	assert(type(texture)=="string",format(err,"texture",type(texture)));
	assert(type(amount)=="number",format(err,"amount",type(amount)));
	assert(type(quality)=="number",format(err,"quality",type(quality)));
	assert(type(tooltipFunc)=="function",format(err,"tooltip function",type(tooltipFunc)));
	assert(type(clickFunc)=="function",format(err,"click function",type(clickFunc)));
	
	local t = {};
	t.name = name;
	t.texture = texture;
	t.amount = amount;
	t.quality = quality;
	t.tooltipFunc = tooltipFunc;
	t.clickFunc = clickFunc;
	t.clickArg1 = clickArg1;
	t.clickArg2 = clickArg2;
	t.tooltipArg1 = tooltipArg1;
	t.tooltipArg2 = tooltipArg2;
	local t2 = self.loot or {}
	table.insert(t2,t);
	self.loot = t2;
	GHI_Message("Total loot "..table.getn(t2));
	LootFrame_OnShow(LootFrame);
	LootFrame_Update(); 
end

function GHU_Loot:AddGHILoot(ID,amount,clickFunc,clickArg1,clickArg2)
	local name,icon,quality = GHI_GetItemInfo(ID);
	if name then
		self:AddLoot(name,icon,amount,quality,clickFunc,clickArg1,clickArg2,GHI_GenerateLink(ID),GHI_ItemTooltip,"self",ID);
	else 
		GHI_Message("item not found");
	end
end

--[[ 	
	/script Loot = GHU_New("Loot");
	/script orig_LootButton_OnClick = LootButton_OnClick; LootButton_OnClick = function(self,button) orig_LootButton_OnClick(self,button); GHI_Message("Loot click"); LootFrame:Show(); end
	/script Loot:OpenLootFrame();  Loot:AddGHILoot("Venaliter_29181772",3,GHI_Message,"Test");
	
	
--]]--
