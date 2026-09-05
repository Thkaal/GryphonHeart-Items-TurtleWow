GHU_Mail = {}
GHU_Mail.__index = GHU_Mail;
GHU_Mail.hooked = {};
GHU_Mail.cache = {};
GHU_Mail.pendingAttachment = nil;
GHU_Mail.pendingReceives = {};
GHU_Mail.sending = nil;

local GHU_MAIL_SUBJECT_PREFIX = "GHI#";

-- GHIM1 = original/raw transport
-- GHIM2 = | / ~ escaped transport
-- GHIM3 = hexadecimal transport
-- GHIM4 = optional compression + mail-safe Base64
local GHU_MAIL_BODY_PREFIX_V1 = "GHIM1#";
local GHU_MAIL_BODY_PREFIX_V2 = "GHIM2#";
local GHU_MAIL_BODY_PREFIX_V3 = "GHIM3#";
local GHU_MAIL_BODY_PREFIX_V4 = "GHIM4#";

-- All newly-sent mail uses GHIM4.
local GHU_MAIL_BODY_PREFIX = GHU_MAIL_BODY_PREFIX_V4;

local GHU_MAIL_CHUNK_SIZE = 460;

-- Legacy GHIM2 decoder. New outgoing mail uses GHIM3.
local function GHU_MailDecode(text)
	if type(text) ~= "string" then return ""; end
	text = string.gsub(text,"~1","|");
	text = string.gsub(text,"~0","~");
	return text;
end

local function GHU_MailMessage(msg)
	if type(GHI_Message) == "function" then
		GHI_Message(msg);
	elseif DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(msg);
	end
end

local function GHU_MailHexEncode(text)
	if type(text) ~= "string" then return ""; end

	local out = {};
	local i;

	for i = 1,string.len(text) do
		out[i] = string.format("%02X",string.byte(text,i));
	end

	return table.concat(out,"");
end


local function GHU_MailHexDecode(text)
	if type(text) ~= "string" then return nil; end

	-- Hex must always contain two characters per original byte.
	if math.mod(string.len(text),2) ~= 0 then
		return nil;
	end

	local out = {};
	local n = 0;
	local i;

	for i = 1,string.len(text),2 do
		local byte = tonumber(string.sub(text,i,i+1),16);

		if not byte then
			return nil;
		end

		n = n + 1;
		out[n] = string.char(byte);
	end

	return table.concat(out,"");
end

-- ============================================================================
-- GHIM4 MAIL-SAFE BASE64
--
-- Uses URL-safe characters only:
-- A-Z a-z 0-9 - _
--
-- Padding "=" is intentionally omitted.
-- Compatible with Lua 5.0.2; no bitwise operators are required.
-- ============================================================================

local GHU_BASE64_ALPHABET =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

local GHU_BASE64_DECODE = {};

do
	local i;
	for i=1,string.len(GHU_BASE64_ALPHABET) do
		GHU_BASE64_DECODE[string.sub(GHU_BASE64_ALPHABET,i,i)] = i - 1;
	end
end


local function GHU_Base64Encode(text)
	if type(text) ~= "string" then return ""; end

	local out = {};
	local outCount = 0;
	local textLen = string.len(text);
	local i = 1;

	while i <= textLen do
		local remaining = textLen - i + 1;

		local b1 = string.byte(text,i) or 0;
		local b2 = 0;
		local b3 = 0;

		if remaining >= 2 then
			b2 = string.byte(text,i+1) or 0;
		end

		if remaining >= 3 then
			b3 = string.byte(text,i+2) or 0;
		end

		local c1 = math.floor(b1 / 4);
		local c2 = math.mod(b1,4) * 16 + math.floor(b2 / 16);
		local c3 = math.mod(b2,16) * 4 + math.floor(b3 / 64);
		local c4 = math.mod(b3,64);

		outCount = outCount + 1;
		out[outCount] = string.sub(
			GHU_BASE64_ALPHABET,
			c1 + 1,
			c1 + 1
		);

		outCount = outCount + 1;
		out[outCount] = string.sub(
			GHU_BASE64_ALPHABET,
			c2 + 1,
			c2 + 1
		);

		if remaining >= 2 then
			outCount = outCount + 1;
			out[outCount] = string.sub(
				GHU_BASE64_ALPHABET,
				c3 + 1,
				c3 + 1
			);
		end

		if remaining >= 3 then
			outCount = outCount + 1;
			out[outCount] = string.sub(
				GHU_BASE64_ALPHABET,
				c4 + 1,
				c4 + 1
			);
		end

		i = i + 3;
	end

	return table.concat(out,"");
end


local function GHU_Base64Decode(text)
	if type(text) ~= "string" then return nil; end

	local textLen = string.len(text);

	-- An unpadded Base64 string can never have length mod 4 == 1.
	if math.mod(textLen,4) == 1 then
		return nil;
	end

	local out = {};
	local outCount = 0;
	local i = 1;

	while i <= textLen do
		local remaining = textLen - i + 1;

		if remaining < 2 then
			return nil;
		end

		local a = GHU_BASE64_DECODE[string.sub(text,i,i)];
		local b = GHU_BASE64_DECODE[string.sub(text,i+1,i+1)];

		if a == nil or b == nil then
			return nil;
		end

		local c = nil;
		local d = nil;

		if remaining >= 3 then
			c = GHU_BASE64_DECODE[string.sub(text,i+2,i+2)];
			if c == nil then return nil; end
		end

		if remaining >= 4 then
			d = GHU_BASE64_DECODE[string.sub(text,i+3,i+3)];
			if d == nil then return nil; end
		end

		local b1 = a * 4 + math.floor(b / 16);

		outCount = outCount + 1;
		out[outCount] = string.char(b1);

		if c ~= nil then
			local b2 =
				math.mod(b,16) * 16 +
				math.floor(c / 4);

			outCount = outCount + 1;
			out[outCount] = string.char(b2);
		end

		if d ~= nil then
			local b3 =
				math.mod(c,4) * 64 +
				d;

			outCount = outCount + 1;
			out[outCount] = string.char(b3);
		end

		i = i + 4;
	end

	return table.concat(out,"");
end

-- ============================================================================
-- GHIM4 SIMPLE LZ COMPRESSION
--
-- Token 0:
--   00 <length> <literal bytes...>
--
-- Token 1:
--   01 <distance high> <distance low> <length>
--
-- Minimum match length: 4 bytes
-- Maximum match length: 255 bytes
-- Maximum distance:     65535 bytes
--
-- The compressed result may contain arbitrary binary bytes. That is safe
-- because GHIM4 Base64-encodes it before SendMail().
-- ============================================================================

local GHU_LZ_MIN_MATCH = 4;
local GHU_LZ_MAX_MATCH = 255;
local GHU_LZ_MAX_DISTANCE = 65535;


local function GHU_LZAddDictionaryKey(dict,text,pos,textLen)
	if pos + 2 <= textLen then
		local key = string.sub(text,pos,pos+2);
		dict[key] = pos;
	end
end


local function GHU_LZFindMatch(text,pos,textLen,dict)
	if pos + 2 > textLen then
		return nil,0;
	end

	local key = string.sub(text,pos,pos+2);
	local previous = dict[key];

	if not previous then
		return nil,0;
	end

	local distance = pos - previous;

	if distance < 1 or distance > GHU_LZ_MAX_DISTANCE then
		return nil,0;
	end

	local maxLen = textLen - pos + 1;

	if maxLen > GHU_LZ_MAX_MATCH then
		maxLen = GHU_LZ_MAX_MATCH;
	end

	local matchLen = 0;

	while matchLen < maxLen do
		local a = string.byte(text,previous + matchLen);
		local b = string.byte(text,pos + matchLen);

		if a ~= b then
			break;
		end

		matchLen = matchLen + 1;
	end

	if matchLen < GHU_LZ_MIN_MATCH then
		return nil,0;
	end

	return distance,matchLen;
end


local function GHU_Compress(text)
	if type(text) ~= "string" then return nil; end

	local textLen = string.len(text);

	if textLen == 0 then
		return "";
	end

	local dict = {};

	local out = {};
	local outCount = 0;

	local literals = {};
	local literalCount = 0;


	local function FlushLiterals()
		if literalCount <= 0 then return; end

		outCount = outCount + 1;
		out[outCount] = string.char(0);

		outCount = outCount + 1;
		out[outCount] = string.char(literalCount);

		outCount = outCount + 1;
		out[outCount] = table.concat(literals,"");

		literals = {};
		literalCount = 0;
	end


	local i = 1;

	while i <= textLen do
		local distance,matchLen =
			GHU_LZFindMatch(text,i,textLen,dict);

		if distance and matchLen >= GHU_LZ_MIN_MATCH then

			FlushLiterals();

			local distanceHigh = math.floor(distance / 256);
			local distanceLow = math.mod(distance,256);

			outCount = outCount + 1;
			out[outCount] = string.char(1);

			outCount = outCount + 1;
			out[outCount] = string.char(distanceHigh);

			outCount = outCount + 1;
			out[outCount] = string.char(distanceLow);

			outCount = outCount + 1;
			out[outCount] = string.char(matchLen);


			-- Make consumed positions available for later matches.
			local j;

			for j=0,matchLen-1 do
				GHU_LZAddDictionaryKey(
					dict,
					text,
					i+j,
					textLen
				);
			end

			i = i + matchLen;

		else
			literalCount = literalCount + 1;
			literals[literalCount] = string.sub(text,i,i);

			GHU_LZAddDictionaryKey(
				dict,
				text,
				i,
				textLen
			);

			i = i + 1;

			if literalCount >= 255 then
				FlushLiterals();
			end
		end
	end

	FlushLiterals();

	return table.concat(out,"");
end


local function GHU_Decompress(text)
	if type(text) ~= "string" then return nil; end

	local textLen = string.len(text);

	if textLen == 0 then
		return "";
	end

	-- Individual bytes are stored separately because LZ back-references
	-- may overlap data currently being generated.
	local out = {};
	local outLen = 0;

	local i = 1;

	while i <= textLen do
		local token = string.byte(text,i);

		if token == 0 then

			local runLen = string.byte(text,i+1);

			if not runLen or runLen < 1 then
				return nil;
			end

			if i + 1 + runLen > textLen then
				return nil;
			end

			local j;

			for j=0,runLen-1 do
				outLen = outLen + 1;
				out[outLen] = string.sub(
					text,
					i+2+j,
					i+2+j
				);
			end

			i = i + 2 + runLen;


		elseif token == 1 then

			local distanceHigh = string.byte(text,i+1);
			local distanceLow = string.byte(text,i+2);
			local matchLen = string.byte(text,i+3);

			if not distanceHigh
				or not distanceLow
				or not matchLen then

				return nil;
			end

			local distance =
				distanceHigh * 256 +
				distanceLow;

			if distance < 1
				or distance > outLen
				or matchLen < GHU_LZ_MIN_MATCH then

				return nil;
			end

			local sourceStart =
				outLen - distance + 1;

			local j;

			for j=0,matchLen-1 do
				local ch = out[sourceStart+j];

				if not ch then
					return nil;
				end

				outLen = outLen + 1;
				out[outLen] = ch;
			end

			i = i + 4;


		else
			-- Unknown token means damaged compressed data.
			return nil;
		end
	end

	return table.concat(out,"");
end

local function GHU_ParseMailSubject(subject)
	if type(subject) ~= "string" then return nil; end
	if string.sub(subject,1,string.len(GHU_MAIL_SUBJECT_PREFIX)) ~= GHU_MAIL_SUBJECT_PREFIX then return nil; end
	local _,_,mailID,part,total,displaySubject = string.find(subject,"^GHI#([^#]+)#(%d+)#(%d+)#(.*)$");
	part = tonumber(part);
	total = tonumber(total);
	if not mailID or not part or not total then return nil; end
	return { id=mailID, part=part, total=total, subject=displaySubject or "" };
end

local function GHU_MailKey(sender,mailID)
	return (sender or "")..":"..(mailID or "");
end

local function GHU_EnsureMailSavedData()
	GHU_MiscData = GHU_MiscData or {};
	GHU_MiscData.GHIMailClaimed = GHU_MiscData.GHIMailClaimed or {};
end

-- standard
function GHU_Mail:Create(varName,name)
	setglobal(varName,GHU_Mail);
	local obj = {};
	setmetatable(obj,getglobal(varName));
	obj.headerName = name;
	obj.SelectedSkill = 0;
	setglobal(varName,obj);
	obj:InitHooks(varName);
end

function GHU_Mail:Hook(funcName,varName)
	if not(type(self.orig)=="table") then self.orig = {}; end
	if not(type(self.installedHooks)=="table") then self.installedHooks = {}; end
	if self.installedHooks[funcName] then return true; end
	assert(type(self[funcName])=="function","No function found for "..funcName);
	local original = getglobal(funcName);
	if type(original) ~= "function" then return false; end
	self.orig[funcName] = original;
	local hookObject = getglobal(varName);
	hookObject.hooked[funcName] = function(...)
		gself = getglobal(varName);
		local hookTarget = getglobal(varName);
		return hookTarget[funcName](hookTarget,unpack(arg));
	end
	setglobal(funcName,getglobal(varName)["hooked"][funcName]);
	self.installedHooks[funcName] = true;
	return true;
end

-- The Vanilla mail frame may not exist yet when GHU itself loads.  Inbox API
-- hooks are available immediately, but the Send Mail frame functions/buttons
-- can appear later.  Keep the object name and retry those hooks whenever the
-- mailbox UI is shown.
function GHU_Mail:GetMaxSendAttachments()
	local n = tonumber(ATTACHMENTS_MAX) or tonumber(ATTACHMENTS_MAX_SEND) or 16;
	if n < 1 then n = 16; end
	return n;
end

function GHU_Mail:GetSendAttachmentButton(index)
	if not index then return nil; end
	-- TurtleMail replaces the disabled Vanilla package button with its own
	-- MailAttachment1..N buttons. Prefer those when present.
	local button = getglobal("MailAttachment"..index);
	if button then return button; end
	return getglobal("SendMailAttachment"..index);
end

function GHU_Mail:GetAttachmentButtonIndex(button)
	if not button then return nil; end
	if type(button.GetID)=="function" then
		local id = tonumber(button:GetID());
		if id and id > 0 then return id; end
	end
	if type(button.GetName)=="function" then
		local name = button:GetName();
		if type(name)=="string" then
			local _,_,id = string.find(name,"MailAttachment(%d+)$");
			if id then return tonumber(id); end
		end
	end
	return nil;
end

function GHU_Mail:InstallAttachmentButtonHooks()
	local i;
	for i=1,self:GetMaxSendAttachments() do
		local button = self:GetSendAttachmentButton(i);
		if button then
			-- GHI items live on a virtual cursor rather than Blizzard's real item cursor.
			-- Attach them explicitly when the player presses the mouse button on the
			-- visible mail attachment slot.
			local mouseDown = button:GetScript("OnMouseDown");
			if not button.GHUMailMouseDownWrapper or mouseDown ~= button.GHUMailMouseDownWrapper then
				button.GHUMailOldOnMouseDown = mouseDown;
				button.GHUMailMouseDownWrapper = function()
					local obj = GHU_Mail.activeObject;
					local slot = obj and obj:GetAttachmentButtonIndex(this) or nil;
					if obj and slot and type(GHI_GetCursor)=="function" then
						local cursorType,details = GHI_GetCursor();
						if cursorType == "item" then
							if obj:AttachGHIItem(details,slot) then
								-- OnClick fires after OnMouseDown/OnMouseUp.  Consume that one
								-- click so attaching does not immediately trigger our remove path.
								this.GHUMailSuppressNextClick = true;
								return;
							end
						end
					end
					if this and this.GHUMailOldOnMouseDown then return this.GHUMailOldOnMouseDown(); end
				end;
				button:SetScript("OnMouseDown",button.GHUMailMouseDownWrapper);
			end

			local current = button:GetScript("OnClick");
			if not button.GHUMailClickWrapper or current ~= button.GHUMailClickWrapper then
				button.GHUMailOldOnClick = current;
				button.GHUMailClickWrapper = function()
					if this and this.GHUMailSuppressNextClick then
						this.GHUMailSuppressNextClick = nil;
						return;
					end
					local obj = GHU_Mail.activeObject;
					local slot = obj and obj:GetAttachmentButtonIndex(this) or nil;
					if obj and obj.pendingAttachment and slot == obj.pendingAttachment.mailSlot then
						obj:ClearPendingAttachment(true);
						GHU_MailMessage("GHI mail attachment removed.");
						return;
					end
					if this and this.GHUMailOldOnClick then return this.GHUMailOldOnClick(); end
				end;
				button:SetScript("OnClick",button.GHUMailClickWrapper);
			end
		end
	end
end

function GHU_Mail:InstallMailButtonHook()
	local current = getglobal("SendMailMailButton_OnClick");
	if type(current) ~= "function" then return; end
	if self.mailButtonWrapper and current == self.mailButtonWrapper then return; end
	self.mailButtonOriginal = current;
	local old = current;
	self.mailButtonWrapper = function()
		local obj = GHU_Mail.activeObject;
		if obj and obj.pendingAttachment then
			obj:BeginGHIItemSend();
			return;
		end
		return old();
	end;
	setglobal("SendMailMailButton_OnClick",self.mailButtonWrapper);
end

function GHU_Mail:InstallSendHooks(varName)
	varName = varName or self.varName;
	if not varName then return; end
	self:Hook("SendMailFrame_SendMail",varName);
	self:Hook("SendMailFrame_Update",varName);
	self:InstallAttachmentButtonHooks();
	self:InstallMailButtonHook();
end

-- Return true when the current physical cursor is inside a frame.  Vanilla has
-- no reliable GHI-aware OnReceiveDrag here because GHI deliberately clears the
-- native cursor before showing its own virtual item cursor.
local function GHU_MailCursorIsOver(frame)
    if not frame or not frame:IsVisible() then return false; end
    local left,right,top,bottom = frame:GetLeft(),frame:GetRight(),frame:GetTop(),frame:GetBottom();
    if not left or not right or not top or not bottom then return false; end
    local x,y = GetCursorPosition();
    local scale = 1;
    if UIParent and type(UIParent.GetEffectiveScale)=="function" then
        scale = UIParent:GetEffectiveScale() or 1;
    end
    if scale == 0 then scale = 1; end
    x = x / scale;
    y = y / scale;
    return x >= left and x <= right and y >= bottom and y <= top;
end

local function GHU_MailFocusIsWithin(frame,target)
    local f = frame;
    local guard = 0;
    while f and guard < 12 do
        if f == target then return true; end
        if type(f.GetParent) ~= "function" then break; end
        f = f:GetParent();
        guard = guard + 1;
    end
    return false;
end

function GHU_Mail:FindSendAttachmentUnderCursor()
	local focus = nil;
	if type(GetMouseFocus)=="function" then focus = GetMouseFocus(); end
	local i;
	for i=1,self:GetMaxSendAttachments() do
		local button = self:GetSendAttachmentButton(i);
		if button and button:IsVisible() then
			if focus and GHU_MailFocusIsWithin(focus,button) then return i,button; end
			if GHU_MailCursorIsOver(button) then return i,button; end
		end
	end
	return nil,nil;
end

function GHU_Mail:TryExternalCursorDrop(cursorType,details)
	if cursorType ~= "item" then return false; end
	if not SendMailFrame or not SendMailFrame:IsVisible() then return false; end
	local slot = self:FindSendAttachmentUnderCursor();
	if not slot then return false; end
	return self:AttachGHIItem(details,slot) == true;
end

function GHU_Mail:RegisterExternalDropHandler()
    if self.externalDropRegistered then return; end
    if type(GHI_RegisterExternalCursorDropHandler) ~= "function" then return; end
    GHI_RegisterExternalCursorDropHandler("GHU_Mail",function(cursorType,details)
        local obj = GHU_Mail.activeObject;
        if not obj then return false; end
        return obj:TryExternalCursorDrop(cursorType,details);
    end);
    self.externalDropRegistered = true;
end

function GHU_Mail:UpdateDropTarget()
	self:RegisterExternalDropHandler();
end

function GHU_Mail:InitHooks(varName)
	self.varName = varName;
	self:Hook("GetInboxItem",varName);
	self:Hook("GetInboxHeaderInfo",varName);
	self:Hook("GetInboxNumItems",varName);
	self:Hook("GetLatestThreeSenders",varName);
	self:Hook("GetInboxText",varName);
	self:Hook("TakeInboxItem",varName);
	self:InstallSendHooks(varName);
	self:RegisterExternalDropHandler();
end

function GHU_Mail:GetRealHeader(index)
	if not self.orig or type(self.orig.GetInboxHeaderInfo) ~= "function" then return nil; end
	return self.orig.GetInboxHeaderInfo(index);
end

function GHU_Mail:GetTransferMeta(index)
	local _,_,sender,subject = self:GetRealHeader(index);
	local meta = GHU_ParseMailSubject(subject);
	if meta then meta.sender = sender; end
	return meta;
end

function GHU_Mail:IsClaimed(sender,mailID)
	GHU_EnsureMailSavedData();
	return GHU_MiscData.GHIMailClaimed[GHU_MailKey(sender,mailID)] == true;
end

function GHU_Mail:SetClaimed(sender,mailID)
	GHU_EnsureMailSavedData();
	GHU_MiscData.GHIMailClaimed[GHU_MailKey(sender,mailID)] = true;
end

-- Assemble all server-mail chunks belonging to one GHI attachment. Calling
-- the original GetInboxText for a chunk also asks the server for that mail's
-- body if it is not cached yet; MAIL_INBOX_UPDATE will refresh the frame.
function GHU_Mail:AssembleTransfer(index)
	local meta = self:GetTransferMeta(index);
	if not meta then return nil; end
	local key = GHU_MailKey(meta.sender,meta.id);
	if self.cache[key] and self.cache[key].code then return self.cache[key]; end

	local realCount = self.orig.GetInboxNumItems() or 0;
	local indices = {};
	local i;
	for i=1,realCount do
		local _,_,sender,subject = self.orig.GetInboxHeaderInfo(i);
		local m = GHU_ParseMailSubject(subject);
		if m and sender == meta.sender and m.id == meta.id and m.total == meta.total then
			indices[m.part] = i;
		end
	end

    local chunks = {};
    local transportVersion = nil;

    for i=1,meta.total do
	    local realIndex = indices[i];

	    -- A multipart GHI message can appear in the inbox before every
	    -- part has been populated.
	    if not realIndex then
		    return nil,"Loading GHI mail data...";
	    end

	    local body = self.orig.GetInboxText(realIndex);

	    if type(body) ~= "string" or body == "" then
		    return nil,"Loading GHI mail data...";
	    end


        -- Accept GHIM1/GHIM2/GHIM3 legacy mail and current GHIM4 mail.
        local prefixV4 =
	        GHU_MAIL_BODY_PREFIX_V4..
	        meta.id.."#"..
	        i.."#"..
	        meta.total.."#";

        local prefixV3 =
	        GHU_MAIL_BODY_PREFIX_V3..
	        meta.id.."#"..
	        i.."#"..
	        meta.total.."#";

        local prefixV2 =
	        GHU_MAIL_BODY_PREFIX_V2..
	        meta.id.."#"..
	        i.."#"..
	        meta.total.."#";

        local prefixV1 =
	        GHU_MAIL_BODY_PREFIX_V1..
	        meta.id.."#"..
	        i.."#"..
	        meta.total.."#";


        local bodyPrefix = nil;
        local thisVersion = nil;

        if string.sub(body,1,string.len(prefixV4)) == prefixV4 then
	        bodyPrefix = prefixV4;
	        thisVersion = 4;

        elseif string.sub(body,1,string.len(prefixV3)) == prefixV3 then
	        bodyPrefix = prefixV3;
	        thisVersion = 3;

        elseif string.sub(body,1,string.len(prefixV2)) == prefixV2 then
	        bodyPrefix = prefixV2;
	        thisVersion = 2;

        elseif string.sub(body,1,string.len(prefixV1)) == prefixV1 then
	        bodyPrefix = prefixV1;
	        thisVersion = 1;

        else
	        return nil,"Loading GHI mail data...";
        end

	    -- Every part of one transfer must use the same transport format.
	    if transportVersion == nil then
		    transportVersion = thisVersion;

	    elseif transportVersion ~= thisVersion then
		    return nil,"GHI mail transfer contains mixed transport versions.";
	    end


	    chunks[i] = string.sub(
		    body,
		    string.len(bodyPrefix)+1
	    );
    end


    local payload = table.concat(chunks,"");


    -- GHIM4:
    -- first character = compression flag
    -- rest = mail-safe Base64 data
    if transportVersion == 4 then

	    if string.len(payload) < 2 then
		    return nil,"GHI mail GHIM4 payload is corrupt.";
	    end

	    local compressedFlag =
		    string.sub(payload,1,1);

	    local encoded =
		    string.sub(payload,2);

	    local decoded =
		    GHU_Base64Decode(encoded);

	    if not decoded then
		    return nil,"GHI mail Base64 data is corrupt.";
	    end


	    if compressedFlag == "1" then

		    decoded = GHU_Decompress(decoded);

		    if not decoded then
			    return nil,"GHI mail compressed data is corrupt.";
		    end

	    elseif compressedFlag ~= "0" then

		    return nil,"GHI mail compression flag is corrupt.";
	    end


	    payload = decoded;


    -- GHIM3 compatibility.
    elseif transportVersion == 3 then

	    payload = GHU_MailHexDecode(payload);

	    if not payload then
		    return nil,"GHI mail hex data is corrupt.";
	    end


    -- GHIM2 compatibility.
    elseif transportVersion == 2 then

	    payload = GHU_MailDecode(payload);
    end
	local colon = string.find(payload,":",1,true);
	if not colon then return nil,"GHI mail payload is corrupt."; end
	local bodyLen = tonumber(string.sub(payload,1,colon-1));
	if not bodyLen then return nil,"GHI mail payload is corrupt."; end
	local userBodyStart = colon + 1;
	local userBodyEnd = userBodyStart + bodyLen - 1;
	local userBody = "";
	if bodyLen > 0 then userBody = string.sub(payload,userBodyStart,userBodyEnd); end
	local code = string.sub(payload,userBodyEnd+1);
	if code == "" then return nil,"GHI mail contains no item data."; end

	local ID,amount,item;
	if type(GHI_PeekExportItem)=="function" then
		ID,amount,item = GHI_PeekExportItem(code);
	end
	local data = { code=code, body=userBody, ID=ID, amount=amount, item=item, meta=meta };
	self.cache[key] = data;
	return data;
end

function GHU_Mail:RetryPendingReceives()
	if not self.pendingReceives then return; end
	local key,entry;
	for key,entry in pairs(self.pendingReceives) do
		if entry and entry.index then
			local data,err = self:AssembleTransfer(entry.index);
			if data then
				self.pendingReceives[key] = nil;
			elseif err and string.find(err,"Loading GHI mail data",1,true) then
				-- Still waiting for the server to populate one or more bodies.
			end
		end
	end
end

-- Inbox hooks ----------------------------------------------------------------
function GHU_Mail:GetInboxItem(index,itemIndex)
	self = gself or self;
	-- Vanilla/Turtle 1.12 FrameXML calls GetInboxItem(index) with no
	-- attachment index because each server mail has only one package slot.
	-- Treat an omitted index as attachment slot 1 for our virtual GHI package.
	local requestedItemIndex = itemIndex;
	if requestedItemIndex == nil then requestedItemIndex = 1; end
	local meta = self:GetTransferMeta(index);
	if meta and meta.part == 1 and requestedItemIndex == 1 and not self:IsClaimed(meta.sender,meta.id) then
		local data = self:AssembleTransfer(index);
		local name = "GHI Item";
		local icon = "Interface\\Icons\\INV_Misc_Gift_04";
		local amount = 1;
		local quality = 1;
		if type(data)=="table" then
			amount = tonumber(data.amount) or 1;
			if type(data.item)=="table" then
				name = data.item.name or name;
				icon = data.item.icon or icon;
				quality = data.item.quality or quality;
			end
		end
		return name,icon,amount,quality,1;
	end
	if itemIndex == nil then
		return self.orig.GetInboxItem(index);
	end
	return self.orig.GetInboxItem(index,itemIndex);
end

function GHU_Mail:GetInboxHeaderInfo(index)
	self = gself or self;

	local packageIcon,stationeryIcon,sender,subject,money,CODAmount,daysLeft,hasItem,wasRead,wasReturned,textCreated,canReply,isGM = self.orig.GetInboxHeaderInfo(index);
	local meta = GHU_ParseMailSubject(subject);
	if meta then
		-- TurtleMail's automatic "Open All" routine skips GM mail. GHI multipart
		-- mail must be protected from that routine because TurtleMail otherwise
		-- calls TakeInboxItem() and DeleteInboxItem() before GetInboxText() has
		-- necessarily populated the server-side body. GHI needs all parts to
		-- remain in the inbox until the complete transfer can be assembled.
		isGM = true;

		if meta.part == 1 then
			subject = meta.subject ~= "" and meta.subject or "GHI Item";
			if not self:IsClaimed(sender,meta.id) then
				packageIcon = "Interface\\Icons\\INV_Misc_Gift_04";
				hasItem = 1;
			else
				packageIcon = nil;
				hasItem = nil;
			end
		else
			subject = "GHI item data ("..meta.part.."/"..meta.total..")";
			hasItem = nil;
			packageIcon = nil;
		end
	end
	return packageIcon,stationeryIcon,sender,subject,money,CODAmount,daysLeft,hasItem,wasRead,wasReturned,textCreated,canReply,isGM;
end

function GHU_Mail:GetInboxNumItems()
	self = gself or self;
	return self.orig.GetInboxNumItems();
end

function GHU_Mail:GetInboxText(index)
    self = gself or self;

    local nativeBody, nativeStationery = self.orig.GetInboxText(index);

	local meta = self:GetTransferMeta(index);
	if meta then
		local stationery = nativeStationery;
		if meta.part == 1 then
			local data,err = self:AssembleTransfer(index);
			if data then
				if data.body and data.body ~= "" then return data.body,stationery; end
				return "A Gryphonheart Item is attached to this letter.",stationery;
			end
			return (err or "Loading GHI item data...").."\n\nKeep all GHI mail parts until the attachment is claimed.",stationery;
		end
		return "This message contains part "..meta.part.." of "..meta.total.." of a Gryphonheart Item attachment. Keep it until the attachment in the first message has been claimed.",stationery;
	end
	return nativeBody,nativeStationery;
end

function GHU_Mail:GetLatestThreeSenders()
	self = gself or self;
	return self.orig.GetLatestThreeSenders();
end

function GHU_Mail:TakeInboxItem(index)
	self = gself or self;
	local meta = self:GetTransferMeta(index);
	if meta and meta.part == 1 then
		if self:IsClaimed(meta.sender,meta.id) then
			GHU_MailMessage("That GHI mail attachment has already been claimed.");
			return;
		end
		local data,err = self:AssembleTransfer(index);
		if not data then
			if err and string.find(err,"Loading GHI mail data",1,true) then
				self.pendingReceives = self.pendingReceives or {};
				local receiveKey = GHU_MailKey(meta.sender,meta.id);
				self.pendingReceives[receiveKey] = {
					index=index, id=meta.id, sender=meta.sender, total=meta.total
				};
				GHU_MailMessage("GHI mail is still downloading. Waiting for the inbox to update...");
			else
				GHU_MailMessage(err or "GHI mail data is still loading. Open the letter again in a moment.");
			end
			if type(CheckInbox)=="function" then CheckInbox(); end
			return;
		end
		if type(GHI_ImportItem) ~= "function" then
			GHU_MailMessage("GHI is not loaded; cannot claim this attachment.");
			return;
		end
		GHI_ImportItem(data.code);
		self:SetClaimed(meta.sender,meta.id);
		GHU_MailMessage("GHI mail attachment claimed.");
		if type(InboxFrame_Update)=="function" then InboxFrame_Update(); end
		if type(OpenMail_Update)=="function" then OpenMail_Update(); end
		return;
	end
	return self.orig.TakeInboxItem(index);
end

-- Send-side virtual attachment ------------------------------------------------
function GHU_Mail:UnlockPendingAttachment()
	local p = self.pendingAttachment;
	if not p then return; end
	if type(GHI_ContainerData)=="table" and type(GHI_ContainerData[p.bag])=="table" and type(GHI_ContainerData[p.bag][p.slot])=="table" then
		if GHI_ContainerData[p.bag][p.slot].ID == p.ID then
			GHI_ContainerData[p.bag][p.slot].locked = nil;
		end
	end
	if type(GHI_UpdateContainers)=="function" then GHI_UpdateContainers(); end
end

function GHU_Mail:ClearPendingAttachment(unlock)
	if unlock then self:UnlockPendingAttachment(); end
	self.pendingAttachment = nil;
	if type(SendMailFrame_Update)=="function" and not self._updatingSendFrame then
		SendMailFrame_Update();
	end
end

function GHU_Mail:ApplyAttachmentVisual()
	local p = self.pendingAttachment;
	if not p then return; end
	local button = self:GetSendAttachmentButton(p.mailSlot or 1);
	if not button then return; end
	local icon = p.icon or "Interface\\Icons\\INV_Misc_QuestionMark";
	button:SetNormalTexture(icon);
	local count = nil;
	if type(button.GetName)=="function" then count = getglobal((button:GetName() or "").."Count"); end
	if count then
		if (p.amount or 1) > 1 then count:SetText(p.amount); count:Show(); else count:SetText(""); count:Hide(); end
	end
	button:Show();
	if SendMailCODButton then SendMailCODButton:Disable(); end
	if SendMailCODButtonText then SendMailCODButtonText:SetTextColor(GRAY_FONT_COLOR.r,GRAY_FONT_COLOR.g,GRAY_FONT_COLOR.b); end
	if SendMailSubjectEditBox and (SendMailSubjectEditBox:GetText()=="" or SendMailSubjectEditBox:GetText()==SendMailFrame.previousItem) then
		SendMailSubjectEditBox:SetText(p.name or "GHI Item");
		SendMailFrame.previousItem = p.name or "GHI Item";
	end
end

function GHU_Mail:HasRealSendAttachment()
	local i;
	for i=1,self:GetMaxSendAttachments() do
		local button = self:GetSendAttachmentButton(i);
		-- TurtleMail stores queued attachments on MailAttachmentN.item instead of
		-- leaving them in the Blizzard send slot until the actual send begins.
		if button and button.item then return true; end
		if type(GetSendMailItem)=="function" then
			local realName = GetSendMailItem(i);
			if realName then return true; end
		end
	end
	return false;
end

function GHU_Mail:AttachGHIItem(details,mailSlot)
	if self.sending then
		GHU_MailMessage("A GHI mail is already being sent.");
		return false;
	end
	if self.pendingAttachment then
		GHU_MailMessage("Remove the current GHI mail attachment first.");
		return false;
	end
	if self:HasRealSendAttachment() then
		GHU_MailMessage("Remove the normal WoW mail attachment(s) before attaching a GHI item.");
		return false;
	end
	mailSlot = tonumber(mailSlot) or 1;
	if mailSlot < 1 or mailSlot > self:GetMaxSendAttachments() then mailSlot = 1; end
	if type(details)~="table" or not details.id or not details.ItemOrigBag or not details.ItemOrigFrame then return false; end
	if type(GHI_IsBagEmpty)=="function" and GHI_IsBagEmpty(details.id)==false then
		GHU_MailMessage("Empty this GHI bag before mailing it.");
		return false;
	end
	local name,icon = GHI_GetItemInfo(details.id);
	local slot = details.ItemOrigFrame.number;
	local amount = tonumber(details.ItemAmount) or 0;
	-- GHI uses ItemAmount == 0 to mean "the entire stack" when an item is
	-- picked up normally.  Resolve that sentinel before serializing the mail.
	if amount <= 0 then
		local info = GHI_GetContainerInfo(details.ItemOrigBag,slot);
		if type(info)=="table" then amount = tonumber(info.amount) or 1; else amount = 1; end
	end
	self.pendingAttachment = {
		ID = details.id,
		amount = amount,
		bag = details.ItemOrigBag,
		slot = slot,
		frame = details.ItemOrigFrame,
		name = name or "GHI Item",
		icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark",
		mailSlot = mailSlot,
	};
	GHI_ResetCursor();
	-- GHI_ResetCursor unlocks the source slot; lock it again while the item is
	-- attached to the outgoing mail so it cannot be moved during the transfer.
	local p = self.pendingAttachment;
	if type(GHI_ContainerData)=="table" and type(GHI_ContainerData[p.bag])=="table" and type(GHI_ContainerData[p.bag][p.slot])=="table" then
		GHI_ContainerData[p.bag][p.slot].locked = 1;
	end
	if type(GHI_UpdateContainers)=="function" then GHI_UpdateContainers(); end
	self:ApplyAttachmentVisual();
	GHU_MailMessage("GHI item attached to mail.");
	return true;
end

function GHU_Mail:SendMailFrame_Update()
	self = gself or self;
	self._updatingSendFrame = true;
	local r = self.orig.SendMailFrame_Update();
	self._updatingSendFrame = nil;
	self:ApplyAttachmentVisual();
	return r;
end

function GHU_Mail:MakeTransportSubject(mailID,part,total,subject)
	local prefix = GHU_MAIL_SUBJECT_PREFIX..mailID.."#"..part.."#"..total.."#";
	if part == 1 then
		local max = 64 - string.len(prefix);
		if max < 0 then max = 0; end
		return prefix..string.sub(subject or "GHI Item",1,max);
	end
	return prefix;
end

function GHU_Mail:SendNextPart()
	local s = self.sending;
	if not s then return; end

	local part = s.part;
	local subject = self:MakeTransportSubject(s.mailID,part,s.total,s.subject);
	local bodyPrefix = GHU_MAIL_BODY_PREFIX..s.mailID.."#"..part.."#"..s.total.."#";
	local body = bodyPrefix..s.parts[part];

	SendMail(s.to,subject,body);
end

function GHU_Mail:BeginGHIItemSend()
	local p = self.pendingAttachment;
	if not p then return false; end
	if self.sending then return true; end
	if type(GHI_TransferExportItem) ~= "function" then
		GHU_MailMessage("GHI mail transfer support is not loaded.");
		return true;
	end
	local to = SendMailNameEditBox and SendMailNameEditBox:GetText() or "";
	local subject = SendMailSubjectEditBox and SendMailSubjectEditBox:GetText() or "";
	local userBody = SendMailBodyEditBox and SendMailBodyEditBox:GetText() or "";
	if to == "" or subject == "" then
		GHU_MailMessage("Enter a recipient and subject before sending the GHI item.");
		return true;
	end
	if SendMailMoney and type(MoneyInputFrame_GetCopper)=="function" and MoneyInputFrame_GetCopper(SendMailMoney) > 0 then
		GHU_MailMessage("GHI item mail cannot include money or C.O.D. Clear the money field first.");
		return true;
	end
	if self:HasRealSendAttachment() then
		GHU_MailMessage("A GHI item cannot be mailed together with normal WoW attachments yet. Remove them first.");
		return true;
	end

	local code,err = GHI_TransferExportItem(p.ID,p.amount);

	if not code then
		GHU_MailMessage(err or "Could not prepare GHI item for mail.");
		return true;
	end
--[[
    -- Construct the normal GHI payload first.
    local rawPayload = string.len(userBody)..":"..userBody..code;

    -- Encode the complete payload as hexadecimal before chunking.
    -- GHIM3 therefore transports only characters 0-9 and A-F.
    local payload = GHU_MailHexEncode(rawPayload);

	local total = math.ceil(string.len(payload) / GHU_MAIL_CHUNK_SIZE);
]]

    -- Construct the original GHI mail payload.
    local rawPayload =
	    string.len(userBody)..":"..
	    userBody..
	    code;


    -- GHIM4 always Base64-encodes the transport data.
    local rawEncoded =
	    GHU_Base64Encode(rawPayload);


    -- Try compression first.
    local compressed =
	    GHU_Compress(rawPayload);

    local compressedEncoded = nil;

    if compressed then
	    compressedEncoded =
		    GHU_Base64Encode(compressed);
    end


    local payload;
    local compressedFlag;


    -- Use compression only when the FINAL Base64 representation
    -- is actually smaller.
    if compressedEncoded
	    and string.len(compressedEncoded) < string.len(rawEncoded) then

	    compressedFlag = "1";
	    payload = compressedFlag..compressedEncoded;

    else

	    compressedFlag = "0";
	    payload = compressedFlag..rawEncoded;
    end

    if compressedFlag == "1" then
	    GHU_MailMessage(
		    "GHIM4 compressed: "..
		    string.len(rawPayload)..
		    " bytes -> "..
		    string.len(payload)..
		    " transport characters."
	    );
    else
	    GHU_MailMessage(
		    "GHIM4 uncompressed: "..
		    string.len(rawPayload)..
		    " bytes -> "..
		    string.len(payload)..
		    " transport characters."
	    );
    end


    -- Chunk the FINAL GHIM4 transport representation.
    local total =
	    math.ceil(
		    string.len(payload) /
		    GHU_MAIL_CHUNK_SIZE
	    );

    if total < 1 then
	    total = 1;
    end
	if total > 50 then
		GHU_MailMessage("This GHI item is too large to mail safely (more than 50 mail parts). Use trade or Export Item instead.");
		return true;
	end
	local postage = 0;
	if type(GetSendMailPrice)=="function" then postage = (GetSendMailPrice() or 0) * total; end
	if postage > GetMoney() then
		GHU_MailMessage("Not enough money for the "..total.." mail part(s) required by this GHI item.");
		return true;
	end

	local mailID = tostring(mod(time(),100000000));
	if math and math.random then mailID = mailID..tostring(math.random(100,999)); end
	local parts = {};
	local i;
	for i=1,total do
		local a = ((i-1)*GHU_MAIL_CHUNK_SIZE)+1;
		parts[i] = string.sub(payload,a,a+GHU_MAIL_CHUNK_SIZE-1);
	end

    self.sending = {
        to=to, subject=subject, mailID=mailID, parts=parts, total=total, part=1,
        bag=p.bag, slot=p.slot, frame=p.frame, amount=p.amount, ID=p.ID, name=p.name,
    };
	GHU_MailMessage("Sending "..p.name.." by GHI mail ("..total.." part"..((total==1) and "" or "s")..").");
	self:SendNextPart();
	return true;
end

function GHU_Mail:SendMailFrame_SendMail()
	self = gself or self;
	if self.pendingAttachment then
		self:BeginGHIItemSend();
		return;
	end
	return self.orig.SendMailFrame_SendMail();
end

function GHU_Mail:MailSendSucceeded()
	local s = self.sending;
	if not s then return; end

	if s.part < s.total then
		-- The current part succeeded. Give the next part its own retry allowance.
		s.retry = 0;

		s.part = s.part + 1;

		if self.multipartSendFrame then
			self.multipartSendFrame:SetScript("OnUpdate",nil);
		end

		local obj = self;
		local expectedSending = s;
		local elapsed = 0;

		self.multipartSendFrame = CreateFrame("Frame");
		self.multipartSendFrame:SetScript("OnUpdate",function()
			elapsed = elapsed + (arg1 or 0);

			if elapsed >= 2 then
				self.multipartSendFrame:SetScript("OnUpdate",nil);
				self.multipartSendFrame = nil;

				if obj.sending == expectedSending then
					obj:SendNextPart();
				end
			end
		end);

		return;
	end

	-- All server-mail chunks are safely accepted.
	if type(GHI_ContainerData)=="table"
		and type(GHI_ContainerData[s.bag])=="table"
		and type(GHI_ContainerData[s.bag][s.slot])=="table" then

		GHI_ContainerData[s.bag][s.slot].locked = nil;
	end

	if type(GHI_DeleteItem)=="function" then
		GHI_DeleteItem(s.frame,s.amount,s.bag,s.slot);
	end

	self.sending = nil;
	self.pendingAttachment = nil;

	GHU_MailMessage("GHI item mailed successfully.");

	if type(SendMailFrame_Update)=="function" then
		SendMailFrame_Update();
	end
end

function GHU_Mail:MailSendFailed()
	local s = self.sending;
	if not s then return; end
	-- Retry multipart parts once if the mail subsystem rejects a send.
	-- Keep the retry timer separate from the normal success-to-next-part timer.
	if s.total and s.total > 1 then
		s.retry = (s.retry or 0) + 1;

		if s.retry <= 1 then
			local obj = self;
			local expectedSending = s;

			if obj.multipartRetryFrame then
				obj.multipartRetryFrame:SetScript("OnUpdate",nil);
				obj.multipartRetryFrame = nil;
			end

			obj.multipartRetryFrame = CreateFrame("Frame");
			local elapsed = 0;

			obj.multipartRetryFrame:SetScript("OnUpdate",function()
				elapsed = elapsed + (arg1 or 0);

				if elapsed >= 2 then
					obj.multipartRetryFrame:SetScript("OnUpdate",nil);
					obj.multipartRetryFrame = nil;

					if obj.sending == expectedSending then
						obj:SendNextPart();
					end
				end
			end);

			return;
		end
	end

	self.sending = nil;
	GHU_MailMessage("GHI mail failed. The item was not removed from your bag.");
	self:ApplyAttachmentVisual();
end

function GHU_Mail:NewMail()
	-- Kept for compatibility with the unfinished original GHU API. Sending GHI
	-- items is now integrated directly into the normal Send Mail frame above.
end

-- Activate the mailbox hook automatically. The original source only included
-- this as a commented /script example.
if type(GHU_New)=="function" and not GHU_Mail.activeObject then
	GHU_Mail.activeObject = GHU_New("Mail","GHP_Mail");
end

-- Event handling for inbox refresh and multipart GHI mail delivery.
if not GHU_Mail.mailEventFrame then
	local f = CreateFrame("Frame","GHU_MailEventFrame");
	f:RegisterEvent("MAIL_SHOW");
	f:RegisterEvent("MAIL_INBOX_UPDATE");
	f:RegisterEvent("MAIL_SEND_SUCCESS");
	f:RegisterEvent("MAIL_FAILED");
	f:RegisterEvent("MAIL_CLOSED");
	f:SetScript("OnEvent",function()
		local obj = GHU_Mail.activeObject;
		if event == "MAIL_SEND_SUCCESS" then
			if obj then obj:MailSendSucceeded(); end
		elseif event == "MAIL_FAILED" then
			if obj then obj:MailSendFailed(); end
		elseif event == "MAIL_CLOSED" then
			if obj and not obj.sending and obj.pendingAttachment then obj:ClearPendingAttachment(true); end
		elseif event == "MAIL_SHOW" or event == "MAIL_INBOX_UPDATE" then
			if obj then obj:InstallSendHooks(); end
			if type(InboxFrame_Update)=="function" then InboxFrame_Update(); end
			if OpenMailFrame and OpenMailFrame:IsVisible() and type(OpenMail_Update)=="function" then OpenMail_Update(); end
			if obj then obj:RetryPendingReceives(); end
		end
	end);
	-- Install/reinstall mail hooks only when the mailbox UI exists.
	GHU_Mail.mailEventFrame = f;
end
