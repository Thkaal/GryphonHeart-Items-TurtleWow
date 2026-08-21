
--	==================================== Outgoing item links	==================================== 

function GHI_ItemLinkHookings()
	GHI_OrigSetItemRef = SetItemRef;
	SetItemRef = GHI_SetItemRef;
	
	GHI_origSendChatMessage = SendChatMessage;
	SendChatMessage = GHI_SendChatMessage;
	
	-- inc chat
	GHI_origChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler;
	ChatFrame_MessageEventHandler = GHI_ChatFrame_MessageEventHandler;

end



function GHI_GenerateLink(ItemID)
	--GHI_Message("Generate link for "..ItemID);
	if ItemID == nil then return end;
	local name,icon,quality = GHI_GetItemInfo(ItemID);
	if not(name) then return end;
	local link;
	local color = ITEM_QUALITY_COLORS[quality];
	link = "|CFF" ..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255) .."|HGHitem:"..ItemID..":0:0:0:0:0:0:0|h["..name.."]|h|r"
	
	return link;
end

function GHI_SetItemRef(link, text, button)

	

	local prefix = string.sub(link,0,6)

	if prefix == "GHitem" then
		local a = strfind(link,":",0);
		if not(a) then return end;
		local b = strfind(link,":",a+1);
		if not(b) then return end;
			
		local ID = strsub(link,a+1,b-1);
		if IsShiftKeyDown() == 1 then
			local GHI_link = GHI_GenerateLink(ID);
			if ( not(ChatEdit_InsertLink(GHI_link)) and not(GHI_FCCC_InsertLink(GHI_link)) ) then
			end
		else
			if ItemRefTooltip:IsShown() and GHI_LastLinkID == ID then
				ItemRefTooltip:Hide();
			else
				GHI_ItemRefTooltip(ID);
			end
		end
		
		GHI_LastLinkID = ID;
	else
		GHI_OrigSetItemRef(link, text, button);
		GHI_LastLinkID = 0;
	end
end

function GHI_ItemRefTooltip(ID) 
	ShowUIPanel(ItemRefTooltip);
	if ( not ItemRefTooltip:IsShown() ) then
		ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
	end
	GHI_SetTooltipInfo(ItemRefTooltip,ID);
	ItemRefTooltip:Show();
	--[[
	if not(ID) then return; end
	if tonumber(ID) then
		ID = tonumber(ID);
	end
	
	local name,icon,quality,white1,white2,comment,stackSize,creater,version,rightClick,rightClicktext = GHI_GetItemInfo(ID);
	if name == nil then ItemRefTooltip:Hide();  return; end;
	
	
	ShowUIPanel(ItemRefTooltip);
	if ( not ItemRefTooltip:IsShown() ) then
		ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
	end
	
	local color = ITEM_QUALITY_COLORS[quality];
	local qMark = strchar(34);
	
	ItemRefTooltip:ClearLines()
	if not(type(name) == "nil")  then
		ItemRefTooltip:AddLine(name,color.r,color.g,color.b);
	end
	--GHI_Message("white 1 is : "..type(white1));
	if not(type(white1) == "nil") then
		ItemRefTooltip:AddLine(white1, 1, 1, 1);
	end
	if not(type(white2) == "nil") then
		ItemRefTooltip:AddLine(white2, 1, 1, 1);
	end
	if not(type(comment) == "nil") then
	  if not(comment == "") then
		ItemRefTooltip:AddLine(qMark..comment..qMark, 1.0, 0.8196079, 0,1);
	  end
	end
	
	--if type(rightClick) == "table" then 
	if not(type(rightClicktext) == "nil") then 
		local color2 = ITEM_QUALITY_COLORS[2];
		ItemRefTooltip:AddLine("Use: "..rightClicktext.."",color2.r,color2.g,color2.b);
	end
	--end
	if not(creater==nil) then
		local color2 = ITEM_QUALITY_COLORS[2];
		ItemRefTooltip:AddLine("<Made by "..creater..">",color2.r,color2.g,color2.b);
	end
	
	if GHI_IsOfficialItem(ID) then  -- official item
		ItemRefTooltip:AddLine("Official GH item", 0.7,0,0);
	else
		ItemRefTooltip:AddLine("Custom made item",  0.0, 0.7, 0.5);
	end
	
	
	
	ItemRefTooltip:Show();  --]]

end

GHI_SendItemsID = {};
GHI_SendNotItems = {};
--	Catch item links in outgoing text
function GHI_SendChatMessage(text, type, language, target, ...)
	
	
	--- search for []   without links
	local a,b,c,d,e,f;
	a = 0;
		while a do
			--GHI_Message("A");
			a = GHI_SearchStringForChar(text,91,a+1);
			b = strfind(text,"]",a);
			if not(a == nil) and b then 
				c = strbyte(text,a-2);
				d = strbyte(text,b+1);
				if not(c == 124 or d == 124) then
					e = strsub(text,a+1,b-1);
					
					table.insert(GHI_SendNotItems,1,e);
					GHI_SendNotItems[10] = nil;
				end
			end
		end
	
	
	--GHI_Message("Handle Outgoing");

	local a,b,c,d,e,ID,n1,n2 = 0;
	local link,name;

	off = 0;
	for i=1,5 do
		a = string.find(text,"|HGHitem",0);
		if a then
			--GHR_Message("#"..i);
			b = string.find(text,"|C",a-10);	
			c = string.find(text,"|r",a);	
			--GHR_Message(a);
			link = string.sub(text,b,c+1)
			n1 = string.find(link,"|h")
			n2 = string.find(link,"|h",n1+1);
			
			
			name = string.sub(link,n1+3,n2-2)
			
			-- find ID
			d = string.find(text,":",a);
			e = string.find(text,":",d+1);
			
			ID = string.sub(text,d+1,e-1);
			table.insert(GHI_SendItemsID,1,ID);
			GHI_SendItemsID[10] = nil;
			
			
			--text = gsub(text,link,"<"..name..">");
			text = strsub(text,0,b-1).."["..name.."]"..strsub(text,c+2);
		else
			break;	
		end
	end

	
	GHI_origSendChatMessage(text, type, language, target, unpack(arg))
end

--	==================================== Incomming item links 	====================================
--  block std emotes after an emote with "  " in the end
local blockNextStdEmoteFromPlayer = {};
local msgToBlock,playerToBlock;

-- 	func hooking in GHI_ItemLinkHookings

GHI_IncMsgWaiting = {}
GHI_LastInc = {}
GHI_PrevEventOnWait = false;


GHI_MessageErrorsExpected_A = {}
GHI_MessageErrorsExpected_B = {}

function GHI_ChatFrame_MessageEventHandler(self, event, ...)
	-- Turtle/Vanilla private GHI transport.  WoW 1.12 has no addon-message
	-- WHISPER distribution, so GHI uses encoded ordinary whispers.  Suppress
	-- both received transport packets and our own whisper-inform echo.
	if (event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM") and GHI5_IsPrivateWire and GHI5_IsPrivateWire(arg1) then
		return;
	end

	-- std emote blocking
	if GHI_MiscData["block_std_emote"] == true then
		if event == "CHAT_MSG_TEXT_EMOTE" then
			if arg1 == msgToBlock and arg2 == playerToBlock then
				return;
			elseif blockNextStdEmoteFromPlayer[arg2] == true then
				msgToBlock = arg1;
				playerToBlock = arg2;
				blockNextStdEmoteFromPlayer[arg2] = false;
				return;				
			end
		end

		if event == "CHAT_MSG_EMOTE" then
			if strsub(arg1,string.len(arg1)-2,string.len(arg1)) == "   " then
				blockNextStdEmoteFromPlayer[arg2] = true;
			end
		end
		
	end
	
	if event == "CHAT_MSG_SYSTEM" then
		
		--GHI_Message(gsub(ERR_CHAT_PLAYER_NOT_FOUND_S,"%%s","%%a+"));
		--local player = string.match(arg1,gsub(ERR_CHAT_PLAYER_NOT_FOUND_S,"%%s","%%a"));
		local player = gsub(string.match(arg1,"'.*'") or "","'","");
		--print(arg1)
		--print("player: ",string.match(arg1,"'.*'"));
		if player and format(ERR_CHAT_PLAYER_NOT_FOUND_S,player) == arg1 and (GHI_MessageErrorsExpected_A[player] or GHI_MessageErrorsExpected_B[player]) then
			return;
		end
	end
	
	
	msgToBlock = "";
	playerToBlock = "";
	
	-- link searching
	if not(GHI_LastInc.event == event and GHI_LastInc.arg1 == arg1 and GHI_LastInc.arg2 == arg2 and GHI_LastInc.arg3 == arg3 and GHI_LastInc.arg4 == arg4) then -- and not(GHI_TestTrigger == true and not(GHI_CompAddons["Prat"]==true)) then
		C1 = C1 or 0;
		C1 = C1 + 1;
		
		
		GHI_DebugLog = GHI_DebugLog or {};
		--[[table.insert(GHI_DebugLog,"New");
		if not(GHI_LastInc.event == event) then table.insert(GHI_DebugLog,"Event not the same."); end
		if not(GHI_LastInc.arg1 == arg1) then table.insert(GHI_DebugLog,"arg1 not the same. "..(GHI_LastInc.arg1 or "nil") .." == "..(arg1 or "nil")); end
		if not(GHI_LastInc.arg2 == arg2) then table.insert(GHI_DebugLog,"arg2 not the same."); end
		if not(GHI_LastInc.arg3 == arg3) then table.insert(GHI_DebugLog,"arg3 not the same."); end
		if not(GHI_LastInc.arg4 == arg4) then table.insert(GHI_DebugLog,"arg4 not the same."); end --]]
		
		GHI_PrevEventOnWait = false;
		--GHR_Message("chat frame event: "..event);
		GHI_LastInc.event = event;
		GHI_LastInc.arg1 = arg1;
		GHI_LastInc.arg2 = arg2;
		GHI_LastInc.arg3 = arg3;
		GHI_LastInc.arg4 = arg4;
		local sendToSelf = false;
		local WaitForLink = false;
		
		if type(GHI_Temp_Log) == "table" then
			table.insert(GHI_Temp_Log,GHI_LastInc);
		end
		
		local a;
		if type(arg4) == "string" then
			a = strfind(arg4,"xtensionxtooltip2");
			-- epilogue edit
			if not a then
				a = strfind(strlower(arg4),"acecommghi");
			end
			-- end of epilogue edit
		end
		
		
		--table.insert(GHI_DebugLog,"Part A");
		
		if string.sub(event,1,8) == "CHAT_MSG" and not(event=="CHAT_MSG_SYSTEM") and not(arg2=="") and a == nil then
			local text = arg1;
			local linkText,a,b,c,d = 0;
			
			local waitIndex = {};
			--GHI_Message("Handle Incomming");
			--table.insert(GHI_DebugLog,"Part B");
			a = 0;
			for i=1,5 do --GHI_Message("A -3");
				--GHI_Message("A");
				a = GHI_SearchStringForChar(text,91,a+1);
				b = strfind(text,"]",a);
				if not(a == nil) and b then --GHI_Message("a and b found in "..text);
					c = strbyte(text,a-2);
					d = strbyte(text,b+1);
					--GHI_Message(c);
					--GHR_Message(d);
					if not(c == 124 or d == 124) then
						linkText = strsub(text,a+1,b-1); 
						--c,d = strfind(text,linkText);
						
						if GHI_PName == arg2 or event == "CHAT_MSG_WHISPER_INFORM" then 
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
							
							
							--[[
							for index1,value1 in pairs(GHI_SendItemsID) do 
								if type(value1) == "table" then
									if value1.name == linkText then
										
										sendToSelf = true;
										table.insert(waitIndex,index1);
										
										break;
									end
								end
							end]]
						else
							--GHE:Msg("SendPrioritizedMessage(%s,%s,%s,%s,%s,%s);","ALERT","WHISPER",arg2,false,"SuspectedLinkName",linkText)
							GHI:SendPrioritizedMessage("ALERT","WHISPER",arg2,false,"SuspectedLinkName",linkText)
							--GHI_SendDataToBuffer("ReqLink",linkText,arg2);
						end
						
						WaitForLink = true;
						--text = strsub(text,0,a-1).."["..strsub(text,a+1,b-1).."]"..strsub(text,b+1);
						
					end
				else 	
					break;
				end
			end
			--table.insert(GHI_DebugLog,"Part C");
			
			if WaitForLink == true then
				GHI_PrevEventOnWait = true;
				local list = {}
				list.event = event;
				list.text = text;
				list.sender = arg2;
				list.time = time();
				list.arg3 = arg3;
				list.arg4 = arg4;
				list.arg5 = arg5;
				list.arg6 = arg6;
				list.arg7 = arg7;
				list.arg8 = arg8;
				list.arg9 = arg9;
				list.arg10 = arg10;
				list.arg11 = arg11;
				list.arg12 = arg12;
				list.arg13 = arg13;
				list.arg14 = arg14;
				list.this = this;
				list.self = self;
				
				table.insert(GHI_IncMsgWaiting,list);
				
				if (sendToSelf == true) then
					--GHI_Message("Contained "..table.getn(waitIndex..") links");
					--GHI_Message("A");
					for index1,value1 in pairs(waitIndex) do  --GHI_Message("B");
						if event == "CHAT_MSG_WHISPER_INFORM" then
							GHI_RecieveLinkEnd(value1,arg2);
						else
							GHI_RecieveLinkEnd(value1,GHI_PName);
						end
					end
				end
				--GHI_Message("Requested link");
				GHI_LastInc.arg1 = arg1;
				--table.insert(GHI_DebugLog,"2 Setting last arg1 to "..arg1);
				return;
			end
			
			arg1 = text;
			GHI_LastInc.arg1 = arg1;
			--table.insert(GHI_DebugLog,"Setting last arg1 to "..arg1);
		end
	elseif GHI_TestTrigger == true then
		---[[
		GHI_TestTrigger = false;
		--Prat:ChatFrame_MessageEventHandler(event)
		--[[
		GHI_Message("Running delayed trigger");
		table.insert(GHI_DebugLog,"Running delayed trigger on "..(event or "nil"));
		if GHI_CompAddons["Prat"] == true  then
			if event == "CHAT_MSG_CHANNEL" then
				for i = 1,7 do
					setglobal("this", getglobal("ChatFrame"..i));
					Prat:ChatFrame_MessageEventHandler(event)
				end	
			else
				-- todo: run for other chat windows
				Prat:ChatFrame_MessageEventHandler(event)
			end
		end   --]]
		
	else
		if GHI_PrevEventOnWait == true then
			--GHI_Message(arg1.." 9: "..(arg9).." 10: "..(arg10).." 11: "..(arg11).." This name: "..this:GetName())
			return;
		end
	end
	
	GHI_origChatFrame_MessageEventHandler(self, event, unpack(arg))
end

function GHI_SearchStringForChar(str,char,offset)
	if not(offset) then 
		offset = 1;
	end
	for i = offset,strlen(str) do
		if strbyte(strsub(str,i,i)) == char then
			return i;
		end
	end

end
