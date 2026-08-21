
-- This module is interacting with some other addons to make GHI compatible with thems




GHI_CompAddons={};

function GHI_CompOnAddonsLoaded()
	--GetAddOnMetadata("GHI", "Title");
	if (not(GetAddOnMetadata("Prat", "title")==nil)  and not(Prat == nil)) then
		GHI_CompAddons["Prat"] = true;
		
	end
	if (not(GetAddOnMetadata("ForgottenChat", "title")==nil)  and not(FCCC_OnLoad == nil)) then
		GHI_CompAddons["ForgottenChatCC"] = true;
		GHI_OrigFCCC_IncomingMessage = FCCC_IncomingMessage;
		FCCC_IncomingMessage = GHI_FCCC_IncomingMessage;
		
		GHI_OrigFCCC_OutgoingMessage = FCCC_OutgoingMessage;
		FCCC_OutgoingMessage = GHI_FCCC_OutgoingMessage
	end
	
	if (not(GetAddOnMetadata("GHD", "title")==nil)  and not(GHD_MF == nil)) and not(GHD_CompInGHI == false) then
		GHI_CompAddons["GHD"] = true;
		
		GHI_OrigGHD_SendDataToBuffer = GHD_SendDataToBuffer
		GHD_SendDataToBuffer = GHI_GHD_SendDataToBuffer;
		
		
		
		GHI_orig_ChatFrame_MessageEventHandler2 = ChatFrame_MessageEventHandler;
		ChatFrame_MessageEventHandler = GHI_ChatFrame_MessageEventHandler2;
	else
		GHI_orig_ChatFrame_MessageEventHandler2 = function() end;
	end
	
	if (not(GetAddOnMetadata("XPerl_PlayerBuffs", "title")==nil)  and not(XPerl_PlayerBuffs_OnUpdate == nil)) then
		GHI_CompAddons["XPerl_PlayerBuffs"] = true;		
	end
	
	if (not(GetAddOnMetadata("XPerl_Target", "title")==nil)  and not(XPerl_Target == nil)) then
		GHI_CompAddons["XPerl_Target"] = true;
	end
	
	if GHI_CompAddons["XPerl_PlayerBuffs"] == true  or  GHI_CompAddons["XPerl_Target"] == true then
		XPerl_UnitBuff = function(unit, index, flag)
			return GHI_UnitBuff(unit, index);
		end
		XPerl_UnitDebuff = function(unit, index, flag)
			return GHI_UnitDebuff(unit, index);
		end
	end
	 
end





--	FCCC
function GHI_FCCC_IncomingMessage(Name, Text, afk)
	
	local text = Text;
	local linkText,a,b,c,d = 0;
	local WaitForLink = false;
	local waitIndex = {};
	--GHI_Message("Handle Incomming");
	
	a = 0;
	for i=1,5 do
		--GHI_Message("A");
		a = GHI_SearchStringForChar(text,91,a+1);
		b = strfind(text,"]",a);
		if a and b then
			c = strbyte(text,a-2);
			d = strbyte(text,b+1);
			--GHI_Message(c);
			--GHR_Message(d);
			if not(c == 124 or d == 124) then
				linkText = strsub(text,a+1,b-1);
				
				--GHI_SendDataToBuffer("ReqLink",linkText,arg2);  todo fix this
				GHI:SendPrioritizedMessage("ALERT","WHISPER",arg2,false,"SuspectedLinkName",linkText)				
				WaitForLink = true;
				--text = strsub(text,0,a-1).."["..strsub(text,a+1,b-1).."]"..strsub(text,b+1);
				
			end
		else 	
			break;
		end
	end
	
	
	if WaitForLink == true then
		local list = {}
		list.event = event;
		list.text = text;
		list.sender = Name;
		list.time = time();
		list.afk = afk;
		list.FCCC = true;
		list.self = false;
		
		table.insert(GHI_IncMsgWaiting,list);
		
		
		return;
	end
	
		
	GHI_OrigFCCC_IncomingMessage(Name, Text, afk)
end

function GHI_FCCC_OutgoingMessage(Name, Text, Language)
	
	local text = Text;
	local linkText,a,b,c,d = 0;
	
	local waitIndex = {};
	
	local WaitForLink = false;
	
	a = 0;
	for i=1,5 do
		--GHI_Message("A");
		a = GHI_SearchStringForChar(text,91,a+1);
		b = strfind(text,"]",a);
		if a and b then
			c = strbyte(text,a-2);
			d = strbyte(text,b+1);
			--GHI_Message(c);
			--GHR_Message(d);
			if not(c == 124 or d == 124) then
				linkText = strsub(text,a+1,b-1);
				
				local isItem = false;
				for index1,value1 in pairs(GHI_SendItemsID) do 
					if GHI_IsOfficialItem(value1) then  
						if type(GHI_OfficialItemData[tonumber(value1)]) == "table" then --message(value1.." is an official item and the data exsists.");
							if GHI_OfficialItemData[tonumber(value1)].name == linkText then
								sendToSelf = true;
								isItem = true;
								table.insert(waitIndex,value1);
								break;
							end
						end
					else 
						if type(GHI_ItemData[value1]) == "table" then
							if GHI_ItemData[value1].name == linkText then
								sendToSelf = true;
								isItem = true;
								table.insert(waitIndex,value1);
								break;
							end
						end
					end
				end
				if not(isItem == true) then
					
					for index1,value1 in pairs(GHI_SendNotItems) do 
						if value1 == linkText then
							sendToSelf = true;
							table.insert(waitIndex,"0_"..value1);
							
							break;
						end
					end
				end
				
				--[[for index1,value1 in pairs(GHI_ItemData) do 
					if type(value1) == "table" then
						if value1.name == linkText then
							--GHI_SendDataToBuffer("ItemReplyEnd",index1,GHI_PName);	
							sendToSelf = true;
							table.insert(waitIndex,index1);
							--GHI_RecieveLinkEnd(index1,GHI_PName);
							--GHI_Message("Request link for "..linkText.." to self");
							break;
						end
					end
				end]]
				
				WaitForLink = true;
				--text = strsub(text,0,a-1).."["..strsub(text,a+1,b-1).."]"..strsub(text,b+1);
				
			end
		else 	
			break;
		end
	end
	
	
	if WaitForLink == true then
		local list = {}
		list.event = event;
		list.text = text;
		list.to = Name;
		list.sender = GHI_PName;
		list.time = time();
		list.afk = afk;
		list.FCCC = true;
		list.self = true
		list.lan = Language;
		
		
		table.insert(GHI_IncMsgWaiting,list);
		
		if (sendToSelf == true) then
			--GHI_Message("Contained "..table.getn(waitIndex..") links");
			for index1,value1 in pairs(waitIndex) do 
				GHI_RecieveLinkEnd(value1,GHI_PName);
				
			end
		end
		--GHI_Message("Requested link");
		return;
	end
	
	
	GHI_OrigFCCC_OutgoingMessage(Name, Text, Language)
end

function GHI_FCCC_InsertLink(link)
	if not(GHI_CompAddons["ForgottenChatCC"]) then return false end
	
	for i = 1,12 do
		local f1 = getglobal("Window"..i.."_Chat");
		if not(f1 == nil) then
			if f1:IsShown() == 1 then
				local f2 = getglobal("Window"..i.."_EditBox");
				if not(f2 == nil) then
					if f2:IsShown() == 1 then
						local t = f1:GetText();
						f2:SetText(t.." "..link);
						--GHI_Message("inserted in "..f:GetName());
						return true
					end
				end
			end
		end
	end
	return false
end


--	GHD
function GHI_GHD_SendDataToBuffer(metaData,data,reciever)
	if reciever == "" or reciever == nil then return end;
	
	local a = strsub(reciever,0,1);
	local b = strsub(reciever,2);
	local new = "";
	
	if a then
		local va = tonumber(strbyte(a));
		if (va >= 65 and va <= 90) or (va >= 97 and va <= 122) then
			new = strupper(a)..strlower(b);
		else 
			new = reciever;
		end
	end
	
	if new == nil or new == "" or new == " " then return end;
	
	if not(new == LASTSENDER) then
	--GHR_Message("Queued GHD data to "..new..": "..metaData);
	LASTSENDER = new;
	end
	--GHI:SendPrioritizedMessage("BULK","WHISPER",reciever,false,"GHD",metaData,data)
	ChatThrottleLib:SendAddonMessage("BULK", metaData, tostring(data), "WHISPER", new, nil)
end


