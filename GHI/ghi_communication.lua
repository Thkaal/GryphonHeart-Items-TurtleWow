-- Turtle WoW native GHI communication layer (Lua 5.0 compatible)
--
-- Directed GHI traffic on WoW 1.12/TurtleWoW uses a dedicated custom
-- chat channel named "GHI5".  The channel is joined but is deliberately
-- never added to a chat frame, so normal GHI traffic remains out of the
-- visible chat window.  Every directed packet contains its intended
-- recipient; clients ignore packets addressed to another player.
--
-- Non-directed distributions (PARTY/RAID/GUILD/etc.) continue to use
-- SendAddonMessage exactly as before.

GHI = GHI or {};
GHI.ownName = UnitName("player");

local GHI5_CHANNEL_NAME = "GHI5";
local GHI5_CHANNEL_MARK = "GHI5:";
local GHI5_CHANNEL_ID = 0;
local GHI5_CHANNEL_RETRY = 2;

-- Temporary buff-transport diagnostics.  Set this to false after testing.
GHI5_BUFF_DEBUG = true;

local function ghi5_buff_debug(text)
    if not GHI5_BUFF_DEBUG then return; end
    local msg = "GHI5 BUFF DEBUG: "..tostring(text or "");
    if type(GHI_Message) == "function" then
        GHI_Message(msg);
    elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(msg);
    end
end

local function ghi5_table_len(t)
    if type(t) ~= "table" then return -1; end
    return table.getn(t);
end

local GHI5_recv = {};
local GHI5_seq = 0;
local GHI5_eventFrame = nil;
local GHI5_outQueue = {};
local GHI5_nextJoinAttempt = 0;

local function ghi5_count(t)
    local n=0; for _ in pairs(t) do n=n+1; end; return n;
end

local function ghi5_ser(v)
    local ty=type(v);
    if ty=="nil" then return "Z";
    elseif ty=="boolean" then return v and "B1" or "B0";
    elseif ty=="number" then local x=tostring(v); return "N"..string.len(x)..":"..x;
    elseif ty=="string" then return "S"..string.len(v)..":"..v;
    elseif ty=="table" then
        local out={"T",tostring(ghi5_count(v)),":"};
        for k,val in pairs(v) do table.insert(out,ghi5_ser(k)); table.insert(out,ghi5_ser(val)); end
        return table.concat(out);
    end
    return "Z";
end

local function ghi5_num(s,p)
    local c=string.find(s,":",p,true); if not c then return nil,p; end
    return tonumber(string.sub(s,p,c-1)),c+1;
end

local function ghi5_des(s,p)
    p=p or 1; local tag=string.sub(s,p,p); p=p+1;
    if tag=="Z" then return nil,p;
    elseif tag=="B" then local b=string.sub(s,p,p)=="1"; return b,p+1;
    elseif tag=="N" or tag=="S" then
        local n; n,p=ghi5_num(s,p); if not n then return nil,p; end
        local v=string.sub(s,p,p+n-1); p=p+n; if tag=="N" then v=tonumber(v); end; return v,p;
    elseif tag=="T" then
        local n; n,p=ghi5_num(s,p); local t={}; if not n then return t,p; end
        local i; for i=1,n do local k,v; k,p=ghi5_des(s,p); v,p=ghi5_des(s,p); if k~=nil then t[k]=v; end; end
        return t,p;
    end
    return nil,p;
end

-- The custom channel is ordinary chat transport, so the complete directed
-- envelope is hex encoded.  This keeps GHI serialization bytes, WoW markup
-- characters, delimiters and player names out of the visible wire format.
local function ghi5_hex_encode(text)
    local out = {};
    local i;
    for i=1,string.len(text) do
        table.insert(out,string.format("%02X",string.byte(text,i)));
    end
    return table.concat(out);
end

local function ghi5_hex_decode(text)
    if type(text) ~= "string" then return nil; end
    if math.mod(string.len(text),2) ~= 0 then return nil; end
    local out = {};
    local i;
    for i=1,string.len(text),2 do
        local n = tonumber(string.sub(text,i,i+1),16);
        if not n then return nil; end
        table.insert(out,string.char(n));
    end
    return table.concat(out);
end

-- TurtleRP protects its communication channel from the optional drunken-chat
-- suffix.  GHI5's payload is hex, so the only remaining concern is a suffix
-- appended after the encoded text.  Remove it exactly when present.
local GHI5_DRUNK_SUFFIX = nil;
if type(SLURRED_SPEECH) == "string" then
    GHI5_DRUNK_SUFFIX = string.gsub(SLURRED_SPEECH,"%%s","",1);
end

local function ghi5_strip_drunk_suffix(text)
    if type(text) ~= "string" then return text; end
    if type(GHI5_DRUNK_SUFFIX) == "string" and GHI5_DRUNK_SUFFIX ~= "" then
        local suffixLen = string.len(GHI5_DRUNK_SUFFIX);
        if string.len(text) >= suffixLen and string.sub(text,-suffixLen) == GHI5_DRUNK_SUFFIX then
            return string.sub(text,1,string.len(text)-suffixLen);
        end
    end
    return text;
end

local function ghi5_get_channel_id()
    local id = 0;
    if type(GetChannelName) == "function" then
        id = GetChannelName(GHI5_CHANNEL_NAME) or 0;
    end
    if type(id) ~= "number" then id = 0; end
    if id < 0 then id = 0; end
    GHI5_CHANNEL_ID = id;
    return id;
end

local function ghi5_send_channel_wire(wire,prio)
    local id = ghi5_get_channel_id();
    if id <= 0 then return false; end

    if ChatThrottleLib and type(ChatThrottleLib.SendChatMessage) == "function" then
        ChatThrottleLib:SendChatMessage(
            prio or "NORMAL",
            GHI5_CHANNEL_NAME,
            wire,
            "CHANNEL",
            nil,
            id
        );
    elseif type(SendChatMessage) == "function" then
        SendChatMessage(wire,"CHANNEL",nil,id);
    else
        return false;
    end

    return true;
end

local function ghi5_queue_channel_wire(wire,prio)
    table.insert(GHI5_outQueue,{wire=wire,prio=prio});
end

local function ghi5_flush_channel_queue()
    if ghi5_get_channel_id() <= 0 then return; end
    if table.getn(GHI5_outQueue) <= 0 then return; end

    local queue = GHI5_outQueue;
    GHI5_outQueue = {};

    local i;
    for i=1,table.getn(queue) do
        local entry = queue[i];
        if entry and not ghi5_send_channel_wire(entry.wire,entry.prio) then
            -- Channel became unavailable while flushing.  Put this and all
            -- remaining packets back in order for the next retry.
            local j;
            for j=i,table.getn(queue) do
                table.insert(GHI5_outQueue,queue[j]);
            end
            return;
        end
    end
end

local function ghi5_ensure_channel()
    if ghi5_get_channel_id() > 0 then
        ghi5_flush_channel_queue();
        return true;
    end

    if type(JoinChannelByName) == "function" then
        -- Deliberately do NOT call ChatFrame_AddChannel().
        -- CHAT_MSG_CHANNEL still fires, but the GHI5 transport does not become
        -- a normal visible chat channel.
        JoinChannelByName(GHI5_CHANNEL_NAME);
    end

    return false;
end

local function ghi5_receive_wire(text,distribution,sender)
    if type(text)~="string" then return; end
    local _,_,id,pi,pt,data=string.find(text,"^([^:]+):(%d+):(%d+):(.*)$");
    if not id then return; end;

    pi=tonumber(pi);
    pt=tonumber(pt);
    if not pi or not pt or pi < 1 or pt < 1 or pi > pt then return; end

    local key=(sender or "?")..":"..id;
    local r=GHI5_recv[key];
    if not r then
        r={n=pt,p={}};
        GHI5_recv[key]=r;
    elseif r.n ~= pt then
        -- Same sender/id with contradictory part count: discard it.
        GHI5_recv[key]=nil;
        return;
    end

    r.p[pi]=data;

    local i;
    for i=1,r.n do
        if not r.p[i] then return; end
    end

    local all=table.concat(r.p);
    GHI5_recv[key]=nil;

    local args=ghi5_des(all,1);
    if type(args)=="table" and GHI.ReceiveMessage then
        local meta = args[2];
        if meta == "BuffSubscribe" then
            ghi5_buff_debug(
                "RX BuffSubscribe <- "..tostring(sender)..
                " subscription="..tostring(args[3])
            );
        elseif meta == "BuffInfo" then
            local targetGuid = nil;
            if type(UnitGUID) == "function" then
                targetGuid = UnitGUID("target");
            end
            ghi5_buff_debug(
                "RX BuffInfo <- "..tostring(sender)..
                " guid="..tostring(args[3])..
                " targetGuid="..tostring(targetGuid)..
                " match="..tostring(targetGuid == args[3])..
                " buffs="..tostring(ghi5_table_len(args[4]))..
                " debuffs="..tostring(ghi5_table_len(args[5]))
            );
        end
        GHI:ReceiveMessage("GHI",sender,distribution,unpack(args));
    end
end

-- Directed GHI transport.  The envelope before hex encoding is:
--     recipientName <0x01> multipartPacket
-- Every GHI5 client receives the channel message, but only the named client
-- decodes and dispatches the packet.
local function ghi5_send_directed_channel(player,text,prio)
    if not player or player=="" then return; end

    local envelope = tostring(player)..string.char(1)..text;
    local wire = GHI5_CHANNEL_MARK..ghi5_hex_encode(envelope);

    if not ghi5_send_channel_wire(wire,prio) then
        ghi5_queue_channel_wire(wire,prio);
        ghi5_ensure_channel();
    end
end

local function ghi5_send(channel,player,args,prio)
    if type(args) == "table" then
        local meta = args[2];
        if meta == "BuffSubscribe" then
            ghi5_buff_debug("TX BuffSubscribe -> "..tostring(player).." subscription="..tostring(args[3]));
        elseif meta == "BuffInfo" then
            ghi5_buff_debug(
                "TX BuffInfo -> "..tostring(player)..
                " guid="..tostring(args[3])..
                " buffs="..tostring(ghi5_table_len(args[4]))..
                " debuffs="..tostring(ghi5_table_len(args[5]))
            );
        end
    end

    local payload=ghi5_ser(args);
    GHI5_seq=GHI5_seq+1;

    local id=tostring(math.floor(GetTime()*10)).."-"..tostring(GHI5_seq);

    -- Directed channel packets are hex encoded.  70 serialized bytes per part
    -- keeps the final ordinary-chat message comfortably below Vanilla's
    -- normal 255-character message limit, including recipient and headers.
    local chunk=(channel=="WHISPER") and 70 or 190;
    local total=math.ceil(string.len(payload)/chunk);
    if total < 1 then total = 1; end

    local i;
    for i=1,total do
        local part=string.sub(payload,(i-1)*chunk+1,i*chunk);
        local packet=id..":"..i..":"..total..":"..part;

        if channel=="WHISPER" then
            ghi5_send_directed_channel(player,packet,prio);
        else
            SendAddonMessage("GHI5",packet,channel);
        end
    end
end

function GHI:SendMessage(channel,player,...)
    ghi5_send(channel,player,arg,"NORMAL");
end

function GHI:SendPrioritizedMessage(prio,channel,player,...)
    ghi5_send(channel,player,arg,prio);
end

function GHI5_OnAddonMessage(prefix,text,distribution,sender)
    if prefix~="GHI5" then return; end
    ghi5_receive_wire(text,distribution,sender);
end

function GHI5_OnChannelMessage(text,sender,channelNumber,channelName)
    local ownChannel = ghi5_get_channel_id();
    local nameMatches = false;
    local numberMatches = false;

    if type(channelName) == "string" then
        nameMatches = string.lower(channelName) == string.lower(GHI5_CHANNEL_NAME);
    end
    if tonumber(channelNumber) and ownChannel > 0 then
        numberMatches = tonumber(channelNumber) == ownChannel;
    end

    if not nameMatches and not numberMatches then return false; end
    if type(text) ~= "string" then return false; end
    if string.sub(text,1,string.len(GHI5_CHANNEL_MARK)) ~= GHI5_CHANNEL_MARK then
        return false;
    end

    local encoded = string.sub(text,string.len(GHI5_CHANNEL_MARK)+1);
    encoded = ghi5_strip_drunk_suffix(encoded);

    local envelope = ghi5_hex_decode(encoded);
    if not envelope then return true; end

    local separator = string.find(envelope,string.char(1),1,true);
    if not separator then return true; end

    local target = string.sub(envelope,1,separator-1);
    local packet = string.sub(envelope,separator+1);
    local ownName = UnitName("player") or GHI.ownName or "";

    if string.lower(target or "") ~= string.lower(ownName) then
        return true;
    end

    ghi5_receive_wire(packet,"WHISPER",sender);
    return true;
end

function GHI_CommunicationHookings()
    if GHI5_eventFrame then return; end

    local f = CreateFrame("Frame","GHI5CommunicationFrame");
    f:RegisterEvent("PLAYER_ENTERING_WORLD");
    f:RegisterEvent("CHAT_MSG_CHANNEL");
    f:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE");
    f:RegisterEvent("CHAT_MSG_ADDON");

    f:SetScript("OnEvent",function()
        if event == "PLAYER_ENTERING_WORLD" then
            GHI5_CHANNEL_ID = 0;
            GHI5_nextJoinAttempt = 0;
            ghi5_ensure_channel();

        elseif event == "CHAT_MSG_CHANNEL_NOTICE" then
            -- Join/leave notifications are asynchronous.  Re-read the channel
            -- list after every notice and flush anything that was waiting.
            if ghi5_get_channel_id() > 0 then
                ghi5_flush_channel_queue();
            else
                GHI5_nextJoinAttempt = 0;
            end

        elseif event == "CHAT_MSG_CHANNEL" then
            GHI5_OnChannelMessage(
                arg1, -- message
                arg2, -- sender
                arg8, -- channel number
                arg9  -- channel name
            );

        elseif event == "CHAT_MSG_ADDON" then
            GHI5_OnAddonMessage(
                arg1, -- prefix
                arg2, -- message
                arg3, -- distribution
                arg4  -- sender
            );
        end
    end);

    -- GHI_OnLoad can run before the character is fully ready to join a
    -- channel.  Retry quietly until the GHI5 channel exists, then this update
    -- handler does almost nothing except an inexpensive id check.
    f:SetScript("OnUpdate",function()
        local now = GetTime();
        if ghi5_get_channel_id() <= 0 then
            if now >= GHI5_nextJoinAttempt then
                GHI5_nextJoinAttempt = now + GHI5_CHANNEL_RETRY;
                ghi5_ensure_channel();
            end
        elseif table.getn(GHI5_outQueue) > 0 then
            ghi5_flush_channel_queue();
        end
    end);

    GHI5_eventFrame = f;
    ghi5_ensure_channel();
end

-- Kept because other GHI code may feed already-reassembled addon packets into
-- this entry point.  It is not a legacy whisper transport.
function GHI:RecieveRawMessage(prefix,text,distribution,sender)
    ghi5_receive_wire(text,distribution,sender);
end

local recieveFunctions = {};
function GHI:RegisterRecieve(tag,func)
	assert(type(tag) == "string" and type(func) == "function","RegisterRecieve usage: tag (string), func (function)");
	assert(not(type(recieveFunctions[tag])=="function"),"Tag "..tag.." already registered.");
	recieveFunctions[tag] = func;
end


GHI_ShowComm = false;
function GHI:ReceiveMessage(prefix, sender, distribution, oldRecieve, meta, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12)
	
	-- filter unknown away
	if distribution == "UNKNOWN" then return end
	
	--[
	if GHI_ShowComm == true then
		if type(meta) == "string" then
			GHI_Message(prefix.." : ".. sender.." : ".. distribution.." :  ".. meta.." : "..type(arg1).." : "..type(arg2))
		else
			GHI_Message(prefix.." : ".. sender.." : ".. distribution.." :  ".. type(meta).." : "..type(arg1).." : "..type(arg2))
		end 
	end
	
	if oldRecieve == true then
		GHI_RecieveData(meta,arg1,sender)
	elseif oldRecieve == false then
		if meta == "BuffInfo" then -- old buff system
			GHI_RecieveBuff(sender,arg1);
		elseif meta == "DebuffInfo" then -- old buff system
			GHI_RecieveDebuff(sender,arg1);
		elseif meta == "ItemVersion" then
			GHI_RecieveItemVersion(arg1,arg2,sender);
		elseif meta == "ItemDataRequest" then
			GHI_RecieveItemDataRequest(arg1,sender);
		elseif meta == "ItemData" then
			GHI_RecieveItemData(arg1,arg2,sender);
		elseif meta == "SuspectedLinkName" then
			GHI_SendLink(arg1,sender);
		elseif meta == "ItemDataVersions" then
			GHI_ItemDataVersions(arg1,arg2,arg3,sender) 
		elseif meta == "ItemRCData" then
			GHI_RecieveItemRCData(arg1,arg2);
		elseif meta == "ExpectRCData" then
			GHI_RecieveExpectRCData(arg1,nil);
		elseif meta == "ExpectRCDataTime" then
			GHI_RecieveExpectRCData(arg1,arg2);
		elseif meta == "EndRCData" then
			GHI_RecieveEndRCData(arg1);
		elseif meta == "TradeDuration" then
			GHI_RecieveTradeDuration(arg1,arg2,arg3,arg4);
		elseif meta == "ApplyBuff" then		
			ApplyGHIBuff(arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11)
		elseif meta == "TradeBagInfo" then	
			GHI_RecieveTradeBagDetails(arg1,arg2);
		end
	
	end
	
	if string.len(meta or "") > 0 and type(recieveFunctions[meta]) == "function" then
		if meta == "BuffSubscribe" or meta == "BuffInfo" then
			ghi5_buff_debug("DISPATCH "..tostring(meta).." callback=function sender="..tostring(sender));
		end
		recieveFunctions[meta](sender,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9);
		if meta == "BuffSubscribe" or meta == "BuffInfo" then
			ghi5_buff_debug("DONE "..tostring(meta));
		end
	elseif meta == "BuffSubscribe" or meta == "BuffInfo" then
		ghi5_buff_debug("NO CALLBACK REGISTERED for "..tostring(meta));
	end
end


--	==================================== Communication	====================================

GHI_In = 0;
GHI_Out = 0;
GHI_InThisSec = 0;
GHI_OutThisSec = 0;
GHI_OutThisSec = 0;

GHI_COMMUNICATION_LIMIT = 20;

GHI_OutBuffer = {};
GHI_OutPointer = 0;

function GHI_SendDataToBuffer(metaData,data,reciever)
	--- should no longer be used
	
	
	--GHR_Message("GHI. In: "..GHI_In.." Out: "..GHI_Out);
	--GHI_Message("=== Sending Data to "..reciever.." ===");
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
	
	
	
	--GHR_Message("Sending to "..new);
	--GHI_Message(metaData);
	--SWM_Message(data);

	
	
	GHI_OutThisSec = GHI_OutThisSec + 1;
	
	if GHI_OutThisSec > GHI_COMMUNICATION_LIMIT or GHI_OutPointer > 0 then    --- 	or  buffer size > 0
		local list = {};
		list.metaData = metaData;
		list.data = data;
		list.reciever = new;
		
		GHI_OutPointer = GHI_OutPointer + 1;
		GHI_OutBuffer[GHI_OutPointer] = list;
	else
		GHI_Out = GHI_Out + 1;
		GHI:SendMessage("WHISPER",new,true,metaData,data);
	end
end

function GHI_SendBufferData()
	if GHI_OutPointer == 0 then return end
	
	-- 	Move data in buffer
	local firstNil = 0;
	if GHI_OutPointer > 500 then
		for i = 1,GHI_OutPointer do
			if GHI_OutBuffer[i] == nil then
				firstNil = i;
				break;
			end
		end
	end
	if not(firstNil == 0) then
		local addr = 0;
		for i = firstNil,GHI_OutPointer do
			addr = addr + 1;
			GHI_OutBuffer[addr] = GHI_OutBuffer[i];
		end
		GHI_OutPointer = addr;
	end
	
	
	local c1 = 0;
	local c2 = 0;
	local c3 = GHI_OutPointer;
	local send = GHI_OutThisSec;
	if GHD_OutThisSec == nil then
		GHD_OutThisSec = 0;
	end
	for i = 1,GHI_OutPointer do
		if send + GHD_OutThisSec > GHI_COMMUNICATION_LIMIT then
			break;
		end
		
		if type(GHI_OutBuffer[i]) == "table" then
			local metaData = GHI_OutBuffer[i].metaData;
			local data = GHI_OutBuffer[i].data;
			local reciever = GHI_OutBuffer[i].reciever;
			if not(metaData == nil) and not(reciever == nil) then
				GHI_Out = GHI_Out + 1;
				GHI:SendMessage("WHISPER",reciever,true,metaData,data);
				send = send + 1;

				
				GHI_OutBuffer[i] = nil;
				
				if c1 == 0 then
					c1 = i;
				end
			end
		end
		if i == GHI_OutPointer then
			GHI_OutPointer = 0;
			break;
		end
		c2 = i;
	end
	
	--GHI_Message("Sending GHI buffer. Address: "..c1.." - "..c2.." Total: "..c2 - c1.." Max: "..c3);
	
end







function GHI_SendData(dataType,data,reciever)

	if reciever == "" or reciever == nil then return end;
	
	local a = strsub(reciever,0,1);
	local b = strsub(reciever,2);
	local new = "";
	
	if a then
		local va = tonumber(strbyte(a));
		if (va >= 65 and va <= 90) or (va >= 97 and va <= 122) then
			new = strupper(a)..strlower(b);
		--elseif (dataType == "AreaSound" or "AreaBuff") then
		--new = reciever;
		--GHI:SendPrioritizedMessage("BULK", "WHISPER", new,true,dataType,data)
		--return
		else
		new = reciever;
		end
	end
	
	if new == nil or new == "" or new == " " then return end;

	GHI:SendMessage("WHISPER",new, true, dataType, data)
	--SendAddonMessage("GHI_"..dataType,data,"WHISPER",new);
end

function GHI_RecieveData(b,data,sender)
	
	data = GHI_ConvertToNum(data);
	
	--GHI_Message("Recieved "..b);
	--print(data)
	if b == "ReqLink" then
		GHI_SendLink(data,sender)
	elseif string.sub(b,0,10) == "ItemReply<" then
		GHI_RecieveLink(string.sub(b,10),data,sender);
	elseif string.sub(b,0,12) == "ItemReplyEnd" then
		GHI_RecieveLinkEnd(data,sender);
	elseif string.sub(b,0,6) == "Trade<" then	
		GHI_RecieveTradeItem(string.sub(b,7),data,sender);
	elseif b == "TradeAccepted" then
		if sender == GHI_TradePlayer then
			GHI_AcceptTrade();
		end
	elseif b == "RequestBuffs" then	-- request from old buff system
		if not(GHI_SubscribedPlayers[sender]) then
			GHI_OldBuffPlayers[sender] = data or 1;
			if GHI_OldBuffPlayers["own time"] and GHI_OldBuffPlayers["own time"] >= (data or 1) then -- only send it if it have not already been send.
				GHI_SendBuffInfo(sender)
			end
		end
		--GHI_SendDebuffInfo(sender)
	elseif string.sub(b,0,5) == "Buff_" then	
		--GHI_RecieveBuff(string.sub(b,6),data,sender);
	elseif b == "RequestDebuffs" then	-- request from old buff system (not used)
		GHI_SendDebuffInfo(sender)
	elseif string.sub(b,0,7) == "Debuff_" then	
		GHI_RecieveDebuff(string.sub(b,8),data,sender);
	elseif string.sub(b,0,15) == "ItemDataVersion" then
		GHI_RecieveItemDataVersion(data,sender);
	elseif b == "AddonVersionReq" then
		local ver = GetAddOnMetadata("GHI", "Version");
		GHI_SendData("AddonVersionAnswer",ver,sender);
		--GHI_SendData("AddonBetaAnswer",GHI_BetaKey,sender);
	elseif b == "AddonVersionAnswer" then
	    --print("hit")
		if sender == GHI_TradePlayer then
			GHI_RecipientHasGHI = true;
			GHI_RecipientGHIVersion = data;
		end
		if sender == GHI_PingedPlayer then
			GHI_RecievePing(sender,data);
		end
		--GHI_Message(sender.." got version "..data);
	elseif b == "AddonBetaAnswer" then
		if sender == GHI_PingedPlayer then
			GHI_Message(data);
			GHI_PingedPlayer = nil;
		end
	elseif b == "AreaSound" then
	 GHI_GetAreaEffectSound(sender,data)
	  ---i am gonna split the sound and debuff into thier own functions.
	  --print("area sound");
	elseif b == "AreaBuff" then
	GHI_GetAreaEffectBuff(sender,data)
	elseif b == "DisableGHI" then
		GHI_MiscData["disabled"] = true;
	elseif b == "EnableGHI" then
		GHI_MiscData["disabled"] = false;
	end
end



--	vvvvvvvvv	Item data transfer

function GHI_SendLink(name,player) 
	--	Should be run backwards?
	local found = false;
	if not(type(GHI_ItemData) == "table") then return; end
	
	--GHI_Message("Request: "..name.." to "..player);
	
	for index1,value1 in pairs(GHI_SendItemsID) do 
		if GHI_IsOfficialItem(value1) then
			value1 = tonumber(value1);
			if type(GHI_OfficialItemData[value1]) == "table" then 
				if GHI_OfficialItemData[value1].name == name then
					local version = GHI_GetVersions(value1);
					GHI:SendPrioritizedMessage("ALERT","WHISPER",player,false,"ItemVersion",value1,0)
					found = true;
					break;
				end
			end
		else
			if type(GHI_ItemData[value1]) == "table" then
				if GHI_ItemData[value1].name == name then
					local version = GHI_GetVersions(value1);
					GHI:SendPrioritizedMessage("ALERT","WHISPER",player,false,"ItemVersion",value1,version)
					found = true;
					break;
				end
			end
		end
	end
	
	if found == false then
		for i = 1,table.getn(GHI_SendNotItems) do
			if GHI_SendNotItems[i] == name then
				GHI:SendPrioritizedMessage("ALERT","WHISPER",player,false,"ItemVersion","0_"..name,0)
				found = true;
				--GHI_Message("Send none link");
				break;
			end
		end
	end
	
end

function GHI_RecieveItemVersion(ID,version,sender)
	if ID and string.sub(ID,0,2) == "0_" then
		--GHI_Message("Recieve none link");
		GHI_RecieveLinkEnd(ID,sender);
	end
	if GHI_IsOfficialItem(ID) then
		GHI_RecieveLinkEnd(ID,sender)
	end
	local ownVersion = GHI_GetVersions(ID);
	--GHI_Message("sender-> "..version.." > "..ownVersion.." <- own")
	if version > ownVersion then --print("send req");
		GHI:SendMessage("WHISPER",sender,false,"ItemDataRequest",ID)
		GHI_RecieveExpectLink(sender);
	else
		GHI_RecieveLinkEnd(ID,sender)
	end

end

function GHI_RecieveItemDataRequest(ID,sender) -- print("recieve req");
	if not(type(GHI_ItemData) == "table") or not(type(GHI_ItemData[ID])=="table") then return end
	
	local data = {};
	for index1,value1 in pairs(GHI_ItemData[ID]) do
		if not(index1 == "rightClick") then
			data[index1] = value1;
		
		end	
	end
	
	
	GHI:SendMessage("WHISPER",sender,false,"ItemData",ID,data)
end

function GHI_RecieveItemData(ID,data,sender) -- print("recieve data");
	local origRC = GHI_GetRightClickInfo(ID);
	
	GHI_ItemData[ID] = data;
	GHI_SetRightClickInfo(ID,origRC);
	GHI_RecieveLinkEnd(ID,sender)
	--GHI_Message("GHI_RecieveItemData version: "..(GHI_ItemData[ID].version or "nil"));
end


function GHI_RecieveLink(prefix,data,sender)  -- no longer in use
	--GHI_Message(prefix.." : "..data);
	
	local arrayName = "GHI_ItemData";
	local array;
	array = getglobal(arrayName);
	if not(type(array) == "table") then  return end;
	
	
	addrPart = prefix;
	
	
	if data == tostring(tonumber(data)) then data = tonumber(data); end
	
	c = string.find(addrPart,"<");
	d = string.find(addrPart,">");
	
	if c and d then
		addr1 = string.sub(addrPart,c+1,d-1);
		
		if addr1 then 
			if addr1 == tostring(tonumber(addr1)) then addr1 = tonumber(addr1); end
			c = string.find(addrPart,"<",d);
			d = string.find(addrPart,">",d+1);
			if c and d then
				addr2 = string.sub(addrPart,c+1,d-1);
				
				if addr2 then 
					if addr2 == tostring(tonumber(addr2)) then addr2 = tonumber(addr2); end
					c = string.find(addrPart,"<",d);
					d = string.find(addrPart,">",d+1);
					if c and d then
						addr3 = string.sub(addrPart,c+1,d-1);
						if addr3 then 
							if addr3 == tostring(tonumber(addr3)) then addr3 = tonumber(addr3); end
							c = string.find(addrPart,"<",d);
							d = string.find(addrPart,">",d+1);
							if c and d then
								addr4 = string.sub(addrPart,c+1,d-1);
								if addr4 then
									if addr4 == tostring(tonumber(addr4)) then addr4 = tonumber(addr4); end
									if not(type(array[addr1]) == "table") then
										array[addr1] = {}
									end
									if not(type(array[addr1][addr2]) == "table") then
										array[addr1][addr2] = {}
									end
									if not(type(array[addr1][addr2][addr3]) == "table") then
										array[addr1][addr2][addr3] = {}
									end
									array[addr1][addr2][addr3][addr4] = data;
									setglobal(arrayName,array);
								end
							else
								if not(type(array[addr1]) == "table") then
									array[addr1] = {}
								end
								if not(type(array[addr1][addr2]) == "table") then
									array[addr1][addr2] = {}
								end
								array[addr1][addr2][addr3] = data;
								setglobal(arrayName,array);
							end
						end
					else
						if not(type(array[addr1]) == "table") then
							array[addr1] = {}
						end
						array[addr1][addr2] = data;
						setglobal(arrayName,array);
						
					end
				end
			else
				array[addr1] = data;
				setglobal(arrayName,array);
			end		
		end
	end	
	
end


GHI_ExpectLink = {};

function GHI_RecieveExpectLink(sender)
	if sender then
		GHI_ExpectLink[sender]=time();
		--GHR_Message("Expect link from "..sender);
	end
end

function GHI_RecieveLinkEnd(data,sender)
	--GHR_Message("Recieve link end "..data.." from "..sender);
	local info;
	if data and string.sub(data,0,2) == "0_" then
		info = {};
		info.notLink = true;
		info.name = string.sub(data,3);
	elseif GHI_IsOfficialItem(data) then
		data = tonumber(data);
		info = GHI_OfficialItemData[data];
		
	else
		info = GHI_ItemData[data];
	end
	if not( type(info) == "table") then return end;
	
	
	
	for index1,value1 in pairs(GHI_IncMsgWaiting) do 
		if type(value1) == "table" then
			
			if value1.sender == sender  then
				local text = value1.text;
				a = 0;
				done = true;
				for i=1,5 do
					--GHI_Message("link "..i.." string is now '"..text.."' Size: "..strlen(text));
					a = GHI_SearchStringForChar(text,91,a+1);
					b = strfind(text,"]",a);
					if a and b then
						
						local linkText,link;
						linkText = strsub(text,a+1,b-1);
						
						--GHI_Message(linkText.." == "..info.name..". a found as: "..a);
						if info.notLink == true and info.name == linkText then
							--GHI_Message("Found as "..a..": "..info.name);
							text = strsub(text,0,a-1).."|nolink["..linkText.."]"..strsub(text,b+1);
							a = a + 16;
						elseif linkText == info.name then
							link = GHI_GenerateLink(data);
							local cc = strlen(text);
							text = strsub(text,0,a-1)..link..strsub(text,b+1);
							--GHR_Message("Expanded with "..strlen(text)-cc);
							--GHR_Message("Insert "..link);
							a = a + 60;
						else
							-- is it an already inserted link?
							
							c = string.sub(text,a-7,a-1);
							
							--GHI_Message("'"..c.."' lenght: "..strlen(c).."   link text: "..linkText);
							if not(c == "0:0:0|h" or c == "|nolink") then   -- not already inserted
								---GHR_Message("not already inserted");
								done = false;
							end
							a = a + 2;
						end
						
						--c,d = strfind(text,linkText);
						
						--GHI_SendDataToBuffer("ReqLink",strsub(text,a+1,b-1),arg2);
						
						--
						
					else 	
						break;
					end
				end
				
				a = 0;
				for i = 1,5 do 
					a = GHI_SearchStringForChar(text,91,a+1);
					b = strfind(text,"]",a);
					if a and b then
						c = string.sub(text,a-7,a-1);
						--GHI_Message(c.." == 0:0:0|h");
						if not(c == "0:0:0|h" or c == "|nolink") then
							done = false;
							--GHI_Message("not done: "..text);
						end
						
					else
						break;
					end
				end
				
				
				
				if done == true then
					--GHI_Message("text: "..text);
					text = gsub(text,"|nolink","");
					local old_arg1 = arg1;  --
					local event = value1.event;
					setglobal("arg1", text);  --GHI_Message("arg1: "..(text or "nil"));
					setglobal("arg2", value1.sender); --GHI_Message("arg2: "..(value1.sender or "nil"));
					setglobal("arg3", value1.arg3); --GHI_Message("arg3: "..(value1.arg3 or "nil"));
					setglobal("arg4", value1.arg4); --GHI_Message("arg4: "..(value1.arg4 or "nil"));
					setglobal("arg5", value1.arg5); --GHI_Message("arg5: "..(value1.arg5 or "nil"));
					setglobal("arg6", value1.arg6); --GHI_Message("arg6: "..(value1.arg6 or "nil"));
					setglobal("arg7", value1.arg7); --GHI_Message("arg7: "..(value1.arg7 or "nil"));
					setglobal("arg8", value1.arg8); --GHI_Message("arg8: "..(value1.arg8 or "nil"));
					setglobal("arg9", value1.arg9); --GHI_Message("arg9: "..(value1.arg9 or "nil"));
					setglobal("arg10", value1.arg10); --GHI_Message("arg10: "..(value1.arg10 or "nil"));
					setglobal("arg11", value1.arg11); 
					setglobal("arg12", value1.arg12); 
					setglobal("arg13", value1.arg13); 
					setglobal("arg14", value1.arg14); 
					setglobal("arg15", value1.arg15); 
					setglobal("arg16", value1.arg16); 
					setglobal("arg17", value1.arg17); 
					setglobal("arg18", value1.arg18); 
					setglobal("arg19", value1.arg19); 
					setglobal("this", value1.this); --GHI_Message("this: "..(value1.this:GetName() or "nil"));
					setglobal("event", value1.event); --GHI_Message("event: "..(value1.event or "nil"));
					GHI_TestTrigger = true;
					----------------  start test
					--[[
					GHI_Message("Recieved link end. Variable list: ");
					for i=1,11 do
						local V = getglobal("arg"..i);
						if type(V) == "string" or type(V) == "number" then
							GHI_Message("arg"..i..": "..type(V).." = "..V);
						else
							GHI_Message("arg"..i..": "..type(V));
						end
					end
					local V = getglobal("this");
					if type(V) == "string" or type(V) == "number" then
						GHI_Message("this: "..type(V).." = "..V);
					else
						GHI_Message("this: "..type(V));
					end
					local V = getglobal("event");
					if type(V) == "string" or type(V) == "number" then
						GHI_Message("event: "..type(V).." = "..V);
					else
						GHI_Message("event: "..type(V));
					end]]
					--------------   end test
					
					
					if GHI_CompAddons["Prat"] == true and not(value1.FCCC == true) then 
						if event == "CHAT_MSG_CHANNEL" then
							for i = 1,7 do
								setglobal("this", getglobal("ChatFrame"..i));
								--Prat:ChatFrame_MessageEventHandler(event)
								if i == 1 then
									Prat:ChatFrame_MessageEventHandler(event);
								else
									GHI_origChatFrame_MessageEventHandler(getglobal("ChatFrame"..i),event,arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15,arg16,arg17,arg18,arg19);
								end
							end	
						else
							-- todo: run for other chat windows
							Prat:ChatFrame_MessageEventHandler(event)
						end
						
					elseif GHI_CompAddons["ForgottenChatCC"] == true and value1.FCCC == true then
						if value1.self == true then
							GHI_OrigFCCC_OutgoingMessage(value1.to, text, value1.lan)
						else
							GHI_OrigFCCC_IncomingMessage(value1.sender, text, value1.afk)
						end
					else
						if event == "CHAT_MSG_CHANNEL" then
							for i = 1,7 do
								setglobal("this", getglobal("ChatFrame"..i));
								GHI_origChatFrame_MessageEventHandler(getglobal("ChatFrame"..i),event,arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,arg15,arg16,arg17,arg18,arg19);
							end		
						else
							-- todo: run for other chat windows
							GHI_origChatFrame_MessageEventHandler(value1.self,event,arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,arg15,arg16,arg17,arg18,arg19);
						end
					end
					
					GHI_IncMsgWaiting[index1] = nil;
					setglobal("arg1", old_arg1);
					GHI_IsForcingEvent = false;
				else
					GHI_IncMsgWaiting[index1].text = text; --GHI_Message("Msg still stored: "..text);
				end			
			end
		end
	end
	
	--	Check if the item is in the trade window
	for i = 1,6 do
		if type(GHI_TradeItemsRecipient[i]) == "table" then
			if GHI_TradeItemsRecipient[i].ID == data then
				GHI_SetRecipientButton(i,GHI_TradeItemsRecipient[i].ID,GHI_TradeItemsRecipient[i].amount)
			end
		end
	end
end


function GHI_ItemDataVersions(ID,v1,v2,sender) --- after trade
	local own_v1,own_v2 = GHI_GetVersions(ID);
	if own_v1 > v1 then
		GHI_RecieveItemDataRequest(ID,sender)
	end
	if own_v2 > v2 then
		if not(type(GHI_ItemData) == "table") or not(type(GHI_ItemData[ID])=="table") then return end
	
		local data = {};
		for index1,value1 in pairs(GHI_ItemData[ID]) do
			if (index1 == "rightClick") then
				data = value1;
			
			end	
		end
		
		-- todo:  Send an alert with expectation of the information
		GHI:SendPrioritizedMessage("ALERT","WHISPER",sender,false,"ExpectRCData",ID)
		
		local size_b = 0;
		for prioname, Prio in pairs(ChatThrottleLib.Prio) do
			if type(Prio.Ring)=="table" and type(Prio.Ring.pos)=="table" then
				for prioname, data in pairs(Prio.Ring.pos) do
					size_b = size_b + (data.nSize or 0);
				end
			end
		end
		
		GHI:SendMessage("WHISPER",sender,false,"ItemRCData",ID,data)
		
		
		local size_a = 0;
		for prioname, Prio in pairs(ChatThrottleLib.Prio) do
			if type(Prio.Ring)=="table" and type(Prio.Ring.pos)=="table" then
				for prioname, data in pairs(Prio.Ring.pos) do
					size_a = size_a + (data.nSize or 0);
				end
			end
		end
		
		
		
		--GHI_Message("before: "..size_b.." after: "..size_a);
		--local a = ChatThrottleLib:UpdateAvail(); 
		-- TODO. calculate queue time with corect bandwith. Calculate sending time.
		local secs = (size_a)/250; -- assumed average
		--GHI_Message("done in "..secs.." secs");
		GHI:SendPrioritizedMessage("ALERT","WHISPER",sender,false,"ExpectRCDataTime",ID,secs)
		
		
		GHI:SendMessage("WHISPER",sender,false,"EndRCData",ID)
	end
	
	
end

GHI_AwaitingRCData = {};
GHI_AwaitingRCDataTime ={};

function GHI_RecieveExpectRCData(ID,Time)
	GHI_AwaitingRCData[ID] = true;
	if Time then
		GHI_AwaitingRCDataTime[ID] = Time+time();
	else
		GHI_AwaitingRCDataTime[ID] = Time;
	end
end

function GHI_RecieveItemRCData(ID,data)
	if not(type(GHI_ItemData) == "table") or not(type(GHI_ItemData[ID])=="table") then return end
	GHI_ItemData[ID].rightClick = data;
	--GHI_Message("GHI_RecieveItemRCData version: "..(GHI_ItemData[ID].version or "nil"));
end

function GHI_RecieveEndRCData(ID)
	GHI_AwaitingRCData[ID] = nil;
	GHI_AwaitingRCDataTime[ID] = nil;
end


--\t^^^^^^^^^^^^
---AREA SOUND/BUFFS
local function round(number, decimals)
    return string.format(string.format("%%.%df",decimals),number)
end

local function XYUpdate()
local x, y =GetPlayerMapPosition("player");
local xa = math.floor(x*1000)/10;
local ya = math.floor(y*1000)/10;
x = round(x*1002,2);
y = round(y*668,2);
WorldMapFrame:Hide();

return x,y;
end

local SOUND_PLAYED = false;

-- Turtle WoW / WoW 1.12 channel compatibility.
-- GHI does not use a private GHI chat channel for area effects.  The original
-- addon uses the player's current zone General channel as a roster source and
-- then whispers addon messages to each member.  WoW 1.12 has GetChannelName,
-- JoinChannelByName and GetChannelRosterInfo, but Turtle does not expose the
-- later GetNumChannelMembers helper used by this WotLK-era source.
local function GHI_AreaZoneName()
    local zone = GetZoneText() or "";
    if zone == "City of Ironforge" then zone = "Ironforge"; end
    return zone;
end

function GHI_GetAreaChannel(tryJoin)
    local zone = GHI_AreaZoneName();
    local channelName = "General - "..zone;
    local id, name = GetChannelName(channelName);

    if (not id or id == 0 or not name) and tryJoin and type(JoinChannelByName) == "function" then
        local frameID = 1;
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.GetID then
            frameID = DEFAULT_CHAT_FRAME:GetID();
        end
        JoinChannelByName(channelName, "", frameID);
        -- Joining can complete asynchronously.  Recheck now; CHAT_MSG_CHANNEL_NOTICE
        -- will call this function again when the server confirms the join.
        id, name = GetChannelName(channelName);
    end

    return id or 0, name, channelName, zone;
end

local function GHI_ForEachAreaChannelMember(id, callback)
    if not id or id <= 0 or type(callback) ~= "function" then return 0; end
    if type(GetChannelRosterInfo) ~= "function" then return 0; end

    local count = 0;
    local i;
    -- Vanilla has no GetNumChannelMembers().  Read the roster until the API
    -- returns no name.  The hard cap is only a safety net against a bad client API.
    for i = 1, 500 do
        local memberName = GetChannelRosterInfo(id, i);
        if not memberName or memberName == "" then break; end
        count = count + 1;
        callback(memberName);
    end
    return count;
end

function GHI_EnsureAreaChannel(verbose)
    local id, name, channelName = GHI_GetAreaChannel(true);
    if id and id > 0 and name then
        if verbose and GHI_Message then
            local memberCount = GHI_ForEachAreaChannelMember(id, function() end);
            GHI_Message("GHI channel: joined "..name.." (#"..id.."); roster entries visible: "..memberCount..".");
        end
        return true;
    end
    if verbose and GHI_Message then
        GHI_Message("GHI channel: not yet joined to "..channelName.."; join requested.");
    end
    return false;
end

function GHI_SendAreaEffect(typed,...)
    local x,y = XYUpdate();
    local id, name, channelName, comzone = GHI_GetAreaChannel(true);

    if not id or id <= 0 or not name then
        if typed == "sound" then
            local soundPath = unpack(arg);
            if soundPath ~= "dummy" and GHI_Message then
                GHI_Message("Could not join/find "..channelName..", which is required to send GHI area sound.");
            end
        elseif GHI_Message then
            GHI_Message("Could not join/find "..channelName..", which is required to cast GHI area buff.");
        end
        return;
    end

    if typed == "sound" then
        local soundPath,range = unpack(arg);
        -- "dummy" was used by the original addon only to warm the newer channel
        -- roster API.  It must not broadcast anything on Turtle/1.12.
        if soundPath == "dummy" then return; end

        local data = comzone..":"..x..":"..y..":"..soundPath..":"..range;
        GHI_ForEachAreaChannelMember(id, function(MemberName)
            if MemberName and MemberName ~= UnitName("player") then
                GHI_SendData("AreaSound",data,MemberName);
            end
        end);

    elseif typed == "buff" then
        local click = unpack(arg);
        if type(click) ~= "table" then return; end
        click.zone = comzone;
        click.x = x;
        click.y = y;
        -- click.range is already part of the item action data.

        GHI_ForEachAreaChannelMember(id, function(MemberName)
            if MemberName and MemberName ~= UnitName("player") then
                GHI_SendData("AreaBuff",click,MemberName);
            end
        end);
    end
end


function GHI_GetAreaEffectSound(sender,data)--... is other data.
	if GHI_MiscData["block_area_sound"] then return end
	local zone = GetSubZoneText();
	local X,Y = XYUpdate();

	local comzone = GetZoneText()
	if comzone == "City of Ironforge" then comzone = "Ironforge"; end

	local zonesender,sx,sy,soundPath,range = strsplit(":",data);
	--print(zone)
	--range = range or 60;
	--print(zonesender)
	--NOTE:range now accepts numbers or "Zone" to broadcast to entire zone, maybe world with GHD?
	if range~="Zone" then
		--print(comzone,zonesender);
		if comzone == zonesender then
			--print(soundPath)
			--print(math.abs(math.sqrt((sx-X)*(sx-X) + (sy-Y)*(sy-Y))))
			if ( math.abs(math.sqrt((sx-X)*(sx-X) + (sy-Y)*(sy-Y))) <= tonumber(range))and SOUND_PLAYED == false then
				soundPath = gsub(soundPath,"\\\\","/");
				soundPath = gsub(soundPath,"\\","/");
				PlaySoundFile(soundPath);
			end
		end
	  
	else 
		soundPath = gsub(path,"\\\\","/");
		soundPath = gsub(path,"\\","/");
		PlaySoundFile(soundPath);
	end

end

function GHI_GetAreaEffectBuff(sender,data)
	
	if GHI_MiscData["block_area_buff"] then return end
--local filter,refID,guid,name,description,icon,totalDuration,endTime,count,debuffType,range = strsplit(":",data);
	
	
	local zonesender,sx,sy,range = data.zone,data.x,data.y,data.range;
	local zone = GetSubZoneText();
	local X,Y = XYUpdate();
	local range = range or 60;
	local cast;
	
	local comzone = GetZoneText()
	if comzone == "City of Ironforge" then comzone = "Ironforge"; end
	
	if range~= "Zone" then


		if comzone == zonesender then

			--local name,text,texture,untilCancelled,filter,debuffType,duration,cancelable,stackable,range = strsplit(":",data);



			if (math.abs(math.sqrt((sx-X)*(sx-X) + (sy-Y)*(sy-Y)))<= tonumber(range)) then
				cast = true;
				--local b = GHU_New("buff") -- It should be called with GHI_ApplyBuff
				--b:CastBuff(filter,refID,guid,name,description,icon,totalDuration,endTime,count,debuffType)
			end
		end
	else
		--zone broadcast
		cast = true;
		--b:CastBuff(filter,refID,guid,name,description,icon,totalDuration,endTime,count,debuffType)
	end
	if cast then
		-- cast the buff
		ApplyGHIBuff(data.buffName,data.buffDetails,data.buffIcon,data.untillCanceled,data.filter,data.buffType,data.buffDuration,data.cancelable,data.stackable,data.count or 1,data.delay or 0)
	end
end

--[[

if (math.abs(math.sqrt((sx-X)*(sx-X) + (sy-Y)*(sy-Y)))<= tonumber(range)) and SOUND_PLAYED == false then
UpdateLastPlayed()--just gonna do this for buff delay too
--local b = GHU_New("buff") -- It should be called with GHI_ApplyBuff
--b:CastBuff(filter,refID,guid,name,description,icon,totalDuration,endTime,count,debuffType)
   end
   end
 else
 --zone broadcast
  UpdateLastPlayed()
local b = GHU_New("buff")
--b:CastBuff(filter,refID,guid,name,description,icon,totalDuration,endTime,count,debuffType)
 end
end   --]]


function GHI_SendAddonMessage(prefix, text, Type, target)
	GHI_MessageErrorsExpected_A[target] = 1;
	GHI_OrigSendAddonMessage(prefix, text, Type, target)
end



GHI_TimeOutLimit = 10;
function GHI_CheckTimeoutedMsg()
		
	
	for index1,value1 in pairs(GHI_IncMsgWaiting) do 
		if type(value1) == "table" then
			local sender = value1.sender;
			local delay = 0;
			if type(GHI_ExpectLink[sender]) == "number" then
				
				delay = GHI_TimeOutLimit*4
				
			end
		
			if value1.time < time() - (GHI_TimeOutLimit + delay) then
				
				
				--GHR_Message(value1.text.." from "..value1.sender.." timed out after ".. (GHI_TimeOutLimit + delay).." secs");
				local text = gsub(value1.text,"|nolink","");
				
				local event = value1.event;
				-- this should be done dynamically when making GHU_Links
				setglobal("arg1", text);
				setglobal("arg2", value1.sender);
				setglobal("arg3", value1.arg3);
				setglobal("arg4", value1.arg4);
				setglobal("arg5", value1.arg5);
				setglobal("arg6", value1.arg6);
				setglobal("arg7", value1.arg7);
				setglobal("arg8", value1.arg8);
				setglobal("arg9", value1.arg9);
				setglobal("arg10", value1.arg10);
				setglobal("arg11", value1.arg11);
				setglobal("arg12", value1.arg12);
				setglobal("arg13", value1.arg13);
				setglobal("arg14", value1.arg14);
				setglobal("arg15", value1.arg15);
				setglobal("arg16", value1.arg16);
				setglobal("arg17", value1.arg17);
				setglobal("arg18", value1.arg18);
				setglobal("arg19", value1.arg19);
				setglobal("this", value1.this);
				setglobal("self", value1.self);
				
				
				if GHI_CompAddons["Prat"] == true and value1.FCCC == false then 
					
					if event == "CHAT_MSG_CHANNEL" then
						for i = 1,7 do
							setglobal("this", getglobal("ChatFrame"..i));
							Prat:ChatFrame_MessageEventHandler(event)
						end		
					else
						-- todo: run for other chat windows
						Prat:ChatFrame_MessageEventHandler(event)
					end
				elseif GHI_CompAddons["ForgottenChatCC"] == true and value1.FCCC == true then
					if value1.self == true then
						GHI_OrigFCCC_OutgoingMessage(value1.to, value1.text, value1.lan)
					else
						GHI_OrigFCCC_IncomingMessage(value1.sender, value1.text, value1.afk)
					end
				else
					if event == "CHAT_MSG_CHANNEL" then
						for i = 1,7 do
							setglobal("this", getglobal("ChatFrame"..i));
							--GHI_origChatFrame_MessageEventHandler(value1.self,event);
							GHI_origChatFrame_MessageEventHandler(getglobal("ChatFrame"..i),event,arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,arg15, arg16, arg17, arg18, arg19);
						end		
					else
						-- todo: run for other chat windows
						GHI_origChatFrame_MessageEventHandler(value1.self,event,arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,arg15, arg16, arg17, arg18, arg19);
					end
				end
				GHI_IncMsgWaiting[index1] = nil;
						
			end
		end
	end
	
	
	
end

--	======================== Sending item data
--	sending link = no right click info
--	Sending item data = inc right click info

function GHI_SendItemData(ID,player)
	if not(type(GHI_ItemData) == "table") then return; end
	
	--GHI_Message("Sending all data for "..ID.." to "..player);
	
	
	if type(GHI_ItemData[ID]) == "table" then
		
	local index1 = ID;
	
		for index2,value2 in pairs(GHI_ItemData[ID]) do 
			if type(value2) == "table" then
				for index3,value3 in pairs(value2) do 
					if type(value3) == "table" then
						for index4,value4 in pairs(value3) do 
							if type(value4) == "table" then
								-- More than 4 arrays
							else
								GHI_SendDataToBuffer("ItemReply<"..index1.."><"..index2.."><"..index3.."><"..index4..">",value4,player);
							end
						end
					else
						GHI_SendDataToBuffer("ItemReply<"..index1.."><"..index2.."><"..index3..">",value3,player);
					end
				end
			else 
				GHI_SendDataToBuffer("ItemReply<"..index1.."><"..index2..">",value2,player);
			end
		end
		
		GHI_SendDataToBuffer("ItemReplyEnd",index1,player);				
		
		
	else
		
	end
	
end

function GHI_RecieveItemDataVersion(data,sender)  -- GHR_Message("As: Recieved data version");
	local ID,version = strsplit(":",data);
	if not(ID) or not(version) then return end
	if not(type(GHI_ItemData[ID]) == "table") then return end
	
	local ownVersion = GHI_ItemData[ID].version;
	if not(ownVersion) then
		ownVersion = 0;
	end
	version = tonumber(version);
	ownVersion = tonumber(ownVersion);
	if not(version) or not(ownVersion) then
		return;
	end
	
	if ownVersion > version then
		GHI_SendItemData(ID,sender)  --GHR_Message("A1: Sending data.");
	end
	--GHI_Message(ownVersion.." == "..version);
	--GHR_Message("Ae: End recieved data version");
end


function GHI_SendPing(player)
	GHI_SendData("AddonVersionReq",nil,player);
	GHI_PingedPlayer = player;
end

function GHI_RecievePing(player,data)
	
	GHI_Message("Ping reply from "..player);
	GHI_Message("Version "..data);
	GHI_PingedPlayer = nil;
end



--	======================== Bandwith analyzing ========================
function GHI_MainMenuBarPerformanceBarFrame_OnEnter(f)
	orig_MainMenuBarPerformanceBarFrame_OnEnter(f);
	
	local Max = ChatThrottleLib.BURST
	local avail = ChatThrottleLib:UpdateAvail();
	if ChatThrottleLib.bChoking == true then
		Max = ChatThrottleLib.MAX_CPS;
	end
	
	local qSize = 0;
	for _,Prio in pairs(ChatThrottleLib.Prio) do
		for _,pipe in pairs(Prio.ByName) do
			qSize = qSize + table.getn(pipe);
		end
	end
	
	GameTooltip:AddLine("\nBandwidth Used");
	GameTooltip:AddLine(format("%.0f / %.0f b/sec (%.0f%%).",
		Max-avail,
		Max,
		((Max-avail)/Max)*100
	), 1.0, 1.0, 1.0);
	GameTooltip:AddLine(format("%.0f messages in queue.",
		qSize
	), 1.0, 1.0, 1.0);
	if ChatThrottleLib.bChoking then
		GameTooltip:AddLine("Bandwidth lowered due to zoning or low framerate.");
	end
	GameTooltip:Show();
end

PERFORMANCEBAR_UPDATE_INTERVAL = 1;
