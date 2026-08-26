GHU_Mail = {}
GHU_Mail.__index = GHU_Mail;
GHU_Mail.hooked = {};
GHU_Mail.cache = {};
GHU_Mail.pendingAttachment = nil;
GHU_Mail.pendingReceives = {};
GHU_Mail.sending = nil;

local GHU_MAIL_SUBJECT_PREFIX = "GHI#";
local GHU_MAIL_BODY_PREFIX = "GHIM1#";
local GHU_MAIL_CHUNK_SIZE = 460; -- Vanilla SendMail body editbox is limited to 500 chars.

local function GHU_MailMessage(msg)
	if type(GHI_Message) == "function" then
		GHI_Message(msg);
	elseif DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(msg);
	end
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
	for i=1,meta.total do
		local realIndex = indices[i];
		local body = self.orig.GetInboxText(realIndex);
		local bodyPrefix = GHU_MAIL_BODY_PREFIX..meta.id.."#"..i.."#"..meta.total.."#";
		chunks[i] = string.sub(body,string.len(bodyPrefix)+1);
	end

	local payload = table.concat(chunks,"");
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
			subject = "GHI item data ("..meta.part.."\/"..meta.total..")";
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
	local meta = self:GetTransferMeta(index);
	if meta then
		local _,stationery = self.orig.GetInboxText(index);
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
	return self.orig.GetInboxText(index);
end

function GHU_Mail:GetLatestThreeSenders()
	self = gself or self;
	-- Preserve the original GHU demonstration behavior.
	return "Ian Drake","Stormwind Council";
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
	local payload = string.len(userBody)..":"..userBody..code;
	local total = math.ceil(string.len(payload) / GHU_MAIL_CHUNK_SIZE);
	if total < 1 then total = 1; end
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
		codeLength=string.len(code), payloadLength=string.len(payload),
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
	-- All server-mail chunks are safely accepted. Consume the sender's virtual
	-- item only now, matching the success semantics of GHI trade.
	if type(GHI_ContainerData)=="table" and type(GHI_ContainerData[s.bag])=="table" and type(GHI_ContainerData[s.bag][s.slot])=="table" then
		GHI_ContainerData[s.bag][s.slot].locked = nil;
	end
	if type(GHI_DeleteItem)=="function" then
		GHI_DeleteItem(s.frame,s.amount,s.bag,s.slot);
	end
	self.sending = nil;
	self.pendingAttachment = nil;
	GHU_MailMessage("GHI item mailed successfully.");
	if type(SendMailFrame_Update)=="function" then SendMailFrame_Update(); end
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
	-- v44: no continuous mail polling during login or normal gameplay.
	-- TurtleMail/Blizzard mail hooks are installed only from MAIL_SHOW and
	-- MAIL_INBOX_UPDATE after the mail UI exists.
	GHU_Mail.mailEventFrame = f;
end
