GHU_Stash = CreateFrame("frame");
GHU_Stash.__index = GHU_Stash;
GHU_Stash.hooked = {};

GHU_Stash.currentStash = nil;

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

	if not GHU_StashData.nextStashID then
		GHU_StashData.nextStashID = 1;
	end

	self.stashes = GHU_StashData.stashes;
end


function GHU_Stash:OnLoad()
	-- SavedVariables and communication hooks can be initialized here later.
end


function GHU_Stash:GetPlayerName()
	return UnitName("player");
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

			frame.slots[slotNumber] = slot;

			slotNumber = slotNumber + 1;
		end
	end

	self.bagFrame = frame;
end

function GHU_Stash:OpenBag(stash)
	if not stash then
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

	for i = 1, table.getn(self.bagFrame.slots) do
		slot = self.bagFrame.slots[i];

		if slot then
			SetItemButtonTexture(slot, nil);
			SetItemButtonCount(slot, 0);
		end
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
	local stash;

	if not self.stashes then
		return found;
	end

	for _, stash in pairs(self.stashes) do
		if stash.location
			and stash.location.continent == currentLocation.continent
			and stash.location.zone == currentLocation.zone then

			local xDistance = currentLocation.x - stash.location.x;
			local yDistance = currentLocation.y - stash.location.y;

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


function GHU_Stash:Search()
	local location = self:GetCurrentLocation();

	if not location then
		self:AddMessage("You cannot search for a stash here.");
		return;
	end

	local found = self:FindNearbyStashes(location);

	if found and table.getn(found) > 0 then
		self:ShowSearchResults(found);
		return;
	end

	self:AddMessage("You find no signs of a hidden stash.");
end


GHU_Stash:RegisterEvent("VARIABLES_LOADED");

GHU_Stash:SetScript("OnEvent", function()
	if event == "VARIABLES_LOADED" then
		GHU_Stash:Init();
	end
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

	local serial = GHU_StashData.nextStashID;

	GHU_StashData.nextStashID = serial + 1;

	local stashID = playerName .. ":" .. tostring(serial);

    local stash = {
	    id = stashID,
	    creator = playerName,
	    revision = 1,

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

	self:AddMessage("You create a hidden stash.");
end

function GHU_Stash:DestroyStash()
	local stash = self.currentStash;

	if not stash then
		self:AddMessage("You have not discovered a stash to destroy.");
		return;
	end

	if not self:IsAtLocation(stash) then
		self:AddMessage("You are not close enough to the stash.");
		return;
	end

	if not stash.id or not self.stashes[stash.id] then
		self:AddMessage("The stash no longer exists.");
		self.currentStash = nil;
		return;
	end

	self.stashes[stash.id] = nil;

    if self.bagFrame then
	    self.bagFrame:Hide();
    end

	self.currentStash = nil;

	self:AddMessage("You destroy the hidden stash.");
end


function GHU_Stash:Search()
	local location = self:GetCurrentLocation();

	if not location then
		self:AddMessage("You cannot search for a stash here.");
		return;
	end

	self.currentStash = nil;

	local found = self:FindNearbyStashes(location);

	if found and table.getn(found) > 0 then
		self:ShowSearchResults(found);
		return;
	end

	self:AddMessage("You find no signs of a hidden stash.");
end
