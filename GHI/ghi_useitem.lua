

--	====================================	Use item	====================================
local CurrentItem = nil;

local function doAction(click,ID,bag,slot,buffTarget)
	if string.lower(click.Type) == "buff" then			-- ok
		-- Older/affected items can have the icon control's default question
		-- mark stored instead of the chosen buff icon.  Use the item's own
		-- icon as a sane migration fallback rather than displaying '?'.
		if click.buffIcon == nil or click.buffIcon == "" or click.buffIcon == "Interface\\Icons\\INV_Misc_QuestionMark" then
			local _,itemIcon = GHI_GetItemInfo(ID);
			if type(itemIcon) == "string" and itemIcon ~= "" then
				click.buffIcon = itemIcon;
			end
		end
		if type(click.range) == "number" and click.range > 0 then
			if not(GHI_MiscData["block_area_buff"]) then
				GHI_SendAreaEffect("buff",click)
			end
		else
			if buffTarget == nil or buffTarget == UnitName("player") or click.castOnSelf == 1 then
				
				--GHI_Debug(i.." untilCanceled 1 :::  "..btype(getglobal("GHI_TEST").untilCanceled),2);
				--GHI_Debug(i.." untilCanceled 2 :::  "..btype(getglobal("GHI_TEST").untillCanceled),2);
				ApplyGHIBuff(click.buffName,click.buffDetails,click.buffIcon,click.untillCanceled,click.filter,click.buffType,click.buffDuration,click.cancelable,click.stackable,click.count or 1,click.delay or 0)
			else
				
				GHI:SendMessage("WHISPER",buffTarget,false,"ApplyBuff",click.buffName,click.buffDetails,click.buffIcon,click.untillCanceled,click.filter,click.buffType,click.buffDuration,click.cancelable,click.stackable,click.count or 1,click.delay or 0)
			end
		end
	elseif string.lower(click.Type) == "book" then		-- ok
		
		local edit = 0;
		local _,_,_,_,_,_,_,creater = GHI_GetItemInfo(ID);
		if creater == GHI_PName then
			edit = 1;
		end
		
		
		GHI_ShowBook(click.title,click[1],edit,click.material,click.font,click.n,click.h1,click.h2)
		GHI_ItemTextFrameCurrentPage:SetText("1/"..click.pages);
		
		if click.pages == 1 then 
			GHI_ItemTextFramePrevPageButton:Hide();
			GHI_ItemTextFrameNextPageButton:Hide();
		else
			GHI_ItemTextFramePrevPageButton:Show();
			GHI_ItemTextFrameNextPageButton:Show();
		end
		
		GHI_ItemTextFrameScrollFrame:SetVerticalScroll(0);
		GHI_CurrentBookPage = 1;
		GHI_CurrentBookID = ID;
		GHI_CurrentBook = click;
		GHI_CurrentBookEdit = edit;
		GHI_CurrentMaterial = click.material;
	elseif string.lower(click.Type) == "bag" then --	OK
		local num = 1;
		if GHIContainerFrame2:IsShown() then
			num = 2;
		end
		GHI_SelectSecBag(num,ID)
	elseif string.lower(click.Type) == string.lower("GHR Reputation") or string.lower(click.Type) == string.lower("ghr")then
		local facID = click.faction;
		local amount = click.amount;
		
		if not(amount) then
			amount = 0;
		end
		
		--GHI_Message("Increasing rep with "..facID);
		--local itemName = GHI_GetItemInfo(ID);
		
		if facID then
			GHR_RecieveChangeRep(facID..":"..amount,"");
		end
		
		
		local linkedFactions = GHR_GetLinkedFaction(facID)
		if (type(linkedFactions) == "table") then 
		
			for index,value in pairs(linkedFactions) do 
				if type(value) == "table" then
					if value.ratio and value.id then
						local floor_amount2 = floor((amount * value.ratio)+ 0.5)
						if not(floor_amount2 == 0) then
							GHR_RecieveChangeRep(value.id..":"..floor_amount2,"");
						end
					end
				end
			end 
		end
		
		
	elseif string.lower(click.Type) == "script" then --	OK
		local code = "";
		
		local j = 1;
		while type(click.code[j]) == "string" do
			code = code..""..click.code[j];
			j = j+1;
		end
		local Error = GHI_CheckScript(code);
		
		if not(Error == nil or ((Error == "GHI_ContainerData" or Error == "GHI_ItemData") and click.dynamic_rc)) then
			GHI_Message("Script blocked. Contained protected function: "..Error..".");
			return;
		end
		
		local code = GHI_RemoveShortcuts(code);
		
		--isert link
		local link = GHI_GenerateLink(ID);
		code = GHI_InsertLinks(code,ID);
		code = gsub(code,"ITEM_ID",ID);
		code = gsub(code,"ITEM_BAG",bag);
		code = gsub(code,"ITEM_SLOT",slot);
		
		--GHI_Message(code);
		GHI_DoScript(code,click.delay);
		
		
	elseif string.lower(click.Type) == "sound" then
		local path = click.sound_path;
		local delay = click.delay;
		if type(path) == "string" then
			if type(click.range) == "number" and not(GHI_MiscData["block_area_sound"]) then
				GHI_SendAreaEffect("sound",path,click.range);
			else
				path = gsub(path,"\\\\","/");
				path = gsub(path,"\\","/");
				local a = "PlaySoundFile(\""..path.."\");";
				GHI_DoScript(a,delay);  --PlaySoundFile
			end
		end
	elseif string.lower(click.Type) == "expression" then
		local text = click.text;
		local Type = click.expression_type;
		local delay = click.delay;
		if Type == "Say" then
			GHI_DoSay(text,delay,ID);
		elseif Type == "Emote" then
			GHI_DoEmote(text,delay,ID);
		end
	elseif string.lower(click.Type) == "random_expression" then
		local text = click.text;
		local Type = click.expression_type;
		local allow_same = click.allow_same;
		if type(text) == "table" and type(Type) == "table" then
			local index = {};
			for j = 1,6 do
				if (text[j]) and not(text[j] == "") then
					table.insert(index,j);
				end
			end
			
			local r = random(1,table.getn(index));
			if not(allow_same == 1) then
				local last = GHI_GetItemUseInfo(ID,i); 
				if type(last)=="number" and table.getn(index) > 1 and r == last then
					while r == last do
						r = random(1,table.getn(index));
					end								
				end
			end
			
			
			if r and r > 0 then
				local j = index[r];
				if Type[j] == "Emote" then
					GHI_DoEmote(text[j],0,ID);
				elseif Type[j] == "Say" then
					GHI_DoSay(text[j],0,ID);
				end
				if not(allow_same == 1) then
					GHI_SetItemUseInfo(ID,i,j);
				end
			end
		end
	elseif string.lower(click.Type) == "equip_item" then
		local name = click.item_name;
		local delay = click.delay;
		local a = "EquipItem(\""..name.."\");";
		GHI_DoScript(a,delay);
	end
end

function GHI_UseItem(bag,slot)
	
	if not(GHI_ContainerData[bag][slot] == nil) then
		local info = GHI_GetContainerInfo(bag,slot);
		local ID = info.ID;
		local click = GHI_GetRightClickInfo(ID);
		if not(click == nil) and not(info.lock == true) then 
			--	if ready
			
			local CD = click.CD;
			
			--GHR_Message("CD: "..CD);
			--GHI_Message(GetTime() - GHI_CooldownData[ID]);
			
			if not(CD) or (CD == 0) or (GHI_CooldownData[ID] == nil) or (GetTime() - GHI_CooldownData[ID] > CD) or (GetTime() < GHI_CooldownData[ID]) then
				
				-- 	Type
				-- 	AddonReqName
				--	AddonReqData
				--	RequirementType
				--	RequitementData	
				
				if not(click.Type) then return end;
				
				local RCInfo = click;
				
				
				
				
				if click.AddonReqName and click.AddonReqData then
					--local addonReq = getglobal(click.AddonReqName);
					local addonReq = GetAddOnMetadata(click.AddonReqName, "Version");
					if not(addonReq) or not(GHI_CompareVersions(addonReq,click.AddonReqData)) then
						--	not useable
						GHI_Message("You havent got the required addon for this item");
						GHI_Message("Requires "..click.AddonReqName.." "..click.AddonReqData.." or higher");
						return;
					end
				end
				
				if click.RequirementType and click.RequitementData then
					local a = string.find(click.RequirementType,"_");
					if a then
						local ReqType = string.sub(click.RequirementType,0,a-1);
						local ReqSuffix = string.sub(click.RequirementType,a+1);
					else
						local ReqType = click.RequirementType;
						local ReqSuffix = "";
					end
					
					if ReqType == "Profession" then
						return; --- not implemented yet
					end
					
				end
				
				-- 	Determine is the item can be used, based on mechanicals  --  before 
				local targetName = UnitName("target");
				local buffTarget = nil;
				if type(RCInfo.requireTarget)=="table" and RCInfo.requireTarget[4] == true then
					if targetName == nil or targetName == UnitName("player") then
						buffTarget = UnitName("player");
					else
						if CheckInteractDistance("target", 1) then
							buffTarget = targetName;
						else
							GHI_TooFarAway();
							return;
						end
					end
				end
				
				-- run script before requirement
				local RCInfoList = {};
				if RCInfo.Type == "multible" then
					RCInfoList = click;
				else
					RCInfoList = {click};
				end
				
				CurrentItem = ID;
				for i = 1,table.getn(RCInfoList) do
					local click = {};
					click = RCInfoList[i];
					local req = click.req;
					if (req == 4) then
						doAction(click,ID,bag,slot,buffTarget);
					end
				end
				CurrentItem = nil;
				
				
				-- Check requirements in multible
				local forfilled = true;
				if click.Type == "multible" then
					for i = 1,table.getn(click) do
						local rc = click[i];
						if strlower(rc.Type) == "requirement" and forfilled == true then
							local Type = rc.req_type;
							local text = rc.req_detail;
							
							forfilled = GHI_CheckReq(Type,text);
							
							
						end						
					end
				end
				
				-- 	Determine is the item can be used, based on mechanicals  --  after 
				local targetName = UnitName("target");
				local buffTarget = nil;
				if type(RCInfo.requireTarget)=="table" and (RCInfo.requireTarget[1] == true or (RCInfo.requireTarget[2] == true and forfilled == true) or (RCInfo.requireTarget[3] == true and forfilled == false)) then
					if targetName == nil or targetName == UnitName("player") then
						buffTarget = UnitName("player");
					else
						if CheckInteractDistance("target", 1) then
							buffTarget = targetName;
						else
							GHI_TooFarAway();
							return;
						end
					end
				end
				
				
				CurrentItem = ID;
				for i = 1,table.getn(RCInfoList) do
					local click = {};
					click = RCInfoList[i];
					local req = click.req;
					if not(req) or (req == 1) or (req == 2 and forfilled == true) or (req==3 and forfilled == false) then
						doAction(click,ID,bag,slot,buffTarget);
					end
				end
				CurrentItem = nil;
				
				if RCInfo.consumed == 1 or RCInfo.consumed == true then
					if GHI_ContainerData[bag][slot].amount then
						GHI_ContainerData[bag][slot].amount = GHI_ContainerData[bag][slot].amount - 1;
						if GHI_ContainerData[bag][slot].amount == 0 then
							GHI_ContainerData[bag][slot] = nil;
						end
					end
				end

				
				if CD then
					if CD > 0 then
						GHI_CooldownData[ID] = GetTime();
					end
				end
				GHI_UpdateContainers()
			else
				
				GHI_CantUseItem()
			end
			
		end
	end
	
end

function GHI_CantUseItem()
	local race = UnitRace("player");
	local gender = UnitSex("player");
	local rand = random(1,3);
	if gender == 2 then
		gender = "Male";
	else
		gender = "Female";
	end
	
	race = gsub(race," ","");
	
	if race == "BloodElf" or race == "Draenei" then
		PlaySoundFile("Sound\\Character\\"..race.."\\"..race..""..gender.."_Err_ItemCooldown0"..rand..".wav");
	elseif race == "Human" then
		PlaySoundFile("Sound\\Character\\"..race.."\\"..gender.."ErrorMessages\\"..race..gender.."_err_itemcooldown0"..(rand*2)..".wav")
		
		--/script PlaySoundFile("Sound\\Character\\Human\\FemaleErrorMessages\\HumanFemale_err_itemcooldown02.wav")
	else
		--GHI_Message("Playing Sound\\Character\\"..race.."\\"..race..""..gender.."ErrorMessages\\"..race..""..gender.."_err_itemcooldown0"..(rand*2)..".wav");
		PlaySoundFile("Sound\\Character\\"..race.."\\"..race..""..gender.."ErrorMessages\\"..race..""..gender.."_err_itemcooldown0"..(rand*2)..".wav")
		--/script PlaySoundFile("Sound\\Character\\Human\\FemaleErrorMessages\\HumanFemale_err_itemcooldown02.wav")
	end
	UIErrorsFrame:AddMessage("Item is not ready yet.", 1.0, 0.0, 0.0, 53, 5);
end

function GHI_TooFarAway()
	local race = UnitRace("player");
	local gender = UnitSex("player");
	local rand = random(1,3);
	if gender == 2 then
		gender = "Male";
	else
		gender = "Female";
	end
	local index = {2,4,5};
	race = gsub(race," ","");
	
	if race == "BloodElf" or race == "Draenei" then
		PlaySoundFile("Sound\\Character\\"..race.."\\"..race..""..gender.."_Err_OutOfRange0"..rand..".wav");
	elseif race == "Human" then
		PlaySoundFile("Sound\\Character\\"..race.."\\"..gender.."ErrorMessages\\"..race..gender.."_err_outofrange0"..index[rand]..".wav")
		
		--/script PlaySoundFile("Sound\\Character\\Human\\FemaleErrorMessages\\HumanFemale_err_itemcooldown02.wav")
	else
		--GHI_Message("Playing Sound\\Character\\"..race.."\\"..race..""..gender.."ErrorMessages\\"..race..""..gender.."_err_itemcooldown0"..(rand*2)..".wav");
		PlaySoundFile("Sound\\Character\\"..race.."\\"..race..""..gender.."ErrorMessages\\"..race..""..gender.."_err_outofrange0"..index[rand]..".wav")
		--/script PlaySoundFile("Sound\\Character\\Human\\FemaleErrorMessages\\HumanFemale_err_itemcooldown02.wav")
	end
	UIErrorsFrame:AddMessage("Out of range.", 1.0, 0.0, 0.0, 53, 5);
end

function GHI_GetCurrentItem()
	return CurrentItem;
end

local GHI_ProtectedFunc = {"ForceQuit","Logout","Quit","ArenaTeamLeave","PurchaseSlot","AbandonSkill","BuySkillTier","GuildSetLeader","DeleteCursorItem","GuildDisband","GuildLeave","BuyGuildBankTab","GiveMasterLoot","LootSlot","RollOnLoot","PetAbandon","PetRename","ConfirmTalentWipe","AcceptTrade","AddTradeMoney","BeginTrade","SetTradeMoney","PickupTradeMoney","PickupPlayerMoney","BuyGuildBankTab","DepositGuildBankMoney","PickupGuildBankItem","PickupGuildBankMoney","WithdrawGuildBankMoney","BNAcceptFriendInvite","BNConnected","BNCreateConversation","BNDeclineFriendInvite","BNFeaturesEnabled","BNFeaturesEnabledAndConnected","BNGetBlockedInfo","BNGetBlockedToonInfo","BNGetConversationInfo","BNGetConversationMemberInfo","BNGetCustomMessageTable","BNGetFOFInfo","BNGetFriendInfo","BNGetFriendInfoByID","BNGetFriendInviteInfo","BNGetFriendToonInfo","BNGetInfo","BNGetMatureLanguageFilter","BNGetMaxPlayersInConversation","BNGetNumBlocked","BNGetNumBlockedToons","BNGetNumConversationMembers","BNGetNumFOF","BNGetFOFInfo","BNGetNumFriendInvites","BNGetNumFriends","BNGetNumFriendToons","BNGetSelectedBlock","BNGetSelectedFriend","BNGetSelectedToonBlock","BNGetToonInfo","BNInviteToConversation","BNIsBlocked","BNIsFriend","BNIsSelf","BNIsToonBlocked","BNLeaveConversation","BNListConversation","BNRemoveFriend","BNReportFriendInvite","BNReportPlayer","BNSendConversationMessage","BNSendFriendInvite","BNSendFriendInviteByID","BNSendWhisper","BNSetAFK","BNSetBlocked","BNSetCustomMessage","BNSetDND","BNSetFocus","BNSetFriendNote","BNSetMatureLanguageFilter","BNSetSelectedBlock","BNSetSelectedFriend","BNSetSelectedToonBlock","BNSetToonBlocked","IsBNLogin","CanCooperateWithToon","GHI_ContainerData","GHI_ItemData"};


function GHI_CheckScript(code) -- Check the script for protected functions.
	code = string.lower(code);
	for i=1,table.getn(GHI_ProtectedFunc) do
		local a,b = string.find(code,string.lower(GHI_ProtectedFunc[i]));
		if b then
			local c = string.sub(code,b+1,b+1);
			return GHI_ProtectedFunc[i];
		end	
	end
	return nil;
end

function GHI_RemoveShortcuts(code)
	--code = gsub(code,"Emote\(","GHI_DoEmote\(");
	--code = gsub(code,"emote\(","GHI_DoEmote\(");
	local a,b;
	b = 0;
	while not(b == nil) do
		--GHI_Message("===");
		a,b = string.find(string.lower(code),"emote",b);
		if b then
			local c = strbyte(string.sub(code,b+1,b+2));
			local d = 10;
			if a == 1 then
				d = 10;
			else
				d = strbyte(string.sub(code,a-1,a-1));
			end
			--GHI_Message(a..": "..d.." = "..string.sub(code,a-1,a-1));
			--GHR_Message("c: "..c);
			if c == 40 and (d == 10 or d == 32) then
				code = strsub(code,0,a-1).."GHI_DoEmote"..strsub(code,b+1);
				b = b+5;
			end
		end		
	end	
	
	local a,b;
	b = 0;
	while not(b == nil) do
		--GHI_Message("===");
		a,b = string.find(string.lower(code),"say",b);
		if b then
			local c = strbyte(string.sub(code,b+1,b+2));
			local d = 10;
			if a == 1 then
				d = 10;
			else
				d = strbyte(string.sub(code,a-1,a-1));
			end
			--GHI_Message(a..": "..d.." = "..string.sub(code,a-1,a-1));
			--GHR_Message("c: "..c);
			if c == 40 and (d == 10 or d == 32) then
				code = strsub(code,0,a-1).."GHI_DoSay"..strsub(code,b+1);
				b = b+5;
			end
		end		
	end	
	
	return code;

end


--	Latened emote and say
local GHI_ActionQueue = {};

function GHI_AddActionToQueue(Type,data,waitTime,ID)
	if not(waitTime) or not(Type) or not(data) then
		return
	end
	if not(tonumber(waitTime)) then
		return
	end;
	
	local t = time();
	
	local temp = {};
	temp.Time = t + tonumber(waitTime);
	temp.Type = Type;
	temp.data = data;
	temp.ID = ID;
	
	table.insert(GHI_ActionQueue,temp);
end

function GHI_RunActionsInQueue()
	local t = time();
	
	for i = 1,table.getn(GHI_ActionQueue) do
		if type(GHI_ActionQueue[i]) == "table" then
			if GHI_ActionQueue[i].Time == t then
				local Type = GHI_ActionQueue[i].Type;
				local data = GHI_ActionQueue[i].data;
				local ID = GHI_ActionQueue[i].ID;
				
				if Type == "emote" then
					local e = GHI_IsStdEmote(data);
					if e == false then
						SendChatMessage(data,"EMOTE");
					else 
						local d = getglobal("EMOTE"..e.."_TOKEN")
						DoEmote(d);
					end
				elseif Type == "say" then
					SendChatMessage(data,"SAY");
					--SendChatMessage(data,"say");
				elseif Type == "script" then
					ScriptID = ID;
					CurrentItem = ID;
					RunScript(data);
					CurrentItem = nil;
				end				
			end
		end
	end

end

function GHI_DoEmote(data,waitTime,ID)
	if ID then
		data = GHI_InsertLinks(data,ID);
	end
	if type(waitTime) == "number" and waitTime > 0 then
		GHI_AddActionToQueue("emote",data,waitTime);
	else
		local e = GHI_IsStdEmote(data);
		if e == false then
			if GHI_IsSpamBelowLimit() then
				SendChatMessage(data,"EMOTE");
				GHI_SpamCountIncrease();
				if not(GHI_IsSpamBelowLimit()) then
					GHI_Message(GHI_SPAM_LIMIT_REACHED);
				end			
			end
		else 
			local d = getglobal("EMOTE"..e.."_TOKEN")
			
			if GHI_IsSpamBelowLimit() then
				DoEmote(d);
				GHI_SpamCountIncrease();
				if not(GHI_IsSpamBelowLimit()) then
					GHI_Message(GHI_SPAM_LIMIT_REACHED);
				end			
			end
			
		end	
	end
end

function GHI_DoSay(data,waitTime,ID)
	if ID then
		data = GHI_InsertLinks(data,ID);
	end
	if type(waitTime) == "number" and waitTime > 0 then
		GHI_AddActionToQueue("say",data,waitTime);
	else
		--GHI_Message(data);
		if GHI_IsSpamBelowLimit() then
			SendChatMessage(data,"SAY");
			GHI_SpamCountIncrease();
			if not(GHI_IsSpamBelowLimit()) then
				GHI_Message(GHI_SPAM_LIMIT_REACHED);
			end			
		end
		--SendChatMessage(data,"say");
		
	end
end

function GHI_IsStdEmote(command)
	if not(type(command) == "string") then return false end
	if command == "" then return false end;
	
	local i = 1;
	local j = 1;
	local cmdString = getglobal("EMOTE"..i.."_CMD"..j);
	while ( cmdString ) do
		if ( strfind(cmdString, command, 1, 1) ) then
			if cmdString == "/"..command then
				return i;
			end
		end
		j = j + 1;
		cmdString = getglobal("EMOTE"..i.."_CMD"..j);
		if ( not cmdString ) then
			i = i + 1;
			j = 1;
			cmdString = getglobal("EMOTE"..i.."_CMD"..j);
			
			-- todo: cases for new emotes.
		end
	end
	return false;
	--[[
	for i = 1,170 do
		local a = getglobal("EMOTE"..i.."_TOKEN);
		if a == data or a == string.upper(data) then
			return true;
		
		end
	end
	return false;]]
end

function GHI_DoScript(data,waitTime)
	
	if type(waitTime) == "number" and waitTime > 0 then
		GHI_AddActionToQueue("script",data,waitTime,GHI_GetCurrentItem());
	else	
		RunScript(data);
	end
end

function GHI_SetItemUseInfo(ID,index,info)
	if not(ID) or not(index) then return end;
	if not(type(GHI_ItemUseInfo) == "table") then
		GHI_ItemUseInfo = {};
	end
	if not(type(GHI_ItemUseInfo[ID]) == "table") then
		GHI_ItemUseInfo[ID] = {};
	end
	GHI_ItemUseInfo[ID][index] = info;
end

function GHI_GetItemUseInfo(ID,index)
	if not(ID) or not(index) then return end;
	if not(type(GHI_ItemUseInfo) == "table") then
		return;
	end
	if not(type(GHI_ItemUseInfo[ID]) == "table") then
		return
	end
	return GHI_ItemUseInfo[ID][index];
end


function GHI_CheckReq(Type,text)
	if (type(Type)=="string" and type(text)=="string") then
		local parts = {strsplit(",",text)};
		local req_forfilled = false;
		for j = 1,table.getn(parts) do
			-- substract space seperated info
			local t = parts[j];
			local a,b = 0;
			while a and t do
				b = a;
				a = strfind(t," ",b+1);
			end
			
			local t1 = "";
			if b > 0 then
				t1 = strsub(t,0,b-1);
			end
			local t2 = strsub(t,b+1);
			
			local upper,lower;
			
			-- check if t2 is number or part of t1
			local IsNumber = false;
			local numPlus;
			local range;
			for k = 1,strlen(t2) do
				local s = strbyte(t2,k)
				if type(s)=="number" then
					if not((s>=48 and s<=57) or s == 45 or s==43) then
						IsNumber = false;
						break;
					elseif s == 43 then
						numPlus = k;
					elseif s == 45 then
						range = k;
					else
						IsNumber = true;
					end
				end
			end
			--GHI_Message("t1: "..t1.." t2: '"..t2.."' b "..b);
			if IsNumber == false then
				if t1 == "" then
					t1 = t2;
				else
					t1 = t1.." "..t2;
				end
				t2 = "";
			else
				if range then
					lower = strsub(t2,1,range-1);
					upper = strsub(t2,range+1);
				elseif numPlus then
					lower = strsub(t2,1,numPlus-1);
					upper = nil;
				else
					lower = t2;
					upper = t2;
				end
				if lower then
					lower = tonumber(lower);
				end
				if upper then
					upper = tonumber(upper);
				end
			end
			--GHI_Message("Send Req: "..Type.." ; '"..t1.."'");
			local req = GHI_GetReqResult(Type,t1);
			--GHI_Message(type(req));
			if type(req) == "boolean" then 
				if req == true then --GHI_Message("true");
					req_forfilled = true;
				end
			elseif type(req) == "number" then
				if type(lower)=="number" and not(upper) and req >= lower then
					req_forfilled = true;
				elseif type(lower)=="number" and type(upper)=="number" and req >= lower and req <= upper then
					req_forfilled = true;
				else
					--forfilled = false;
					
				end
			end
		end
		return req_forfilled;
	end
end

function GHI_GetReqResult(filter,data)
	if not(filter) then return true; end
	if filter == "Name" then
		local n = UnitName("player");
		if n == data then 
			return true;
		else 
			return false;
		end;
	elseif filter == "Level" then
		local l = UnitLevel("player");
		return l;
	elseif filter == "Zone" then
		local n = GetRealZoneText();
		if n == data then 
			return true;
		else 
			return false;
		end;
	elseif filter == "SubZone" then
		local n = GetSubZoneText();
		if n == data then 
			return true;
		else 
			return false;
		end;
	elseif filter == "Guild" then
		local n = GetGuildInfo("player");
		if n == data then 
			return true;
		else 
			return false;
		end;
	elseif filter == "Class" then
		local n = UnitClass("player");
		if n == data then 
			return true;
		else 
			return false;
		end;
	elseif filter == "Race" then
		local n = UnitRace("player");
		if n == data then 
			return true;
		else 
			return false;
		end;
	elseif filter == "Gender" then
		local d = 0;
		if strlower(data) == "n" or strlower(data) == "none" then
			d = 1;
		elseif strlower(data) == "m" or strlower(data) == "male" then
			d = 2;
		elseif strlower(data) == "f" or strlower(data) == "female" then
			d = 3;
		end
		local n = UnitSex("player");
		if n == d then 
			return true;
		else 
			return false;
		end;
	elseif filter == "Normal Item" then
		local n = FindItem(data);
		if not(n==nil) then 
			return true;
		else 
			return false;
		end;
	elseif filter == "Base Stats" then
		d = 0;
		if strlower(data) == "str" or strlower(data) == "strength" then
			d = 1;
		elseif strlower(data) == "agi" or strlower(data) == "agility" then
			d = 2;
		elseif strlower(data) == "sta" or strlower(data) == "stamina" then
			d = 3;
		elseif strlower(data) == "int" or strlower(data) == "intellect" then
			d = 4;
		elseif strlower(data) == "spi" or strlower(data) == "spirit" then
			d = 5;
		elseif strlower(data) == "arm" or strlower(data) == "armor" then
			d = 6;
		end
		local n = 0;
		if (d < 6) then
			_,n = UnitStat("player",d);
		else
			n = UnitArmor("player");
		end
		return n;
	elseif filter == "Skill" then
		for i = 1,GetNumSkillLines() do
			local name,_,_,level,_,temp = GetSkillLineInfo(i);
			if level and temp then 
				level = level + temp;
			end
			if strlower(name) == strlower(data) then
				return level;
			end		
		end		
		return 0;
	elseif filter == "Reputation" then
		for i = 1,GetNumFactions() do
			local name,_,_,_,_,level  = GetFactionInfo(i);
			if strlower(name) == strlower(data) then
				return level;
			end		
		end		
		return 0;
	elseif filter == "Honor Kills" then
		local n = GetPVPLifetimeStats();
		return n;
	elseif filter == "Normal Buff" then
		local i = 1;
		local name = "";
		local k = nil;
		while not(name == nil) and k == nil do
			name = UnitBuff("player",i);
			if name == data then
				k = i;
			end
			i = i +1;
		end
		i = 1;
		while not(name == nil) and k == nil do
			name = UnitDebuff("player",i); 
			if name == data then
				k = i;
			end
			i = i +1;
		end

		if not(k == nil) then 
			return true;
		else 
			return false;
		end;
	elseif filter == "GHI Buff" then
		local i = 1;
		local name = "";
		local k = nil;
		while not(name == nil) and k == nil do
			if type(GHI_BuffList[i]) == "table" then
				name = GHI_BuffList[i].name;
			else
				name = nil;
			end
			if name == data then
				k = i;
			end
			i = i +1;
		end
		i = 1;
		while not(name == nil) and k == nil do
			if type(GHI_DebuffList[i]) == "table" then
				name = GHI_DebuffList[i].name;
			else
				name = nil;
			end

			if name == data then
				k = i;
			end
			i = i +1;
		end

		if not(k == nil) then 
			return true;
		else 
			return false;
		end;
	

	elseif filter == "LUA Statement" then 
		data=gsub(data,"\21"," ");
		data=gsub(data,"\22",",");
		RunScript("function GHI_ReqDynamicTest() return " .. data .. ";end");
		
		if GHI_ReqDynamicTest() == true or GHI_ReqDynamicTest() == 1 then
			return true;
		else
			return false;
		end
	end
	
	return true;
end

function GHI_GetReqSuffix(filter)
	if filter == "Level" then
		return "Level ";
	elseif filter == "Honor Kills" then
		return "Honor Kills "
	end
	
	return "";

end

function GHI_InsertLinks(text,ID)
	if not(ID) then return text; end
	local link = GHI_GenerateLink(ID);
	--GHI_Message("link: "..link);
	if link then
		--text = gsub(text,"\%l","(Spellbook.)");
		---GHI_Message(strfind(text,"\%l"));
		local t = nil;
		for i=0,10 do -- %r
			if t == nil then
				t = string.find(string.lower(text),"%l",0,true);
			else
				t = string.find(string.lower(text),"%l",t+1,true);
			end;	
			
			
			if t == nil then
				i = 11;
			else
				text = string.sub(text,0,t-1)..link..string.sub(text,t+2);
			end
		end
		--text = gsub(text,"%L",link);
		--text = text.." "..link;
	end
	return text;
end

local function comp_versions(t1,t2)
	local v1 = t1[1];
	local v2 = t2[1];
	if tostring(tonumber(v1)) == v1 then v1 = tonumber(v1); else v1 = strbyte(v1,1) + 255; end
	if tostring(tonumber(v2)) == v2 then v2 = tonumber(v2); else v2 = strbyte(v2,1) + 255; end
	if v1 > v2 then 
		return true;
	elseif v1 < v2 then
		return false;
	else --  v1 = v2
		table.remove(t1,1);
		table.remove(t2,1);
		if table.getn(t2) == 0 then
			return true;
		elseif table.getn(t1) == 0 then
			return false;
		else
			return comp_versions(t1,t2);
		end
	end
end

--  returs true if v1 >= v2 else false
function GHI_CompareVersions(v1,v2)
	if not(type(v1) == "string" or type(v1) == "number") then return false end
	if not(type(v2) == "string" or type(v2) == "number") then return false end
	local t1 = {strsplit(".",v1)};
	local t2 = {strsplit(".",v2)};
	return comp_versions(t1,t2);
end

---color picker

local r,g,b = 0, 0, 0;
function GHIShowColorPicker()
ColorPickerFrame:SetColorRGB(r,g,b);
--ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a;
ColorPickerFrame.previousValues = {r,g,b,a};
ColorPickerFrame.func = GHIColorChanged;
ColorPickerFrame.hasOpacity     =  false;
ColorPickerFrame.cancelFunc = GHIColorChanged();

ColorPickerFrame:Hide(); -- Need to run the OnShow handler.
ColorPickerFrame:Show();
end



function GHIColorChanged(restore)
local newR, newG, newB, newA;
if restore then
-- The user bailed, we extract the old color from the table created by ShowColorPicker.
newR, newG, newB, newA = unpack(restore);
return;
end
-- Something changed
--newA = OpacitySliderFrame:GetValue(); 
newR, newG, newB = ColorPickerFrame:GetColorRGB();


-- Update our internal storage.
r, g, b = newR, newG, newB;
--print(r)
-- And update any UI elements that use this color...
end
--	Spam filter
GHI_SpamCount = 0;
function GHI_IsSpamBelowLimit()
	return (GHI_SpamCount < 6);

end

function GHI_SpamCountIncrease()
	GHI_SpamCount = GHI_SpamCount + 1;
end

function GHI_SpamCountReset()
	GHI_SpamCount = 0;
end


	
