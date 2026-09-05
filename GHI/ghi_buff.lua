

--[[	Handler for buffs

	Public functions:
	- Add buff
		@ arg
		buff/debuff
		name
		texture
		text
		duration
		effect
		
		
	- Cancel buff
		name

--]]

local Buff;

function GHI_BuffHookings()
	
	Buff = GHU_New("buff");
	-- PLAYER_AURAS_CHANGED belonged to the retired GHI_BuffFrame_Update path.
	-- GHU_BuffDisplay refreshes itself when GHI buff data changes.
	this:RegisterEvent("PLAYER_TARGET_CHANGED");
	Buff:SetFeedbackFunc(GHI_BuffChanged)
	return
	
	
	----TradePlayerItem1ItemButton:SetScript("OnEnter", function() Old_Script_ItemButton(); GHI_TradeItemButtonOnEnter(this:GetParent():GetID()); end);
	
	----GHI_Orig_BuffButton_OnUpdate = BuffButton_OnUpdate;
	----BuffButton_OnUpdate = GHI_BuffButton_OnUpdate
	
	
	----GHI_GHI_UpdateAllBuffs();
	
	--[[  
	GHI_Orig_UnitAura = UnitAura;
	--UnitAura = GHI_UnitAura;
	--hooksecurefunc("UnitAura",GHI_UnitAura);
	--
	GHI_Orig_UnitBuff = UnitBuff;
	--hooksecurefunc("UnitBuff",GHI_UnitBuff);

	--UnitBuff = GHI_UnitBuff;
	
	GHI_Orig_UnitDebuff = UnitDebuff;
	--hooksecurefunc("UnitDebuff",GHI_UnitDebuff);

	--UnitDebuff = GHI_UnitDebuff;
	
	GHI_Orig_SetUnitAura = GameTooltip.SetUnitAura;
	GameTooltip.SetUnitAura = GHI_SetUnitAura;
	
	GHI_Orig_SetUnitBuff = GameTooltip.SetUnitBuff;
	GameTooltip.SetUnitBuff = GHI_SetUnitBuff;
	
	GHI_Orig_SetUnitDebuff = GameTooltip.SetUnitDebuff;
	GameTooltip.SetUnitDebuff = GHI_SetUnitDebuff;
			
	GHI_Orig_CancelUnitBuff = CancelUnitBuff;
	CancelUnitBuff = GHI_CancelUnitBuff;
	
	GHI_Orig_CancelUnitDebuff = CancelUnitDebuff;
	CancelUnitDebuff = GHI_CancelUnitDebuff;
	
	----GHI_Orig_BuffButton_OnClick = BuffButton_OnClick;
	----BuffButton_OnClick = GHI_ClickBuff;
	--]]
	
end

GHI_DelayCastData = {};
-- Player in function 
function ApplyGHIBuff(name,text,texture,untilCancelled,filter,debuffType,duration,cancelable,stackable,count,delay)
	if type(delay)=="number" and delay > 0 then
		local r = 1;
		while GHI_DelayCastData[r] do
			r=r+1;
		end
		GHI_DelayCastData[r] = {name,text,texture,untilCancelled,filter,debuffType,duration,cancelable,stackable,count,0};
		
		GHI_DoScript("ApplyGHIBuff(unpack(GHI_DelayCastData["..r.."])); GHI_DelayCastData["..r.."] = nil;",delay);
		return;
	end
	Buff:CastBuff(string.lower(filter),name,UnitGUID("player"),name,text,texture,(not(untilCancelled) and duration)or 0 ,(not(untilCancelled) and GetTime() + duration) or 0,count	,debuffType,stackable)
	
end

function RemoveGHIBuff(name,count) -- now only called by scripts
	assert(type(name)=="string"and type(count)=="number","RemoveGHIBuff useage: name (string), count (number).")
	
	Buff:RemoveBuff(name,UnitGUID("player"),count)
end

function RemoveAllGHIBuffs()
	Buff:ClearAllBuffs(UnitGUID("player"));
	GHI_DelayCastData = {};
end

-- Target etc in
GHI_SubscribedPlayers = {};
local subscriptionsSend = {};
GHI_OldBuffPlayers = {};
GHI_OldBuffReqs = {};

function GHI_CheckTarget()
	local name, realm = UnitName("target");

	if UnitIsPlayer("target")
		and UnitFactionGroup("target") == UnitFactionGroup("player")
		and not(UnitName("player") == name)
		and realm == nil then

		if type(subscriptionsSend[name])=="number"
			and (GetTime() - subscriptionsSend[name]) < 60*3 then

			return;
		end

		GHI:SendPrioritizedMessage(
			"NORMAL",
			"WHISPER",
			name,
			false,
			"BuffSubscribe",
			60*5
		);

		subscriptionsSend[name] = GetTime();
	end
end

function GHI_BuffRecieveSubscription(sender,subscriptionTime,...)
	GHI_SubscribedPlayers[sender] = GetTime() + subscriptionTime;
	GHI_SendBuffInfo(sender);
end
GHI:RegisterRecieve("BuffSubscribe",GHI_BuffRecieveSubscription)

function GHI_SendBuffInfo(players) 
	local guid = UnitGUID("player");
	local buffs,debuffs = Buff:Serialize(guid);
	
	if type(players) == "string" then
		local name = players;
		players = {};
		players[name] = "dummy";
	end
	
	
	for name,_ in pairs(players) do
		if GHI_OldBuffPlayers[name] then -- send by old standard
			local buffs_old = {};
			buffs_old.lastUpdated = GHI_OldBuffPlayers["own time"];								
			for i,v in pairs(buffs) do
				buffs_old[i] = {
					texture = v.icon,
					name = v.name,
					timeCasted = v.expirationTime - v.totalDuration,
					amount = v.count,
					duration = v.totalDuration,
					text = v.description,
					debuffType = v.debuffType,
				}
			end
			
			local debuffs_old = {};
			debuffs_old.lastUpdated = GHI_OldBuffPlayers["own time"];								
			for i,v in pairs(debuffs) do
				debuffs_old[i] = {
					texture = v.icon,
					name = v.name,
					timeCasted = v.expirationTime - v.totalDuration,
					amount = v.count,
					duration = v.totalDuration,
					text = v.description,
					debuffType = v.debuffType,
				}
			end
			
			GHI:SendMessage("WHISPER",name,false,"BuffInfo",buffs_old)
			GHI:SendMessage("WHISPER",name,false,"DebuffInfo",debuffs_old)
		else
			GHI:SendPrioritizedMessage("NORMAL","WHISPER",name,false,"BuffInfo",guid,buffs,debuffs)
		end
	end
end

function GHI_BuffRecieveInfo(sender,guid,buffData,debuffData,...)

	-- Turtle/Vanilla target identity is name-based in this port.
	-- Store remote buffs by sender name so the key agrees with
	-- UnitGUID("target") / the target buff display.
	local key = sender or guid;

	Buff:Deserialize(
		key,
		buffData,
		debuffData
	);

	-- If the client ever provides a different target identifier,
	-- also populate that key while this sender is our current target.
	local targetName = UnitName("target");

	if sender and targetName
		and string.lower(sender) == string.lower(targetName) then

		local targetKey = UnitGUID("target");

		if targetKey
			and targetKey ~= key then

			Buff:Deserialize(
				targetKey,
				buffData,
				debuffData
			);
		end
	end
end
GHI:RegisterRecieve("BuffInfo",GHI_BuffRecieveInfo)

function GHI_BuffChanged(guid)
	if UnitGUID("player")==guid then
		GHI_OldBuffPlayers["own time"] = time();
		GHI_UpdateBuffSubscriptions()
		GHI_SendBuffInfo(GHI_SubscribedPlayers)
	end
end

function GHI_UpdateBuffSubscriptions()
	for player,timeout in pairs(GHI_SubscribedPlayers) do
		if timeout < GetTime() then
			GHI_SubscribedPlayers[player] = nil;
		end
	end
end


function GHI_RecieveBuff(sender,info) -- v.27.1 old
	if not(type(info) == "table") then 	return	end
	if not(UnitName("target") == sender) then return end
	
	subscriptionsSend[sender] = GetTime() - 60*3 + 15;
	GHI_OldBuffReqs[sender] = time();
	
	local guid = UnitGUID("target");
	local buffs,debuffs = Buff:Serialize(guid);
	
	local t = {};
	for i,v in pairs(info) do
		if type(v) == "table" then
			t[i] = {
				icon = v.texture,
				name = v.name,
				expirationTime = v.timeCasted + v.duration,
				count = v.amount,
				totalDuration = v.duration,
				description = v.text,
				debuffType = v.debuffType,
				
				-- other info
				refID = v.name,
			}
		end
	end
	
	Buff:Deserialize(guid,t,debuffs)
end


function GHI_RecieveDebuff(sender,info)	-- v.27.1 old
	if not(type(info) == "table") then 	return	end
	if not(UnitName("target") == sender) then return end
	
	GHI_OldBuffReqs[sender] = time();
	
	local guid = UnitGUID("target");
	local buffs,debuffs = Buff:Serialize(guid);
	
	local t = {};
	for i,v in pairs(info) do if type(v) == "table" then
		t[i] = {
			icon = v.texture,
			name = v.name,
			expirationTime = v.timeCasted + v.duration,
			count = v.amount,
			totalDuration = v.duration,
			description = v.text,
			debuffType = v.debuffType,
			
			-- other info
			refID = v.name,
		}
	end end
	
	Buff:Deserialize(guid,buffs,t)
end

function Buffformat()
	return Buff:Serialize(UnitGUID("player"));
end

--[[	old table format
	local list = {};
	list.amount = 1;
	list.name = name;
	list.text = text;
	list.texture = texture;
	
	list.untilCancelled = untilCancelled;
	
	if DebuffTypeColor[debuffType] == nil then
		debuffType = "none"; 
	end
	
	list.debuffType = debuffType;
	list.duration = duration;
	list.cancelable = cancelable;
	list.timeCasted = GetTime();
]]--



---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--								ALL BELOW THIS SHOULD BE DELETEABLE
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------


StaticPopupDialogs["GHI_DISABLE_BUFFS"] = {
	text = GHI_DISABLE_BUFF_QUESTION,
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		GHI_DisableBuffHookings() 
	end,
	OnCancel = function ()
		
	end,
	OnUpdate = function ()
	end,
	timeout = 0,
	whileDead = 1,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1
};


function GHI_DisableBuffHookings() 
	GHI_MiscData["DisableBuffs"] = true;
	GHI_ReloadUI();
end

--[[
function GHI_EnableBuffHookings()	
	UnitAura = GHI_UnitAura;
	UnitBuff = GHI_UnitBuff;
	UnitDebuff = GHI_UnitDebuff;
end --]]


function GHI_GHI_UpdateAllBuffs()  -- old
	-- Handle Buffs
	
	for i=BUFF_ACTUAL_DISPLAY+1, BUFF_MAX_DISPLAY do 
		if ( GHI_BuffButton_Update("BuffButton", i, "HELPFUL") ) then 
			---BUFF_ACTUAL_DISPLAY = BUFF_ACTUAL_DISPLAY + 1;
			--GHI_Message(i);
		end
	end

	-- Handle debuffs
	for i=DEBUFF_ACTUAL_DISPLAY+1, DEBUFF_MAX_DISPLAY do
		if ( GHI_BuffButton_Update("DebuffButton", i, "HARMFUL") ) then
			--DEBUFF_ACTUAL_DISPLAY = DEBUFF_ACTUAL_DISPLAY + 1;
		end
	end
end

function GHI_BuffButton_Update(buttonName, index, filter)	-- old
	-- Valid tokens for "filter" include: HELPFUL, HARMFUL, CANCELABLE, NOT_CANCELABLE
	local icon, color, debuffType, debuffSlot, buffCount;
	
	local a = BUFF_ACTUAL_DISPLAY;
	if filter == "HARMFUL" then
		a = DEBUFF_ACTUAL_DISPLAY;
	end
	
	
	local buffIndex, untilCancelled, texture, count,debuffType = GetGHIBuff(index - a, filter);
	local buffName = buttonName..index;
	local buff = getglobal(buffName);
	local buffDuration = getglobal(buffName.."Duration");
	
	
	
	if ( buffIndex == 0 ) then
		-- No buff so hide it if it exists
		if ( buff ) then
			buff:Hide();
			buffDuration:Hide();
			--GHI_Message("hiding: "..buff:GetName());
		end
		
		return nil;
	else  
		buffIndex = buffIndex + a;
		--GHI_Message("bi: "..buffIndex);
		-- If buff button doesn't exist make it
		if ( not buff ) then 
			if ( filter == "HELPFUL" ) then
				buff = CreateFrame("Button", buffName, BuffFrame, "BuffButtonTemplate");
			else
				buff = CreateFrame("Button", buffName, BuffFrame, "BuffButtonHarmful");
			end
			
			buffDuration = getglobal(buffName.."Duration");
		end
		
		buff.GHIBuffIndex = buffIndex - a;
		buff.filter = filter;
		
		
		-- Anchor Buff
		BuffButton_UpdateAnchors(buttonName, index, filter);
		-- Setup Buff
		
		buff.buffIndex = buffIndex;
		buff.untilCancelled = untilCancelled; 
		buff:SetID(100);
		buff:SetAlpha(1.0);
		buff:Show();
		if ( SHOW_BUFF_DURATIONS == "1" ) then
			buffDuration:Show();
		else
			buffDuration:Hide();
		end
		
		-- Set Texture
		icon = getglobal(buffName.."Icon");
		if texture then
			icon:SetTexture(texture);
		else
		
			icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
		end

		-- Set the number of applications of an aura if its a debuff
		buffCount = getglobal(buffName.."Count");			
--		count = GetPlayerBuffApplications(buffIndex);
		
		if ( count > 1 ) then
			buffCount:SetText(count);
			buffCount:Show();
		else
			buffCount:Hide();
		end

		-- Set color of debuff border based on dispel class.
		if ( filter == "HARMFUL" ) then
			--debuffType = "none"--GetPlayerBuffDispelType(buffIndex);
			debuffSlot = getglobal(buffName.."Border");
			if ( debuffType ) then
				color = DebuffTypeColor[debuffType];
			else
				color = DebuffTypeColor["none"];
			end

			if ( debuffSlot ) then
				debuffSlot:SetVertexColor(color.r, color.g, color.b);
			end
			
			if ( not debuffType ) then
				debuffType = "none";
			end
		end
		
		-- Refresh tooltip
		if ( GameTooltip:IsOwned(buff) ) then
			GHI_SetBuffTooltip(this);
		end
	end
	return 1;

end

function GHI_BuffButton_OnUpdate(self, elapsed) -- old
	local buffIndex = this.buffIndex;
	local filter = this.filter;
	
	--GHIBuffIndex
	
	
	--GHI_Message(buffIndex.." > "..BUFF_ACTUAL_DISPLAY);
	--GHI_Message("updating "..this:GetName());
	--GHI_Message(this.buffIndex);
	if not(buffIndex) then
		GHI_Orig_BuffButton_OnUpdate(self, elapsed);
	elseif ((filter == "HELPFUL") and not(buffIndex > BUFF_ACTUAL_DISPLAY)) or ((filter == "HARMFUL") and not(buffIndex > DEBUFF_ACTUAL_DISPLAY)) then
	
		GHI_Orig_BuffButton_OnUpdate(self, elapsed);
		--GHI_GHI_UpdateAllBuffs();
		--GHI_Message("A");
	else
		--GHI_Message(buffIndex);
		--GHI_Message("B");
	
		local buffDuration = getglobal(this:GetName().."Duration");
		
		
		if ( this.untilCancelled == 1 ) then
			buffDuration:Hide();
			if ( GameTooltip:IsOwned(this) ) then
				GHI_SetBuffTooltip(this)
			end
			return;
		end

		
		
		--if buffIndex > BUFF_ACTUAL_DISPLAY then
		--local timeLeft = 20;
		
		--else
		
		local timeLeft = GetGHIBuffTimeLeft(this.GHIBuffIndex,filter);
		
		--
		--GHR_Message("t: "..timeLeft);
		
		if timeLeft <= 0 then
			RemoveGHIBuff(this.GHIBuffIndex,filter);
			--GHI_GHI_UpdateAllBuffs();
			GHI_UpdateAllBuffs();
			return;
		end
		--GHR_Message(buffIndex);
		
		if ( timeLeft < BUFF_WARNING_TIME ) then
			this:SetAlpha(BuffFrame.BuffAlphaValue);
		else
			this:SetAlpha(1.0);
		end

		-- Update duration
		--GHI_Message(this:GetName().." : "..timeLeft);
		BuffFrame_UpdateDuration(this, timeLeft);

		if ( BuffFrame.BuffFrameUpdateTime > 0 ) then
			return;
		end
		if ( GameTooltip:IsOwned(this) ) then
			GHI_SetBuffTooltip(this)
		end
	end
end

function GHI_ClickBuff()	-- old
	local buffIndex = this.GHIBuffIndex; 
	local a = BUFF_ACTUAL_DISPLAY;
	
	if this.filter == "HARMFUL" then
		a = DEBUFF_ACTUAL_DISPLAY;
	end
	
	
	
	
	local _,b = string.find(this:GetName(),"Button");
	if b then
		local index = tonumber(string.sub(this:GetName(),b+1));
		if index then
			if (index > a) then 
				if (this.filter == "HELPFUL") then
					if (GHI_BuffList[buffIndex]) then
						--GHI_Message("clicked "..index.." name: "..GHI_BuffList[index].name);
						--if (GHI_BuffList[buffIndex].untilCancelled == 1) then
						RemoveGHIBuff(buffIndex,"HELPFUL")
						--end
					end
				end
			end
		end
	end
	GHI_Orig_BuffButton_OnClick();
end

GHI_RerunBuffUpdate = false;
function GHI_UpdateAllBuffs()
	----GHI_RerunBuffUpdate = false;
	--BuffFrame_Update();
	
	--TargetFrame_UpdateAuras(TargetFrame);  -- changed from self
	
	--[[
	if GHI_CompAddons["XPerl_PlayerBuffs"] == true then
		XPerl_Unit_UpdateBuffs(XPerl_Player, nil, nil, 0, 0)
	end 
	if GHI_CompAddons["XPerl_Target"] == true then
		XPerl_Unit_UpdateBuffs(XPerl_Target, nil, nil, 0, 0);
		XPerl_Targets_BuffUpdate(XPerl_Target);
	end  --]]
	
	local guid = UnitGUID("target");
	Buff:ClearAllBuffs(guid);
	for i,buff in pairs(GHI_TargetBuffs) do
		if type(buff)=="table" then
			Buff:CastBuff("buff",i,guid,buff.name,buff.text,buff.texture,(buff.untilCancelled and buff.duration)or 0 ,(buff.untilCancelled and buff.timeCasted+buff.duration) or 0,buff.amount,buff.debuffType);
		end
	end
	for i,buff in pairs(GHI_TargetDebuffs) do
		if type(buff)=="table" then
			Buff:CastBuff("debuff",i,guid,buff.name,buff.text,buff.texture,(buff.untilCancelled and tb.duration)or 0 ,(buff.untilCancelled and buff.timeCasted+buff.duration) or 0,buff.amount,buff.debuffType);
		end
	end
	
end

GHI_UpdateWatcher ={};
function GHI_AddUpdateWatcher(timeToUpdate)
	local t = timeToUpdate+time()-0.5;
	local i = 1;
	while GHI_UpdateWatcher[i] and GHI_UpdateWatcher[i] < t do
		i = i +1;
	end
	table.insert(GHI_UpdateWatcher,i,t);
	table.insert(GHI_UpdateWatcher,i,t+1);
end

function GHI_CheckUpdateWatcher()
	local t = GHI_UpdateWatcher[1];
	if t then
		if t <=time() then
			table.remove(GHI_UpdateWatcher,1);
			GHI_UpdateAllBuffs();
			--GHI_Debug("Running schedualled update");
		end	
	end
end


--	============================  buffs  =====================
--[[
local GHI_CurrentMaxBuffs ={};
local GHI_CurrentMaxDebuffs ={};


function GHI_UnitAura(unit,index,filter)
	--if index==1 then GHI_Debug("Unit aura "..unit.." # "..index.." f: "..filter.." Called by "..(this:GetName() or "unknown")); end
	if not(type(GHI_CurrentMaxBuffs[unit])=="number") then
		GHI_CurrentMaxBuffs[unit] = 0;
	end
	if not(type(GHI_CurrentMaxDebuffs[unit])=="number") then
		GHI_CurrentMaxDebuffs[unit] = 0;
	end
	
	if not(index) or not(tonumber(index)) then
		--GHI_Message("Case 4");
		return GHI_Orig_UnitAura(unit,index,filter );
	else
		index = tonumber(index);
	end
	
	local name = GHI_Orig_UnitAura(unit,index,filter );

	if name then
		if GHI_CurrentMaxBuffs[unit] < index and filter == "HELPFUL" then
			GHI_CurrentMaxBuffs[unit] = index;
		end
		if GHI_CurrentMaxDebuffs[unit] < index and filter == "HARMFUL" then
			GHI_CurrentMaxDebuffs[unit] = index;
		end
		--if index==1 then GHI_Message("Case 1"); end
		return GHI_Orig_UnitAura(unit,index,filter );
	else
		if GHI_CurrentMaxBuffs[unit] >= index and filter == "HELPFUL"  then
			GHI_CurrentMaxBuffs[unit] = index -1;
		end
		if GHI_CurrentMaxDebuffs[unit] >= index and filter == "HARMFUL"  then
			GHI_CurrentMaxDebuffs[unit] = index -1;
		end
		
		--GHI_Debug(index.." "..index-GHI_CurrentMaxBuffs[unit],2);
		local ghi_index = 0;
		if filter == "HELPFUL" then
			ghi_index = index-GHI_CurrentMaxBuffs[unit];
		elseif filter == "HARMFUL" then
			ghi_index = index-GHI_CurrentMaxDebuffs[unit];
		else	
			--if index==1 then GHI_Message("Case 2"); end
			return;
		end
		--GHI_Debug("Getting buff/debuff unit: "..unit.." filter: "..filter.." i: "..ghi_index);
		if strlower(unit) == "player" then 
			--if index==1 then GHI_Message("Case 3"); end
			local a = GetGHIBuff(ghi_index,filter);
			--if a then			GHI_Message(index.." "..filter.." ghi: "..ghi_index.." Returning: "..a); end
			return GetGHIBuff(ghi_index,filter);
		elseif strlower(unit) == "target" then
			return GetGHITargetBuff(ghi_index,filter); --GetGHITargetBuff(ghi_index,filter);
		end
		
		
	end
end


function GHI_UnitBuff(unit,index,castable )
-- nil;
	--if unit == "player" then GHI_Debug("Unit buff "..unit.." # "..index.." Called by "..(this:GetName() or "unknown")); end
	
	-- name, rank, icon, count, debuffType, duration, expirationTime, isMine, isStealable 
	
	return GHI_UnitAura(unit,index,"HELPFUL");
	
	--if index ==3 then GHI_Debug(""..die); end
	-- [ [
	if not(type(GHI_CurrentMaxBuffs[unit])=="number") then
		GHI_CurrentMaxBuffs[unit] = 0;
	end
	
	local name = GHI_Orig_UnitBuff(unit,index,castable );

	if name then	
		if GHI_CurrentMaxBuffs[unit] < index then
			GHI_CurrentMaxBuffs[unit] = index;
		end
		
		if unit == "target" then
			GHI_TargetBuffAmount = index;
		end
		
		--local frame = getglobal("TargetFrameBuff"..index);
		--if frame then
		--	frame:SetScript("OnEnter", function() GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", 15, -25); GameTooltip:SetUnitBuff("target", this.id); end);
			
		--end
		GHI_Debug("Unit buff "..unit.." # "..index.." Called by "..(this:GetName() or "unknown"));
		
		return GHI_Orig_UnitBuff(unit,index,castable );
	else
		if GHI_CurrentMaxBuffs[unit] >= index then
			GHI_CurrentMaxBuffs[unit] = index -1;
		end
		--if index <= GHI_TargetBuffAmount then
		--	GHI_TargetBuffAmount = 0;
		--end
		local buffIndex = index - GHI_CurrentMaxBuffs[unit];
		
		--GHI_Message("Looking for index: "..buffIndex..". Found: "..type(GHI_TargetBuffs[buffIndex]));
		--GHD_PrintArray(GHI_TargetBuffs)
		
		--GHI_Debug(index.." -> "..buffIndex);
		-- test
		if buffIndex == 1 then
		local _,_,icon = GetGHIBuff(buffIndex,"HELPFUL");
		return "Test Buff","Rank 9000",icon,3,"Magic",17000,17000,1,nil;
		elseif buffIndex == 2 then
		return "Test Buff","Rank 9000","Interface\\Icons\\INV_Ammo_Bullet_03",4,"Magic",1800,17000,1,nil;
		end
		
		
		if not(GHI_TargetBuffs[buffIndex]) then 
			return;
		else 
			
			local frame = getglobal("TargetFrameBuff"..index);
			if frame then
				frame:SetScript("OnEnter", function() GHI_TargetBuffTooltip(buffIndex) end);
			end
			--GHI_Message("inserted "..index.." : "..type(frame));
			--GHI_Message("Returneds: "..GHI_TargetBuffs[buffIndex].name..", , "..GHI_TargetBuffs[buffIndex].texture);
			--name, rank, icon, count, debuffType, duration, expirationTime, isMine, isStealable
			
			--return GHI_TargetBuffs[buffIndex].name, "", GHI_TargetBuffs[buffIndex].texture, 1, nil,nil;
			return GHI_TargetBuffs[buffIndex].name, "", GHI_TargetBuffs[buffIndex].texture, 1, nil,nil,nil,true;
		end 
	end	 ] ]
end

function GHI_UnitDebuff(unit,index,raidFilter)
	--return nil;
	
	return GHI_UnitAura(unit,index,"HARMFUL");
	--[ [
	local name = GHI_Orig_UnitDebuff(unit,index,raidFilter);
	if name then	
		if unit == "target" then
			GHI_TargetDebuffAmount = index;
		end
		
		local frame = getglobal("TargetFrameDebuff"..index);
		if frame then
			frame:SetScript("OnEnter", function() GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", 15, -25); GameTooltip:SetUnitDebuff("target", this.id); end);
		end
		
		
		return GHI_Orig_UnitDebuff(unit,index,raidFilter);
	else
		if index <= GHI_TargetDebuffAmount then
			GHI_TargetDebuffAmount = 0;
		end
		local DebuffIndex = index - GHI_TargetDebuffAmount;
		--GHD_PrintArray(GHI_TargetDebuffs);
		--GHI_Message("Looking for index: "..DebuffIndex..". Found: "..type(GHI_TargetDebuffs[DebuffIndex]));
		if not(GHI_TargetDebuffs[DebuffIndex]) then 
			return;
		else 
			local frame = getglobal("TargetFrameDebuff"..index);
			if frame then
				frame:SetScript("OnEnter", function() GHI_TargetDebuffTooltip(DebuffIndex) end);
			end
			--GHI_Message("Returneds: "..GHI_TargetDebuffs[DebuffIndex].name..", , "..GHI_TargetDebuffs[DebuffIndex].texture..", "..GHI_TargetDebuffs[DebuffIndex].debuffType);
			return GHI_TargetDebuffs[DebuffIndex].name, "", GHI_TargetDebuffs[DebuffIndex].texture, 1,GHI_TargetDebuffs[DebuffIndex].debuffType, nil,nil;
			
		end
	end	] ]
end


function GHI_CancelUnitAura(unit,index,filter)
	

	local ghi_index = 0;
	if filter == "HELPFUL" then
		ghi_index = index-(GHI_CurrentMaxBuffs[unit] or 0);
	elseif filter == "HARMFUL" then
		ghi_index = index-(GHI_CurrentMaxDebuffs[unit] or 0);
	else	
		return GHI_Orig_CancelUnitBuff(unit,index,filter);
	end
	if ghi_index < 1 or GHI_MiscData["DisableBuffs"] == true then
		if filter == "HELPFUL" then
			return GHI_Orig_CancelUnitBuff(unit,index);
		elseif filter == "HARMFUL" then
			return GHI_Orig_CancelUnitDebuff(unit,index);
		end

	else
		
		if strlower(unit) == "player" then
			RemoveGHIBuff(ghi_index,filter);			
		end
	end
end

function GHI_CancelUnitBuff(unit,index,filter)
	GHI_CancelUnitAura(unit,index,filter);
end

function GHI_CancelUnitDebuff(unit,index,filter)
	GHI_CancelUnitAura(unit,index,filter);
end



function GHI_SetUnitAura(frame,unit,index,filter)
	--GHI_Debug("GHI_SetUnitAura "..unit.." "..index.." "..filter);
	if not(type(GHI_CurrentMaxBuffs[unit])=="number") or  not(type(GHI_CurrentMaxDebuffs[unit])=="number") then
		return GHI_Orig_SetUnitAura(frame,unit,index,filter);
	end
	
	local GHI_index;
	if filter == "HELPFUL" then
		GHI_index = index - GHI_CurrentMaxBuffs[unit];
	elseif filter == "HARMFUL" then
		GHI_index = index - GHI_CurrentMaxDebuffs[unit];
	else
		return GHI_Orig_SetUnitAura(frame,unit,index,filter);
	end
	if GHI_index <= 0 then
		return GHI_Orig_SetUnitAura(frame,unit,index,filter);
	end
	--if unit == "player" then
		
	GHI_SetBuffTooltip(frame,GHI_index,filter,unit)
	--end
end

function GHI_SetUnitBuff(frame,unit,index)
	return GHI_SetUnitAura(frame,unit,index,"HELPFUL");
end

function GHI_SetUnitDebuff(frame,unit,index)
	return GHI_SetUnitAura(frame,unit,index,"HARMFUL");
end

-- ]]
GHI_TargetBuffs = {};
GHI_TargetDebuffs = {};

function GHI_TargetBuffTooltip(index) -- old
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", 15, -25);
	GameTooltip:ClearLines(); 
	GameTooltip:AddLine(GHI_TargetBuffs[index].name,1,0.8196079,0);  
	GameTooltip:AddLine(GHI_WordWrap(GHI_TargetBuffs[index].text,GHI_WWSize),1,1,1);  
	GameTooltip:Show();
end



function GHI_SendBuffInfo_old(sender,lastUpdated) --old
	if not(type(lastUpdated) == "number") then
		lastUpdated = 0;
	end
	
	local ownTime = 0;
	if type(GHI_BuffList) == "table" then
		if type(GHI_BuffList.lastUpdated) == "number" then
			ownTime = GHI_BuffList.lastUpdated
		end
	end
	
	if lastUpdated < ownTime or lastUpdated == 0 or ownTime == 0 then
		GHI:SendMessage("WHISPER",sender,false,"BuffInfo",GHI_BuffList)
	end
	
	--[[
	for index1,value1 in pairs(GHI_BuffList) do 
		
		GHI_SendDataToBuffer("Buff_Name-"..index1,value1.name,sender);	
		GHI_SendDataToBuffer("Buff_Text-"..index1,value1.text,sender);	
		GHI_SendDataToBuffer("Buff_Icon-"..index1,value1.texture,sender);	
				
	end
	GHI_SendDataToBuffer("Buff_Amount",table.getn(GHI_BuffList),sender);]]
end


function GHI_SendDebuffInfo_old(sender,lastUpdated) -- old
	if not(type(lastUpdated) == "number") then
		lastUpdated = 0;
	end
	
	local ownTime = 0;
	if type(GHI_DebuffList) == "table" then
		if type(GHI_DebuffList.lastUpdated) == "number" then
			ownTime = GHI_DebuffList.lastUpdated
		end
	end
	
	if lastUpdated < ownTime or lastUpdated == 0 or ownTime == 0 then
		GHI:SendMessage("WHISPER",sender,false,"DebuffInfo",GHI_DebuffList)
	end
	--[[
	for index1,value1 in pairs(GHI_DebuffList) do 
		
		GHI_SendDataToBuffer("Debuff_Name-"..index1,value1.name,sender);	
		GHI_SendDataToBuffer("Debuff_Text-"..index1,value1.text,sender);	
		GHI_SendDataToBuffer("Debuff_Icon-"..index1,value1.texture,sender);	
		GHI_SendDataToBuffer("Debuff_Type-"..index1,value1.debuffType,sender);			
	end
	GHI_SendDataToBuffer("Debuff_Amount",table.getn(GHI_DebuffList),sender);]]
end


function GHI_RecieveBuffOld(prefix,data,sender)   -- old
	if sender == UnitName("target") then
		local a = string.sub(prefix,0,5);
		local b = tonumber(string.sub(prefix,6));
		--GHI_Message(a.."    "..b);
		if a and b then
			if not(GHI_TargetBuffs.name == UnitName("target")) then
				GHI_TargetBuffs = {};
				GHI_TargetBuffs.name = UnitName("target");
			
			end
			if not(type(GHI_TargetBuffs[b]) == "table") then
				GHI_TargetBuffs[b] = {};
			end
		
			local changed = false;
			if a == "Name-" then
				if not(GHI_TargetBuffs[b].name == data) then changed = true; end
				GHI_TargetBuffs[b].name = data;
			elseif a == "Text-" then
				if not(GHI_TargetBuffs[b].text == data) then changed = true; end
				GHI_TargetBuffs[b].text = data;
			elseif a == "Icon-" then
				if not(GHI_TargetBuffs[b].icon == data) then changed = true; end
				GHI_TargetBuffs[b].icon = data;
			end
			
			if changed == true then
				--TargetDebuffButton_Update();
			end
		end
		
		if prefix == "Amount" then 
			local amount = tonumber(data);
			if amount then 
				local len = table.getn(GHI_TargetBuffs);
				if amount < len then 
					local array = {};
					array.name = GHI_TargetBuffs.name;
					
					for i=1,amount do 
						array[i] = GHI_TargetBuffs[i];
					end
					GHI_TargetBuffs = array;
					
					
				end
			end
			TargetDebuffButton_Update();
		end
	end
end



function GHI_RecieveDebuffOld(prefix,data,sender)	-- old
	if sender == UnitName("target") then
		local a = string.sub(prefix,0,5);
		local b = tonumber(string.sub(prefix,6));
		--GHI_Message(a.."    "..b);
		if a and b then
			if not(GHI_TargetDebuffs.name == UnitName("target")) then
				GHI_TargetDebuffs = {};
				GHI_TargetDebuffs.name = UnitName("target");
			
			end
			if not(type(GHI_TargetDebuffs[b]) == "table") then
				GHI_TargetDebuffs[b] = {};
			end
		
			local changed = false;
			if a == "Name-" then
				if not(GHI_TargetDebuffs[b].name == data) then changed = true; end
				GHI_TargetDebuffs[b].name = data;
			elseif a == "Text-" then
				if not(GHI_TargetDebuffs[b].text == data) then changed = true; end
				GHI_TargetDebuffs[b].text = data;
			elseif a == "Icon-" then
				if not(GHI_TargetDebuffs[b].icon == data) then changed = true; end
				GHI_TargetDebuffs[b].icon = data;
			elseif a == "Type-" then
				if not(GHI_TargetDebuffs[b].debuffType == data) then changed = true; end
				GHI_TargetDebuffs[b].debuffType = data;
			end
			if changed == true then
				--TargetDeDebuffButton_Update();
			end
		end
		
		if prefix == "Amount" then 
			local amount = tonumber(data);
			if amount then 
				local len = table.getn(GHI_TargetDebuffs);
				if amount < len then 
					local array = {};
					array.name = GHI_TargetDebuffs.name;
					
					for i=1,amount do 
						array[i] = GHI_TargetDebuffs[i];
					end
					GHI_TargetDebuffs = array;
					
					
				end
			end
			TargetDebuffButton_Update();
		end
	end
end


function GHI_TargetDebuffTooltip(index)	-- old
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", 15, -25);
	GameTooltip:ClearLines(); 
	GameTooltip:AddLine(GHI_TargetDebuffs[index].name,1,0.8196079,0);  
	GameTooltip:AddLine(GHI_WordWrap(GHI_TargetDebuffs[index].text,GHI_WWSize),1,1,1);  
	GameTooltip:Show();
end



--- 	Intern API
GHI_WWSize = 30;

function GHI_SetBuffTooltip(frame,index,filter,unit)	-- old
	
	--GHI_Message("tooltip "..index);
	
	if filter == "HELPFUL" then
		local list = {};
		if unit == "player" then
			list= GHI_BuffList;
		elseif unit == "target" then
			list=GHI_TargetBuffs;
		end
		if not(list[index]) then 
			return;
		else
			GameTooltip:ClearLines(); 
			GameTooltip:AddLine(list[index].name,1,0.8196079,0);
			GameTooltip:AddLine(GHI_WordWrap(list[index].text,GHI_WWSize),1,1,1);
			
			if not(list[index].untilCancelled == 1) then
				if (list[index].timeCasted) and (list[index].duration) then
					local t = list[index].timeCasted + list[index].duration - GetTime();
					local t2 = GHI_TimeToTooltipText(t);
					
					GameTooltip:AddLine(t2.." "..GHI_REMAINING,1,0.8196079,0);
				end
			end
			
			GameTooltip:Show();
		end
	elseif filter == "HARMFUL" then
		local list = {};
		if unit == "player" then
			list= GHI_DebuffList;
		elseif unit == "target" then
			list=GHI_TargetDebuffs;
		end
		if not(list[index]) then 
			return;
		else
			GameTooltip:ClearLines(); 
			GameTooltip:AddLine(list[index].name,1,0.8196079,0);
			GameTooltip:AddLine(GHI_WordWrap(list[index].text,GHI_WWSize),1,1,1);
			
			if not(list[index].untilCancelled == 1) then
				if (list[index].timeCasted) and (list[index].duration) then
					local t = list[index].timeCasted + list[index].duration - GetTime();
					local t2 = GHI_TimeToTooltipText(t);
					
					GameTooltip:AddLine(t2.." "..GHI_REMAINING,1,0.8196079,0);
				end
			end
			GameTooltip:Show()
		end 
	else
		return;
	end
	
	
	
end

function GHI_TimeToTooltipText(Time)
	local CD_Sec = floor(Time);
	if CD_Sec == 1 then
		return CD_Sec.." "..GHI_SEC_S;
	elseif CD_Sec < 60 then
		return CD_Sec.." "..GHI_SECS_S;
	else
		local CD_Min = floor(CD_Sec/60)+1;
		if CD_Min == 1 then
			return CD_Min.." "..GHI_MIN_S;
		elseif CD_Min < 60 then
			return CD_Min.." "..GHI_MINS_S;
		else
			local CD_Hour = floor(CD_Min/60)+1;
			if CD_Hour == 1 then
				return CD_Hour.." "..GHI_HOUR_S;
			elseif CD_Hour < 24 then
				return CD_Hour.." "..GHI_HOURS_S;
			else 
				local CD_Days = floor(CD_Hour/24)+1;
				if CD_Days == 1 then
					return CD_Days.." "..GHI_DAY_S;
				else
					return CD_Days.." "..GHI_DAYS_S;
				end						
			end
		end				
	end

end


----	API

function GetGHIBuff(index, filter)
	-- name, rank, icon, count, debuffType, duration, expirationTime, isMine, isStealable
	if filter == "HELPFUL" then
		if not(GHI_BuffList[index]) then
			return;
		else
			local untilCancelled, name, buffDuration, Texture, count, debuffType;
			buffDuration = GHI_BuffList[index].duration;
			--GHI_Message(" buffDuration for "..index.."  is "..(buffDuration or "nil"));
			local expirationTime = GetGHIBuffTimeLeft(index, filter) + GetTime();
			Texture = GHI_BuffList[index].texture;
			count = GHI_BuffList[index].amount;
			name = GHI_BuffList[index].name;
			debuffType = GHI_BuffList[index].debuffType;
			untilCancelled = GHI_BuffList[index].untilCancelled;
			if count == nil then count = 1; end
			if not(buffDuration) then buffDuration = 0; end
			--GHI_Debug("untilCancelled: "..btype(untilCancelled));
			if untilCancelled == 1 then
				buffDuration = 0;
			end
			--GHI_Debug("Returning duration "..buffDuration.." expirationTime: "..expirationTime.." thats in "..expirationTime-GetTime()); 
			
			if expirationTime-GetTime() < 0 and not(untilCancelled == 1) then
				RemoveGHIBuff(index, filter)
			end
			
			return name,"rank",Texture,count,"Magic",buffDuration,expirationTime,1,nil;
			--return "Test Buff","Rank 9000","Interface\\Icons\\INV_Ammo_Bullet_03",3,"Magic",17000,50000,1,nil;
			--return index, untilCancelled, Texture, count, debuffType;
		end
	elseif filter == "HARMFUL" then
		if not(GHI_DebuffList[index]) then
			return;
		else
			local untilCancelled, buffDuration, name, Texture, count, debuffType;
			buffDuration = GHI_DebuffList[index].duration;
			local expirationTime = GetGHIBuffTimeLeft(index, filter) + GetTime();
			Texture = GHI_DebuffList[index].texture;
			count = GHI_DebuffList[index].amount;
			name = GHI_DebuffList[index].name;
			debuffType = GHI_DebuffList[index].debuffType;
			if strlower(debuffType) == "physical" then
				debuffType =nil;
			end
			untilCancelled = GHI_DebuffList[index].untilCancelled;
			if not(buffDuration) then buffDuration = 0; end
			if count == nil then count = 1; end
			
			if expirationTime-GetTime() < 0 and not(untilCancelled == 1) then
				RemoveGHIBuff(index, filter)
				
			end
			return name,"rank",Texture,count,debuffType,buffDuration,expirationTime,1,nil;
		end
	
	else
		return 0;
	end
end

function GetGHIBuffTimeLeft(index,filter)
	if filter == "HELPFUL" then
		if not(type(GHI_BuffList[index]) == "table") or not(GHI_BuffList[index].timeCasted) or not(GHI_BuffList[index].duration) then
			
			return -1;
		else
			if GHI_BuffList[index].untilCancelled == 1 then
				return 1;
			end
			
			local t = GHI_BuffList[index].timeCasted + GHI_BuffList[index].duration - GetTime();
			if t then
				return t;
			else
				return -1;
				
			end
			
		end
	elseif filter == "HARMFUL" then
		if not(type(GHI_DebuffList[index]) == "table") or not(GHI_DebuffList[index].timeCasted) or not(GHI_DebuffList[index].duration) then
			
			return -1;
		else
			if GHI_DebuffList[index].untilCancelled == 1 then
				return 1;
			end
			
			local t = GHI_DebuffList[index].timeCasted + GHI_DebuffList[index].duration - GetTime();
			if t then
				return t;
			else
				return -1;
				
			end
			
		end
	else
		return -1;
	end
end

--[[
function ApplyGHIBuff(name,text,texture,untilCancelled,filter,debuffType,duration,cancelable,stackable)
	Buff:CastBuff("buff",name		,UnitGUID("player"),name			,text					,texture							,(untilCancelled and duration)or 0 	,(untilCancelled and GetTime() + duration) or 0	,count	,debuffType)
	Buff:CastBuff("buff",name..(2)	,UnitGUID("player"),name			,text					,texture							,(untilCancelled and duration)or 0 	,(untilCancelled and GetTime() + duration) or 0								,2		,nil);
	Buff:CastBuff("buff","b"..(2)	,UnitGUID("player"),"Test Buff A"	,"A buff for testing"	,"Interface\\Icons\\Inv_misc_key_10",60*10								,GetTime()+30									,2		,nil);
	
	
	filter = strupper(filter);
	--GHI_Debug("apply untilCancelled: "..btype(untilCancelled));
	local B = {}
	if filter == "HELPFUL" then
		--table.insert(GHI_BuffList,list);
		B = GHI_BuffList;
	elseif filter == "HARMFUL" then
		--table.insert(GHI_DebuffList,list);
		B = GHI_DebuffList;
	end
	
	
	for i=1,table.getn(B) do
		if type(B[i]) == "table" then
			if B[i].name == name and B[i].text == text and B[i].texture == texture then
				if filter == "HELPFUL" then
					if stackable == 1 then
						GHI_BuffList[i].amount = GHI_BuffList[i].amount +1;
					else
						GHI_BuffList[i].amount = 1;
					end
					GHI_BuffList[i].timeCasted = GetTime();
					GHI_BuffList.lastUpdated = time();
				elseif filter == "HARMFUL" then
					if stackable == 1 then
						GHI_DebuffList[i].amount = GHI_DebuffList[i].amount +1;
					else
						GHI_DebuffList[i].amount = 1;
					end
					GHI_DebuffList[i].timeCasted = GetTime();
					GHI_DebuffList.lastUpdated = time();
				end
				
				--GHI_GHI_UpdateAllBuffs();
				GHI_UpdateAllBuffs();
				if duration and duration > 0 then
					GHI_AddUpdateWatcher(duration)
				end
				return;
			end
		end
	end
	
	
	local list = {};
	list.amount = 1;
	list.name = name;
	list.text = text;
	list.texture = texture;
	
	list.untilCancelled = untilCancelled;
	
	if DebuffTypeColor[debuffType] == nil then
		debuffType = "none"; 
	end
	
	list.debuffType = debuffType;
	list.duration = duration;
	list.cancelable = cancelable;
	list.timeCasted = GetTime();
	
	if filter == "HELPFUL" then
		table.insert(GHI_BuffList,list);
		GHI_BuffList.lastUpdated = time();
	elseif filter == "HARMFUL" then
		table.insert(GHI_DebuffList,list);
		GHI_DebuffList.lastUpdated = time();
	end
	
	--GHI_GHI_UpdateAllBuffs();
	
	if duration and duration > 0 then
		GHI_AddUpdateWatcher(duration)
	end
	
	--GHI_UpdateAllBuffs();
end --]]


GHI_BuffList = {};
GHI_DebuffList = {};
GHI_BuffList.lastUpdated = time();
GHI_DebuffList.lastUpdated = time();

function GetGHITargetBuff(index,filter)
	--GHI_Debug("index: "..index.." filter: "..filter.." ");
	if filter == "HELPFUL" then --GHI_Debug("right A "..type(index)..": "..type(GHI_TargetBuffs[index]),2);
		if not(type(GHI_TargetBuffs[index])=="table") then --GHI_Debug("right B",2);
			return;
		else	
			local tb =GHI_TargetBuffs[index];
			local uc = not(tb.untilCancelled == 1);
			return tb.name,"rank",tb.texture,tb.amount,tb.debuffType,(uc and tb.duration)or 0 ,(uc and tb.timeCasted+tb.duration) or 0,1,nil;
		end
	else
		if not(type(GHI_TargetDebuffs[index])=="table") then --GHI_Debug("right B",2);
			return;
		else	
			local tb =GHI_TargetDebuffs[index];
			local uc = not(tb.untilCancelled == 1);
			return tb.name,"rank",tb.texture,tb.amount,tb.debuffType,(uc and tb.duration)or 0 ,(uc and tb.timeCasted+tb.duration) or 0,nil,nil;
			--tb.debuffType
		end
	end
end

