GHU_Stash = CreateFrame("frame");
GHU_Stash.__index = GHU_Stash;
GHU_Stash.hooked = {};
GHU_Stash.GHIContainerID = 100;

GHU_Stash.zoneSyncPending = false;
GHU_Stash.zoneSyncElapsed = 0;
GHU_Stash.zoneSyncDelay = 2;

GHU_Stash.currentStash = nil;

GHU_Stash.channelName = "GHUstashUHG";

GHU_Stash.transportPrefix = "GHUS1";
GHU_Stash.transportSerial = 0;

GHU_Stash.transportChunkSize = 180;
GHU_Stash.transportSendDelay = 0.20;
GHU_Stash.transportSendElapsed = 0;

GHU_Stash.transportSendQueue = {};
GHU_Stash.transportIncoming = {};

GHU_Stash.transportTimeout = 15;
GHU_Stash.manifestWait = 3;
GHU_Stash.stashRequestTimeout = 6;

GHU_Stash.base64Alphabet =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	.. "abcdefghijklmnopqrstuvwxyz"
	.. "0123456789+/";

-- Physical-zone synchronization.
GHU_Stash.prioritySyncPending = false;
GHU_Stash.priorityLocation = nil;

-- Background zone cycle.
GHU_Stash.cycleActive = false;
GHU_Stash.cycleZones = {};
GHU_Stash.cycleIndex = 1;
GHU_Stash.cyclePaused = false;

-- Current reconciliation transaction.
GHU_Stash.syncRequest = nil;
GHU_Stash.syncRequestSerial = 0;

-- Full-stash requests currently in flight.
GHU_Stash.pendingStashRequests = {};

-- How close the player must be to interact with a stash.
-- Coordinates run from 0.0 to 1.0, so 0.005 is roughly
-- half of one percent of the zone map.
GHU_Stash.searchTolerance = 0.015;
GHU_Stash.locationTolerance = 0.005;

function GHU_Stash:AddMessage(message)
	local chatFrame = SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME;

	if chatFrame then
		chatFrame:AddMessage(message);
	end
end

function GHU_Stash:Init()
	if not GHU_StashData then
		GHU_StashData = {};
	end

	if not GHU_StashData.stashes then
		GHU_StashData.stashes = {};
	end

	if not GHU_StashData.replicaStashes then
		GHU_StashData.replicaStashes = {};
	end

	self.stashes = GHU_StashData.stashes;
	self.replicaStashes = GHU_StashData.replicaStashes;

	-- Container 100 is only the temporary bridge to
	-- whichever stash is currently open.
	if type(GHI_ContainerData) == "table" then
		GHI_ContainerData[self.GHIContainerID] = nil;
	end

	self:HookGHI();
	self:InitCommunication();
end

function GHU_Stash:JoinStashChannel()
	if not self.channelName then
		return false;
	end

	local channelID = GetChannelName(self.channelName);

	if not channelID or channelID == 0 then
		JoinChannelByName(self.channelName);
	end

	return true;
end

function GHU_Stash:InitCommunication()
	if self.hooked.communication then
		return;
	end

	if not LibStub then
		self:AddMessage(
			"GHU stash communication is not available."
		);
		return;
	end

	self.serializer =
		LibStub("AceSerializer-3.0", true);

	if not self.serializer then
		self:AddMessage(
			"GHU stash serializer is not available."
		);
		return;
	end

	self.transportSendQueue = {};
	self.transportIncoming = {};

	self.hooked.communication = true;
end

function GHU_Stash:Base64Encode(text)
	if not text then
		return "";
	end

	local alphabet = self.base64Alphabet;
	local result = {};

	local length = string.len(text);
	local i = 1;

	while i <= length do
		local b1 = string.byte(text, i);
		local b2 = nil;
		local b3 = nil;

		if i + 1 <= length then
			b2 = string.byte(text, i + 1);
		end

		if i + 2 <= length then
			b3 = string.byte(text, i + 2);
		end

		local c1 = math.floor(b1 / 4);

		local c2 =
			math.mod(b1, 4) * 16;

		if b2 then
			c2 = c2 + math.floor(b2 / 16);
		end

		local c3 = 0;
		local c4 = 0;

		if b2 then
			c3 =
				math.mod(b2, 16) * 4;

			if b3 then
				c3 =
					c3 + math.floor(b3 / 64);
			end
		end

		if b3 then
			c4 = math.mod(b3, 64);
		end

		table.insert(
			result,
			string.sub(
				alphabet,
				c1 + 1,
				c1 + 1
			)
		);

		table.insert(
			result,
			string.sub(
				alphabet,
				c2 + 1,
				c2 + 1
			)
		);

		if b2 then
			table.insert(
				result,
				string.sub(
					alphabet,
					c3 + 1,
					c3 + 1
				)
			);
		else
			table.insert(result, "=");
		end

		if b3 then
			table.insert(
				result,
				string.sub(
					alphabet,
					c4 + 1,
					c4 + 1
				)
			);
		else
			table.insert(result, "=");
		end

		i = i + 3;
	end

	return table.concat(result);
end

function GHU_Stash:GetBase64Value(character)
	if not character
		or character == "=" then

		return nil;
	end

	local position =
		string.find(
			self.base64Alphabet,
			character,
			1,
			true
		);

	if not position then
		return nil;
	end

	return position - 1;
end


function GHU_Stash:Base64Decode(text)
	if not text then
		return nil;
	end

	local result = {};
	local length = string.len(text);
	local i = 1;

	while i <= length do
		local a = string.sub(text, i, i);
		local b = string.sub(text, i + 1, i + 1);
		local c = string.sub(text, i + 2, i + 2);
		local d = string.sub(text, i + 3, i + 3);

		local v1 = self:GetBase64Value(a);
		local v2 = self:GetBase64Value(b);
		local v3 = self:GetBase64Value(c);
		local v4 = self:GetBase64Value(d);

		if v1 == nil or v2 == nil then
			return nil;
		end

		local b1 =
			(v1 * 4)
			+
			math.floor(v2 / 16);

		table.insert(
			result,
			string.char(b1)
		);

		if c ~= "=" and v3 ~= nil then
			local b2 =
				(math.mod(v2, 16) * 16)
				+
				math.floor(v3 / 4);

			table.insert(
				result,
				string.char(b2)
			);
		end

		if d ~= "="
			and v3 ~= nil
			and v4 ~= nil then

			local b3 =
				(math.mod(v3, 4) * 64)
				+
				v4;

			table.insert(
				result,
				string.char(b3)
			);
		end

		i = i + 4;
	end

	return table.concat(result);
end

function GHU_Stash:GetNextTransportID()
	self.transportSerial =
		(tonumber(self.transportSerial) or 0) + 1;

	return tostring(
		self:GetNameChecksum(
			self:GetPlayerName() or ""
		)
	)
		.. "-"
		.. tostring(time())
		.. "-"
		.. tostring(self.transportSerial);
end

function GHU_Stash:SendTransport(
	messageType,
	payload
)
	if not self.serializer then
		return false;
	end

	local packet = {
		type = messageType,
		payload = payload,
	};

	local serialized =
		self.serializer:Serialize(packet);

	if not serialized then
		return false;
	end

	local encoded =
		self:Base64Encode(serialized);

	local transportID =
		self:GetNextTransportID();

	local length = string.len(encoded);

	local total =
		math.ceil(
			length / self.transportChunkSize
		);

	if total < 1 then
		total = 1;
	end

	local part;

	for part = 1, total do
		local first =
			((part - 1)
			* self.transportChunkSize)
			+ 1;

		local last =
			first
			+ self.transportChunkSize
			- 1;

		local chunk =
			string.sub(
				encoded,
				first,
				last
			);

		local message =
			self.transportPrefix
			.. ":"
			.. transportID
			.. ":"
			.. tostring(part)
			.. ":"
			.. tostring(total)
			.. ":"
			.. chunk;

		table.insert(
			self.transportSendQueue,
			message
		);
	end

	return true;
end

function GHU_Stash:ProcessTransportQueue(elapsed)
	if not elapsed then
		return;
	end

	if table.getn(self.transportSendQueue) == 0 then
		self.transportSendElapsed = 0;
		return;
	end

	self.transportSendElapsed =
		self.transportSendElapsed + elapsed;

	if self.transportSendElapsed
		< self.transportSendDelay then

		return;
	end

	self.transportSendElapsed = 0;

	local channelID =
		GetChannelName(self.channelName);

	if not channelID
		or channelID <= 0 then

		self:JoinStashChannel();
		return;
	end

	local message =
		table.remove(
			self.transportSendQueue,
			1
		);

	if not message then
		return;
	end

	SendChatMessage(
		message,
		"CHANNEL",
		nil,
		channelID
	);
end

function GHU_Stash:GetZoneStashes(continent, zone)
	local result = {};

	local sources = {
		self.stashes,
		self.replicaStashes,
	};

	local sourceIndex;
	local source;
	local stashID;
	local stash;
	local existing;

	for sourceIndex = 1, table.getn(sources) do
		source = sources[sourceIndex];

		for stashID, stash in pairs(source or {}) do
			if stash.location
				and stash.location.continent == continent
				and stash.location.zone == zone then

				existing = result[stashID];

				if not existing
					or self:IsNewerStash(
						stash,
						existing
					) then

					result[stashID] = stash;
				end
			end
		end
	end

	return result;
end

function GHU_Stash:IsNewerStash(incoming, existing)
	if not incoming then
		return false;
	end

	if not existing then
		return true;
	end

	local incomingTime = tonumber(incoming.updated) or 0;
	local existingTime = tonumber(existing.updated) or 0;

	if incomingTime > existingTime then
		return true;
	elseif incomingTime < existingTime then
		return false;
	end

	local incomingSerial =
		tonumber(incoming.updateSerial) or 0;

	local existingSerial =
		tonumber(existing.updateSerial) or 0;

	if incomingSerial > existingSerial then
		return true;
	elseif incomingSerial < existingSerial then
		return false;
	end

	-- If two records somehow have exactly the same
	-- version, a tombstone wins over a live copy.
	local incomingDeleted =
		incoming.deleted and true or false;

	local existingDeleted =
		existing.deleted and true or false;

	if incomingDeleted ~= existingDeleted then
		return incomingDeleted;
	end

	local incomingEditor =
		string.lower(incoming.lastEditor or "");

	local existingEditor =
		string.lower(existing.lastEditor or "");

	return incomingEditor > existingEditor;
end

function GHU_Stash:ReceivePublishedStash(sender, stash)
	if type(stash) ~= "table" then
		return;
	end

	if not stash.id or stash.id == "" then
		return;
	end

	if stash.deleted then
		stash.items = nil;
	end

	-- Cursor locking is local state and must never become
	-- part of the distributed stash.
	if type(stash.items) == "table" then
		local slot;
		local item;

		for slot, item in pairs(stash.items) do
			if type(item) == "table" then
				item.locked = nil;
			end
		end
	end

	--
	-- If this is one of our originally-created stashes,
	-- a newer remote copy may represent changes made while
	-- we were offline.
	--
    if self.stashes[stash.id] then
	    if self:IsNewerStash(
		    stash,
		    self.stashes[stash.id]
	    ) then

		    self.stashes[stash.id] = stash;
		    self:HandleAcceptedStash(stash);
	    end

	    return;
    end

	    local old = self.replicaStashes[stash.id];

	    if not old
		    or self:IsNewerStash(stash, old) then

		    self.replicaStashes[stash.id] = stash;
		    self:HandleAcceptedStash(stash);
	    end
    end

function GHU_Stash:ScheduleZoneSync()
	self.zoneSyncPending = true;
	self.zoneSyncElapsed = 0;
end


function GHU_Stash:Update(elapsed)
	self:ProcessTransportQueue(elapsed);
	self:CleanupTransportIncoming();

	if self.zoneSyncPending then
		self.zoneSyncElapsed =
			self.zoneSyncElapsed + elapsed;

		if self.zoneSyncElapsed
			>= self.zoneSyncDelay then

			self.zoneSyncPending = false;
			self.zoneSyncElapsed = 0;

			-- Leave synchronization disabled until
			-- the basic channel transport is proven.
			-- self:SynchronizeCurrentZone();
		end
	end
end

function GHU_Stash:GenerateStashID(location)
	if not location then
		return nil;
	end

	local playerName = self:GetPlayerName();

	if not playerName then
		return nil;
	end

	local timestamp = time();
	local checksum = self:GetNameChecksum(playerName);
	local zone = tonumber(location.zone) or 0;

	local stashID = tostring(timestamp)
		.. "-"
		.. tostring(checksum)
		.. "-"
		.. tostring(zone);

	if self.stashes and self.stashes[stashID] then
		return nil;
	end

	if self.replicaStashes and self.replicaStashes[stashID] then
		return nil;
	end

	return stashID;
end

function GHU_Stash:OnLoad()
	self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterEvent("PLAYER_LOGOUT");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA");
    self:RegisterEvent("CHAT_MSG_CHANNEL");
end


function GHU_Stash:GetPlayerName()
	return UnitName("player");
end

function GHU_Stash:EnterCurrentZone()
	local location = self:GetCurrentLocation();

	if not location then
		return;
	end

	-- A physical zone always has priority over
	-- the background reconciliation cycle.
	self.priorityLocation = location;
	self.prioritySyncPending = true;

	if self.syncRequest
		and self.syncRequest.type == "cycle" then

		self.cyclePaused = true;
	end

	self:ScheduleZoneSync();
end

function GHU_Stash:PublishStash(stash)
	if not stash
		or not stash.id then

		return false;
	end

	return self:SendTransport(
		"SDAT",
		{
			stash = stash,
		}
	);
end

function GHU_Stash:CreateBagFrame()
	if self.bagFrame then
		return;
	end

	local frame = CreateFrame("Frame", "GHU_StashBagFrame", UIParent);
	frame:SetWidth(220);
	frame:SetHeight(255);
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	frame:SetFrameStrata("DIALOG");
	frame:SetMovable(true);
	frame:EnableMouse(true);
	frame:RegisterForDrag("LeftButton");
	frame:Hide();

	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = {
			left = 8,
			right = 8,
			top = 8,
			bottom = 8,
		},
	});

	frame:SetScript("OnDragStart", function()
		this:StartMoving();
	end);

	frame:SetScript("OnDragStop", function()
		this:StopMovingOrSizing();
	end);


	-- Title
	local title = frame:CreateFontString(
		"GHU_StashBagTitle",
		"OVERLAY",
		"GameFontNormalLarge"
	);

	title:SetPoint("TOP", frame, "TOP", 0, -16);
	title:SetText("Hidden Stash");

	frame.title = title;


	-- Location text
	local locationText = frame:CreateFontString(
		"GHU_StashBagLocation",
		"OVERLAY",
		"GameFontNormalSmall"
	);

	locationText:SetPoint("TOP", title, "BOTTOM", 0, -4);
	locationText:SetText("");

	frame.locationText = locationText;


	-- Close button
    local close = CreateFrame(
	    "Button",
	    "GHU_StashBagCloseButton",
	    frame,
	    "UIPanelCloseButton"
    );

    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4);

    close:SetScript("OnClick", function()
	    GHU_Stash:CloseBag();
    end);


	-- Item slots
	frame.slots = {};

	local row;
	local column;
	local slot;
	local slotNumber = 1;

	for row = 1, 4 do
		for column = 1, 4 do

			slot = CreateFrame(
				"Button",
				"GHU_StashBagSlot" .. slotNumber,
				frame,
				"ItemButtonTemplate"
			);

			slot:SetWidth(36);
			slot:SetHeight(36);

			slot:SetPoint(
				"TOPLEFT",
				frame,
				"TOPLEFT",
				26 + ((column - 1) * 44),
				-62 - ((row - 1) * 44)
			);

            slot.slotNumber = slotNumber;
            slot.number = slotNumber;
            slot:SetID(slotNumber);

            slot:RegisterForDrag("LeftButton");
            slot:RegisterForClicks("AnyUp");


            slot:SetScript("OnClick", function()
	            -- Initially only use GHI's left-click inventory handling.
	            -- Right-click item use can be added once stash storage is stable.
	            if arg1 == "LeftButton" then
		            GHI_ContainerFrameItemButton_OnClick(arg1);
		            GHU_Stash:UpdateBag();
	            end
            end);


            slot:SetScript("OnDragStart", function()
	            if this.hasItem then
		            GHI_PickupContainerItem(this, 0);
		            GHU_Stash:UpdateBag();
	            end
            end);


            slot:SetScript("OnReceiveDrag", function()
	            local cursorType = GHI_GetCursor();

	            if cursorType == "item" then
		            GHI_PlaceContainerItem(this);
		            GHU_Stash:UpdateBag();
	            end
            end);


            slot:SetScript("OnEnter", function()
	            if this.hasItem then
		            GHI_ContainerFrameItemButton_OnEnter(this);
	            end
            end);


            slot:SetScript("OnLeave", function()
	            GameTooltip:Hide();
            end);


            frame.slots[slotNumber] = slot;

			slotNumber = slotNumber + 1;
		end
	end

	self.bagFrame = frame;
end

function GHU_Stash:IsStashChannelEvent(
	channelString,
	channelNumber,
	channelName
)
	local wanted =
		string.lower(
			self.channelName or ""
		);

	if channelName
		and string.lower(channelName)
			== wanted then

		return true;
	end

	if channelString
		and string.find(
			string.lower(channelString),
			wanted,
			1,
			true
		) then

		return true;
	end

	local channelID =
		GetChannelName(self.channelName);

	if channelID
		and channelID > 0
		and tonumber(channelNumber)
			== tonumber(channelID) then

		return true;
	end

	return false;
end

function GHU_Stash:ReceiveChannelChat(
	message,
	sender,
	channelString,
	channelNumber,
	channelName
)
	if not self:IsStashChannelEvent(
		channelString,
		channelNumber,
		channelName
	) then

		return;
	end

	if not message or not sender then
		return;
	end

	if string.lower(sender)
		== string.lower(
			self:GetPlayerName() or ""
		) then

		return;
	end

	local prefix;
	local transportID;
	local part;
	local total;
	local data;

	_, _, prefix,
		transportID,
		part,
		total,
		data =
		string.find(
			message,
			"^([^:]+):([^:]+):(%d+):(%d+):(.+)$"
		);

	if prefix ~= self.transportPrefix then
		return;
	end

	part = tonumber(part);
	total = tonumber(total);

	if not part
		or not total
		or part < 1
		or part > total
		or total > 1000 then

		return;
	end

	local key =
		string.lower(sender)
		.. ":"
		.. transportID;

	local incoming =
		self.transportIncoming[key];

	if not incoming then
		incoming = {
			sender = sender,
			total = total,
			parts = {},
			count = 0,
			time = GetTime(),
		};

		self.transportIncoming[key] =
			incoming;
	end

	if incoming.total ~= total then
		self.transportIncoming[key] = nil;
		return;
	end

	incoming.time = GetTime();

	if not incoming.parts[part] then
		incoming.parts[part] = data;
		incoming.count =
			incoming.count + 1;
	end

	if incoming.count < incoming.total then
		return;
	end

	local chunks = {};
	local i;

	for i = 1, incoming.total do
		if not incoming.parts[i] then
			return;
		end

		table.insert(
			chunks,
			incoming.parts[i]
		);
	end

	self.transportIncoming[key] = nil;

	local encoded =
		table.concat(chunks);

	local serialized =
		self:Base64Decode(encoded);

	if not serialized then
		return;
	end

	local success;
	local packet;

	success, packet =
		self.serializer:Deserialize(
			serialized
		);

	if not success
		or type(packet) ~= "table" then

		return;
	end

	self:HandleTransportMessage(
		sender,
		packet
	);
end

function GHU_Stash:CleanupTransportIncoming()
	local now = GetTime();
	local key;
	local incoming;

	for key, incoming
		in pairs(self.transportIncoming) do

		if not incoming.time
			or now - incoming.time
				> self.transportTimeout then

			self.transportIncoming[key] =
				nil;
		end
	end
end

function GHU_Stash:HandleTransportMessage(
	sender,
	packet
)
	if type(packet) ~= "table"
		or type(packet.type) ~= "string" then

		return;
	end

	local payload =
		packet.payload or {};

	if packet.type == "MREQ" then
		self:ReceiveManifestRequest(
			sender,
			payload
		);

	elseif packet.type == "MREP" then
		self:ReceiveManifestReply(
			sender,
			payload
		);

	elseif packet.type == "SREQ" then
		self:ReceiveStashDataRequest(
			sender,
			payload
		);

	elseif packet.type == "SDAT" then
		if type(payload.stash)
			== "table" then

			self:ReceivePublishedStash(
				sender,
				payload.stash
			);
		end
	end
end

function GHU_Stash:BroadcastManifestRequest(
	requestID,
	continent,
	zone
)
	return self:SendTransport(
		"MREQ",
		{
			requestID = requestID,
			continent = continent,
			zone = zone,
		}
	);
end

function GHU_Stash:ReceiveManifestRequest(
	sender,
	payload
)
	if type(payload) ~= "table" then
		return;
	end

	local requestID =
		payload.requestID;

	local continent =
		tonumber(payload.continent);

	local zone =
		tonumber(payload.zone);

	if not requestID
		or not continent
		or not zone then

		return;
	end

	local manifest =
		self:BuildZoneManifest(
			continent,
			zone
		);

	self:SendTransport(
		"MREP",
		{
			requestID = requestID,
			requester = sender,
			continent = continent,
			zone = zone,
			manifest = manifest,
		}
	);
end

function GHU_Stash:IsSameStashVersion(
	a,
	b
)
	if not a or not b then
		return false;
	end

	if (tonumber(a.updated) or 0)
		~= (tonumber(b.updated) or 0) then

		return false;
	end

	if (tonumber(a.updateSerial) or 0)
		~= (tonumber(b.updateSerial) or 0) then

		return false;
	end

	if (a.deleted and true or false)
		~= (b.deleted and true or false) then

		return false;
	end

	if string.lower(a.lastEditor or "")
		~= string.lower(b.lastEditor or "") then

		return false;
	end

	return true;
end

function GHU_Stash:GetBestStash(stashID)
	local own =
		self.stashes
		and self.stashes[stashID];

	local replica =
		self.replicaStashes
		and self.replicaStashes[stashID];

	if own and replica then
		if self:IsNewerStash(
			replica,
			own
		) then

			return replica;
		end

		return own;
	end

	return own or replica;
end

function GHU_Stash:MergeManifest(
	holder,
	manifest
)
	if not self.syncRequest
		or type(manifest) ~= "table" then

		return;
	end

	local stashID;
	local version;

	for stashID, version
		in pairs(manifest) do

		if type(version) == "table" then
			local best =
				self.syncRequest.best[
					stashID
				];

			if not best
				or self:IsNewerStash(
					version,
					best
				) then

				self.syncRequest.best[
					stashID
				] = version;

				self.syncRequest.holders[
					stashID
				] = {
					holder
				};

			elseif self:IsSameStashVersion(
				version,
				best
			) then

				local holders =
					self.syncRequest.holders[
						stashID
					];

				if not holders then
					holders = {};
					self.syncRequest.holders[
						stashID
					] = holders;
				end

				local found = false;
				local i;

				for i = 1,
					table.getn(holders) do

					if holders[i]
						== holder then

						found = true;
						break;
					end
				end

				if not found then
					table.insert(
						holders,
						holder
					);
				end
			end
		end
	end
end

function GHU_Stash:ReceiveManifestReply(
	sender,
	payload
)
	if not self.syncRequest
		or type(payload) ~= "table" then

		return;
	end

	if payload.requestID
		~= self.syncRequest.id then

		return;
	end

	if string.lower(
		payload.requester or ""
	) ~= string.lower(
		self:GetPlayerName() or ""
	) then

		return;
	end

	self:MergeManifest(
		sender,
		payload.manifest
	);
end

function GHU_Stash:TombstoneStash(stash)
	if not stash or not stash.id then
		return false;
	end

	-- Make destruction a new version of the stash.
	self:TouchStash(stash);

	stash.deleted = true;

	-- The tombstone keeps identity, creator, location,
	-- version information, etc., but no longer needs
	-- the item contents.
	stash.items = nil;

	return true;
end

function GHU_Stash:TouchStash(stash)
	if not stash then
		return;
	end

	local timestamp = time();

	if stash.updated == timestamp then
		stash.updateSerial =
			(tonumber(stash.updateSerial) or 0) + 1;
	else
		stash.updated = timestamp;
		stash.updateSerial = 0;
	end

	stash.lastEditor = self:GetPlayerName();
end

function GHU_Stash:GetNameChecksum(name)
	if not name then
		return 0;
	end

	name = string.lower(name);

	local checksum = 0;
	local i;
	local byte;

	for i = 1, string.len(name) do
		byte = string.byte(name, i);

		checksum = math.mod(
			checksum + (byte * i),
			100000
		);
	end

	return checksum;
end

function GHU_Stash:GetNextSyncRequestID()
	self.syncRequestSerial =
		(tonumber(self.syncRequestSerial) or 0) + 1;

	return self:GetPlayerName()
		.. "-"
		.. tostring(time())
		.. "-"
		.. tostring(self.syncRequestSerial);
end

function GHU_Stash:OpenGHIBackpack()
	if GHIContainerFrame1
		and not GHIContainerFrame1:IsShown() then

		GHIContainerFrame1:Show();
	end
end

function GHU_Stash:HandleAcceptedStash(stash)
	if not stash then
		return;
	end

	if stash.deleted then
		stash.items = nil;
	end

	if self.currentStash
		and self.currentStash.id == stash.id then

		if stash.deleted then
			if self.bagFrame
				and self.bagFrame:IsShown() then

				self:CloseBag();
			end

			self.currentStash = nil;

			self:AddMessage(
				"The hidden stash has been destroyed."
			);

			return;
		end

		self.currentStash = stash;

		if self.bagFrame
			and self.bagFrame:IsShown() then

			self:BindGHIContainer(stash);
			self:UpdateBag();
		end
	end
end

function GHU_Stash:OpenBag(stash)
	if not stash then
		return;
	end

	if stash.deleted then
		self:AddMessage(
			"The stash no longer exists."
		);
		return;
	end

	if not self:IsAtLocation(stash) then
		self:AddMessage("You are not close enough to the stash.");
		return;
	end

	if not stash.items then
		stash.items = {};
	end

	if not self.bagFrame then
		self:CreateBagFrame();
	end

	self.currentStash = stash;

    self:BindGHIContainer(stash);

	self.bagFrame.title:SetText("Hidden Stash");

	if stash.location then
		local locationName = stash.location.zoneName or "";

		if stash.location.subZoneName
			and stash.location.subZoneName ~= "" then

			locationName = locationName
				.. " - "
				.. stash.location.subZoneName;
		end

		self.bagFrame.locationText:SetText(locationName);
	else
		self.bagFrame.locationText:SetText("");
	end

	self:UpdateBag();

	self.bagFrame:Show();
end

function GHU_Stash:UpdateBag()
	if not self.bagFrame then
		return;
	end

	local i;
	local slot;
	local data;
	local ID;
	local name;
	local texture;
	local amount;
	local locked;

	for i = 1, table.getn(self.bagFrame.slots) do
		slot = self.bagFrame.slots[i];

		if slot then
			data = GHI_GetContainerInfo(
				self.GHIContainerID,
				i
			);

			if type(data) == "table" then
				ID = data.ID;
				name, texture = GHI_GetItemInfo(ID);

				amount = data.amount or 0;
				locked = data.locked;

				SetItemButtonTexture(slot, texture);
				SetItemButtonCount(slot, amount);
				SetItemButtonDesaturated(
					slot,
					locked,
					0.5,
					0.5,
					0.5
				);

				slot.ID = ID;
				slot.number = i;
				slot.count = amount;
				slot.hasItem = 1;
			else
				SetItemButtonTexture(slot, nil);
				SetItemButtonCount(slot, 0);
				SetItemButtonDesaturated(
					slot,
					nil,
					0.5,
					0.5,
					0.5
				);

				slot.ID = nil;
				slot.number = i;
				slot.count = 0;
				slot.hasItem = nil;
			end
		end
	end
end

function GHU_Stash:BindGHIContainer(stash)
	if not stash then
		return false;
	end

	if not stash.items then
		stash.items = {};
	end

	if not GHI_ContainerData then
		GHI_ContainerData = {};
	end

	GHI_ContainerData[self.GHIContainerID] = stash.items;

	if self.bagFrame then
		self.bagFrame:SetID(self.GHIContainerID);
	end

	return true;
end


function GHU_Stash:UnbindGHIContainer()
	local cursorType;
	local cursorDetails;

	if type(GHI_GetCursor) == "function" then
		cursorType, cursorDetails = GHI_GetCursor();

		-- Do not leave a stash item locked on the GHI cursor
		-- after the stash ceases to be available.
		if cursorType == "item"
			and cursorDetails
			and cursorDetails.ItemOrigBag == self.GHIContainerID then

			GHI_ResetCursor();
		end
	end

	if type(GHI_ContainerData) == "table" then
		GHI_ContainerData[self.GHIContainerID] = nil;
	end
end

function GHU_Stash:GetCurrentLocation()
	-- Remember the map the player currently has selected.
	local oldContinent = GetCurrentMapContinent();
	local oldZone = GetCurrentMapZone();

	-- Force the map API to the player's actual current zone.
	SetMapToCurrentZone();

	local continent = GetCurrentMapContinent();
	local zone = GetCurrentMapZone();
	local x, y = GetPlayerMapPosition("player");

	local zoneName = GetZoneText();
	local subZoneName = GetSubZoneText();

	-- Restore the previous map selection when possible.
	if oldContinent and oldContinent > 0 then
		SetMapZoom(oldContinent, oldZone);
	end

	-- 0,0 usually means that usable coordinates were not available.
	if not x or not y or (x == 0 and y == 0) then
		return nil;
	end

	return {
		continent = continent,
		zone = zone,
		zoneName = zoneName,
		subZoneName = subZoneName,
		x = x,
		y = y,
	};
end

function GHU_Stash:BuildZoneManifest(continent, zone)
	local manifest = {};
	local stashes =
		self:GetZoneStashes(continent, zone);

	local stashID;
	local stash;

	for stashID, stash in pairs(stashes) do
		manifest[stashID] = {
			updated = tonumber(stash.updated) or 0,
			updateSerial =
				tonumber(stash.updateSerial) or 0,
			lastEditor = stash.lastEditor or "",
			deleted = stash.deleted,
		};
	end

	return manifest;
end

function GHU_Stash:BuildZoneCycle()
	self.cycleZones = {};

	local continents = {
		GetMapContinents()
	};

	local continent;
	local zones;
	local zone;

	for continent = 1, table.getn(continents) do
		zones = {
			GetMapZones(continent)
		};

		for zone = 1, table.getn(zones) do
			table.insert(
				self.cycleZones,
				{
					continent = continent,
					zone = zone,
					zoneName = zones[zone],
				}
			);
		end
	end
end

function GHU_Stash:StartZoneCycle()
	if table.getn(self.cycleZones) == 0 then
		self:BuildZoneCycle();
	end

	self.cycleActive = true;
	self.cyclePaused = false;
	self.cycleIndex = 1;

	self:ContinueZoneCycle();
end

function GHU_Stash:ContinueZoneCycle()
	if not self.cycleActive
		or self.cyclePaused
		or self.prioritySyncPending
		or self.syncRequest then

		return;
	end

	local zone =
		self.cycleZones[self.cycleIndex];

	if not zone then
		self.cycleIndex = 1;
		zone = self.cycleZones[1];
	end

	if not zone then
		return;
	end

	self:BeginZoneReconciliation(
		zone.continent,
		zone.zone,
		"cycle"
	);
end

function GHU_Stash:FinishZoneReconciliation()
	local syncType = nil;

	if self.syncRequest then
		syncType = self.syncRequest.type;
	end

	self.syncRequest = nil;

	if self.prioritySyncPending then
		self:ScheduleZoneSync();
		return;
	end

	if syncType == "priority" then
		if not self.cycleActive then
			self:StartZoneCycle();
		else
			self.cyclePaused = false;
			self:ContinueZoneCycle();
		end

		return;
	end

	if syncType == "cycle" then
		self.cycleIndex = self.cycleIndex + 1;

		if self.cycleIndex >
			table.getn(self.cycleZones) then

			self.cycleIndex = 1;
		end

		self:ContinueZoneCycle();
	end
end

function GHU_Stash:BeginZoneReconciliation(
	continent,
	zone,
	syncType
)
	local requestID = self:GetNextSyncRequestID();

	self.syncRequest = {
		id = requestID,
		type = syncType,
		continent = continent,
		zone = zone,

		-- Best versions reported by everybody.
		best = {},

		-- Which players possess each best version.
		holders = {},

		started = GetTime(),
	};

	self:BroadcastManifestRequest(
		requestID,
		continent,
		zone
	);
end

function GHU_Stash:SynchronizeCurrentZone()
	if not self.prioritySyncPending
		or not self.priorityLocation then
		return;
	end

	local location = self.priorityLocation;

	self.prioritySyncPending = false;

	self:BeginZoneReconciliation(
		location.continent,
		location.zone,
		"priority"
	);
end

function GHU_Stash:CloseBag()
	self:UnbindGHIContainer();

	if self.bagFrame then
		self.bagFrame:Hide();
	end
end

function GHU_Stash:GetLocationID()
	local location = self:GetCurrentLocation();

	if not location then
		return nil;
	end

	return location.continent
		.. ":"
		.. location.zone
		.. ":"
		.. math.floor(location.x * 1000)
		.. ":"
		.. math.floor(location.y * 1000);
end


function GHU_Stash:IsAtLocation(stash, x, y)
	if not stash or not stash.location then
		return false;
	end

	local location = stash.location;

	-- If coordinates were not supplied, use the player's current position.
	if not x or not y then
		local currentLocation = self:GetCurrentLocation();

		if not currentLocation then
			return false;
		end

		-- A stash cannot be reached from a different continent or zone.
		if currentLocation.continent ~= location.continent then
			return false;
		end

		if currentLocation.zone ~= location.zone then
			return false;
		end

		x = currentLocation.x;
		y = currentLocation.y;
	end

	local xDistance = x - location.x;
	local yDistance = y - location.y;

	local distance = math.sqrt(
		(xDistance * xDistance)
		+
		(yDistance * yDistance)
	);

	return distance <= self.locationTolerance;
end


function GHU_Stash:FindNearbyStashes(currentLocation)
	local found = {};
	local seen = {};

	local sources = {
		self.stashes,
		self.replicaStashes,
	};

	local sourceIndex;
	local source;
	local stashID;
	local stash;

	for sourceIndex = 1, table.getn(sources) do
		source = sources[sourceIndex];

		for stashID, stash in pairs(source or {}) do
			if not seen[stashID]
				and not stash.deleted
				and stash.location
				and stash.location.continent == currentLocation.continent
				and stash.location.zone == currentLocation.zone then

				local xDistance =
					currentLocation.x - stash.location.x;

				local yDistance =
					currentLocation.y - stash.location.y;

				local distance = math.sqrt(
					(xDistance * xDistance)
					+
					(yDistance * yDistance)
				);

				if distance <= self.searchTolerance then
					table.insert(found, {
						stash = stash,
						distance = distance,
					});

					seen[stashID] = true;
				end
			end
		end
	end

	return found;
end


function GHU_Stash:ShowSearchResults(found)
	local i;
	local result;

	if not found or table.getn(found) == 0 then
		self:AddMessage("You find no signs of a hidden stash.");
		return;
	end

	for i = 1, table.getn(found) do
		result = found[i];

        if result.distance <= self.locationTolerance then
	        self:AddMessage("You discover a hidden stash.");
	        self.currentStash = result.stash;
	        self:OpenBag(result.stash);
		else
			self:AddMessage("You notice signs that something may be hidden nearby.");
		end
	end
end

function GHU_Stash:CreateStash()
	local location = self:GetCurrentLocation();

	if not location then
		self:AddMessage("You cannot create a stash here.");
		return;
	end

	local playerName = self:GetPlayerName();

	if not playerName then
		self:AddMessage("Unable to determine stash creator.");
		return;
	end

    local stashID = self:GenerateStashID(location);

    if not stashID then
	    self:AddMessage("Unable to generate a stash ID.");
	    return;
    end

    local timestamp = time();

    local stash = {
	    id = stashID,
	    creator = playerName,
	    creatorChecksum = self:GetNameChecksum(playerName),

	    created = timestamp,
	    updated = timestamp,
	    updateSerial = 0,
	    lastEditor = playerName,

	    location = {
		    continent = location.continent,
		    zone = location.zone,
		    zoneName = location.zoneName,
		    subZoneName = location.subZoneName,
		    x = location.x,
		    y = location.y,
	    },

	    items = {},
    };

    self.stashes[stashID] = stash;
    self.currentStash = stash;

    self:PublishStash(stash);

    self:AddMessage("You create a hidden stash.");

    -- Open both inventories so the player can immediately
    -- place GHI items into the new stash.
    self:OpenGHIBackpack();
    self:OpenBag(stash);
end

function GHU_Stash:RequestStashData(
	stashID,
	version,
	source
)
	if not stashID
		or not version
		or not source then

		return false;
	end

	return self:SendTransport(
		"SREQ",
		{
			stashID = stashID,
			version = version,
			source = source,
		}
	);
end

function GHU_Stash:ReceiveStashDataRequest(
	sender,
	payload
)
	if type(payload) ~= "table" then
		return;
	end

	if string.lower(
		payload.source or ""
	) ~= string.lower(
		self:GetPlayerName() or ""
	) then

		return;
	end

	local stash =
		self:GetBestStash(
			payload.stashID
		);

	if not stash then
		return;
	end

	local requested =
		payload.version;

	if type(requested) ~= "table" then
		return;
	end

	-- We may have exactly the requested version
	-- or something even newer.
	if self:IsSameStashVersion(
		stash,
		requested
	)
		or self:IsNewerStash(
			stash,
			requested
		) then

		self:PublishStash(stash);
	end
end

function GHU_Stash:DestroyStash()
	local stash = self.currentStash;

	if not stash then
		self:AddMessage(
			"You have not discovered a stash to destroy."
		);
		return;
	end

	if stash.deleted then
		self:AddMessage(
			"The stash no longer exists."
		);
		self.currentStash = nil;
		return;
	end

	if not self:IsAtLocation(stash) then
		self:AddMessage(
			"You are not close enough to the stash."
		);
		return;
	end

	-- For now, preserve the existing rule that the stash
	-- must belong to our original-stash collection.
	if not stash.id or not self.stashes[stash.id] then
		self:AddMessage(
			"The stash no longer exists."
		);
		self.currentStash = nil;
		return;
	end

	-- Close first so an item cannot remain attached
	-- to the cursor/container while the contents vanish.
	if self.bagFrame
		and self.bagFrame:IsShown() then

		self:CloseBag();
	end

	self:TombstoneStash(stash);

	-- IMPORTANT:
	-- Do NOT remove self.stashes[stash.id].
	-- The tombstone must remain permanently available
	-- for synchronization.
	self:PublishStash(stash);

	self.currentStash = nil;

	self:AddMessage(
		"You destroy the hidden stash."
	);
end

function GHU_Stash:HookGHI()
	if not self.hooked.GHI_UpdateContainers
		and type(GHI_UpdateContainers) == "function" then

		self.hooked.GHI_UpdateContainers = GHI_UpdateContainers;

		GHI_UpdateContainers = function()
			GHU_Stash.hooked.GHI_UpdateContainers();

			if GHU_Stash.bagFrame
				and GHU_Stash.bagFrame:IsShown() then

				GHU_Stash:UpdateBag();
			end
		end
	end


	if not self.hooked.GHI_PlaceContainerItem
		and type(GHI_PlaceContainerItem) == "function" then

		self.hooked.GHI_PlaceContainerItem =
			GHI_PlaceContainerItem;

		GHI_PlaceContainerItem = function(frame)
			local targetBag = nil;
			local originBag = nil;

			if frame and frame:GetParent() then
				targetBag = frame:GetParent():GetID();
			end

			if type(GHI_GetCursor) == "function" then
				local cursorType;
				local details;

				cursorType, details = GHI_GetCursor();

				if cursorType == "item" and details then
					originBag = details.ItemOrigBag;
				end
			end

			GHU_Stash.hooked.GHI_PlaceContainerItem(frame);

			if targetBag == GHU_Stash.GHIContainerID
				or originBag == GHU_Stash.GHIContainerID then

				if GHU_Stash.currentStash then
					GHU_Stash:TouchStash(
						GHU_Stash.currentStash
					);

					GHU_Stash:PublishStash(
						GHU_Stash.currentStash
					);
				end
			end
		end
	end
end


function GHU_Stash:Search()
	local location = self:GetCurrentLocation();

	if not location then
		self:AddMessage("You cannot search for a stash here.");
		return;
	end

	if self.bagFrame and self.bagFrame:IsShown() then
		self:CloseBag();
	end

	self.currentStash = nil;

	local found = self:FindNearbyStashes(location);

	if found and table.getn(found) > 0 then
		self:ShowSearchResults(found);
		return;
	end

	self:AddMessage("You find no signs of a hidden stash.");
end

GHU_Stash:SetScript("OnEvent", function()
	if event == "VARIABLES_LOADED" then
		GHU_Stash:Init();

	elseif event == "PLAYER_ENTERING_WORLD" then
		GHU_Stash:JoinStashChannel();
		GHU_Stash:EnterCurrentZone();

	elseif event == "ZONE_CHANGED_NEW_AREA" then
		GHU_Stash:EnterCurrentZone();

    elseif event == "CHAT_MSG_CHANNEL" then
	    GHU_Stash:ReceiveChannelChat(
		    arg1,
		    arg2,
		    arg4,
		    arg8,
		    arg9
	    );

	elseif event == "PLAYER_LOGOUT" then
		GHU_Stash:UnbindGHIContainer();
	end
end);

GHU_Stash:SetScript("OnUpdate", function()
	GHU_Stash:Update(arg1);
end);


SLASH_GHUSTASH1 = "/stash";

SlashCmdList["GHUSTASH"] = function(msg)
	if msg == "search" then
		GHU_Stash:Search();

	elseif msg == "create" then
		GHU_Stash:CreateStash();

	elseif msg == "destroy" then
		GHU_Stash:DestroyStash();

	elseif msg == "open" then
		if GHU_Stash.currentStash then
			GHU_Stash:OpenBag(GHU_Stash.currentStash);
		else
			GHU_Stash:AddMessage("You have not discovered a stash.");
		end

	else
		GHU_Stash:AddMessage(
			"Stash commands: /stash create, /stash search, /stash open, /stash destroy"
		);
	end
end

GHU_Stash:OnLoad();
