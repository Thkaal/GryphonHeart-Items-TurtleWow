

local supportedUnits = {"player","target"};

-- WoW 1.12/TurtleWoW does not expose several later BuffFrame globals
-- that this GHU code inherited from newer Blizzard FrameXML.  Keep the
-- limits local to GHU instead of polluting Blizzard globals.
local GHU_BUFF_MAX_DISPLAY = tonumber(BUFF_MAX_DISPLAY) or 32;
local GHU_DEBUFF_MAX_DISPLAY = tonumber(DEBUFF_MAX_DISPLAY) or 16;
local GHU_BUFFS_PER_ROW = tonumber(BUFFS_PER_ROW) or 8;
local GHU_BUFF_ROW_SPACING = tonumber(BUFF_ROW_SPACING) or 15;

-- WoW 1.12 aura templates expose their child FontStrings as named globals
-- rather than as button.duration/button.count table fields.  Keep our own
-- references and update timer text without relying on the later
-- AuraButton_OnUpdate helper.
local function GHU_AuraButton_OnUpdate()
	local buff = this;
	if not buff or type(buff.timeLeft) ~= "number" then return; end
	buff.timeLeft = buff.timeLeft - (arg1 or 0);
	if buff.timeLeft <= 0 then
		buff.timeLeft = nil;
		buff:SetScript("OnUpdate", nil);
		if buff.duration then buff.duration:Hide(); end
		return;
	end
	if buff.duration then
		local text;
		if SecondsToTimeAbbrev then
			text = SecondsToTimeAbbrev(buff.timeLeft);
		else
			local seconds = math.floor(buff.timeLeft + 0.5);
			if seconds >= 3600 then
				text = math.floor(seconds / 3600).."h";
			elseif seconds >= 60 then
				text = math.floor(seconds / 60).."m";
			else
				text = seconds.."s";
			end
		end
		buff.duration:SetText(text or "");
	end
end

GHU_BuffDisplay = CreateFrame("frame");
GHU_BuffDisplay.buffs = {};
GHU_BuffDisplay.buffObjs = {};
GHU_BuffDisplay.debuffs = {};
GHU_BuffDisplay.nextUpdate = {};
GHU_BuffDisplay.initialized = false;


function GHU_BuffDisplay:OnEvent(event,arg1,arg2)
	if event == "PLAYER_TARGET_CHANGED" then
		self:UpdateDB("target");
	end
	
end

GHU_BuffDisplay:SetScript("OnEvent", function() GHU_BuffDisplay:OnEvent(event,arg1,arg2); end);
GHU_BuffDisplay:RegisterEvent("PLAYER_TARGET_CHANGED");

function GHU_BuffDisplay:RegisterBuffObj(buffObj)
	-- The original 3.x-era source used the type of buffObjs as its one-time
	-- initialization sentinel even though buffObjs is already initialized to {}.
	-- That made this block unreachable. Use an explicit flag on Vanilla.
	if not self.initialized then
		self.initialized = true;
		self.buffObjs = self.buffObjs or {};
		self.buffFrames = {};
		self.buffs = {};
		self.debuffs = {};
		self.nextUpdate = {};
		-- GHU draws its own aura frames; no secure post-hook of Blizzard's
		-- BuffFrame_Update is required on WoW 1.12. Expirations are handled
		-- by CheckUpdate through the GHU timer loop.
		GHU_RegTimer(self,self.CheckUpdate);
	end
	table.insert(self.buffObjs,buffObj);
	return self;
end

function GHU_BuffDisplay:GetBuffs(unit,filter) -- returns table with buff info
	if filter == 1 then
		return self.buffs[unit] or {};
	elseif filter == 2 then
		return self.debuffs[unit] or {};
	end
	return {};
end

function GHU_BuffDisplay:GetNumberBuffs(unit,filter)
	return table.getn(self:GetBuffs(unit,filter));
end

function GHU_BuffDisplay:CheckUpdate()
	for unit,upTime in pairs(self.nextUpdate) do
		if type(upTime)=="number" and upTime <= GetTime() then
			self:UpdateDB(unit);
			break;
		end
	end
end

function GHU_BuffDisplay:UpdateDB(unit) -- remember to call this on target change etc.
	local guid = UnitGUID(unit);
	local nextUp
	--print("Update buff db for",unit);
	
	self.buffs = self.buffs or {};
	
	-- update buffs
	self.buffs[unit] = {};
	--print(table.getn(self.buffObjs),"buff objs");
	for i,buffObj in pairs(self.buffObjs) do
		local res = buffObj:GetBuffs(guid,1);
		
		if type(res) == "table" then
			--print(table.getn(res),"in buff obj",i);
			for _,b in pairs(res) do
				
				b.buffObj = buffObj; -- Is this used? Maybe when clicking
				
				if b.expirationTime and not(b.expirationTime == 0) and b.expirationTime <= GetTime() then
					-- remove buff
					buffObj:RemoveBuff(b.refID,UnitGUID(unit),0);
					return;
				else
					if b.expirationTime then
						if not(nextUp) or (nextUp > b.expirationTime and b.expirationTime > GetTime()) then
							nextUp = b.expirationTime;
						end
					end
					table.insert(self.buffs[unit],b);
				end
			end
		end
	end
	
	--print(table.getn(self.buffs[unit]),"buffs");
	-- update debuffs
	self.debuffs[unit] = {};
	for _,buffObj in pairs(self.buffObjs) do
		local res = buffObj:GetBuffs(guid,2);
		if type(res) == "table" then
			for _,b in pairs(res) do
				b.buffObj = buffObj;
				if b.expirationTime and b.expirationTime <= GetTime() then
					-- remove buff
					buffObj:RemoveBuff(b.refID,UnitGUID(unit),0);
					return;
				else
					if b.expirationTime then
						if not(nextUp) or (nextUp > b.expirationTime and b.expirationTime > GetTime()) then
							nextUp = b.expirationTime;
						end
					end
					table.insert(self.debuffs[unit],b);
				end
			end
		end
	end
	
	self.nextUpdate[unit] = nextUp;
	
	-- call update func
	if (unit == "player") then
	 	GHU_BuffFrame_Update()
	elseif (unit == "target") then
		GHU_BuffFrame_Update()
	end
end

function GHU_BuffDisplay:FindBuff(unit,refID)
	local t1 = self:GetBuffs(unit,1);
	for _,b in pairs(t1) do
		if b.refID == refID then return b; end;
	end
	
	local t2 = self:GetBuffs(unit,2);
	for _,b in pairs(t2) do
		if b.refID == refID then return b; end;
	end
	
	return {};
end

function GHU_BuffDisplay:DisplayTooltip(button)
	local unit = button.unit;
	local refID = button.refID;
	if not(unit and refID) then return end;
	local buff = self:FindBuff(unit,refID);
	if not(buff) then return end;
	
	if button:GetCenter() > UIParent:GetWidth() / 2 then
		GameTooltip:SetOwner(button, "ANCHOR_BOTTOMLEFT", 0,0);
	else
		GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT", 15,-25);
	end
	GameTooltip:ClearLines(); 
	GameTooltip:AddLine(buff.name or "",1,0.8196079,0);  
	GameTooltip:AddLine(buff.description or "",1,1,1,1,1);  
	
	if buff.expirationTime > 0 then
		local s1 = format(SecondsToTimeAbbrev(buff.expirationTime-GetTime())); 
		local n,suffix = strsplit(" ",string.match(s1,"%d* %a") or "")
		n = tonumber(n);
		
		local s2 = "";
		if suffix=="s" then s2 = SPELL_TIME_REMAINING_SEC; end
		if suffix=="m" then s2 = SPELL_TIME_REMAINING_MIN; end
		if suffix=="h" then s2 = SPELL_TIME_REMAINING_HOURS; end
		if suffix=="d" then s2 = SPELL_TIME_REMAINING_DAYS; end
		GameTooltip:AddLine(format(s2,n),1,0.8196079,0);  
	end
	
	GameTooltip:Show();
	
end

-- ================================================================
-- Buff functions. Copied from Blizzard code and modified
-- ================================================================



local GHU_BuffFrames = {};

-- v41: keep target GHU auras attached to the actual target frame.
-- Player GHU auras remain freely movable.
local function GHU_PositionTargetBuffFrame()
	local frame = GHU_BuffFrames["target"];
	if not frame or not TargetFrame then return; end
	frame:ClearAllPoints();
	frame:SetPoint("TOPLEFT", TargetFrame, "BOTTOMLEFT", 5, 0);
end

function GHU_BuffResetAllPositions()
	local x,y = UIParent:GetWidth()/2,UIParent:GetHeight()/2;
	
	
	for _,unit in pairs(supportedUnits) do
		if unit == "target" then
			GHU_PositionTargetBuffFrame();
		else
			Set(GHU_MiscData,"BuffPos",unit,1,x);
			Set(GHU_MiscData,"BuffPos",unit,2,y);
			if GHU_BuffFrames[unit] then
				GHU_BuffFrames[unit]:ClearAllPoints();
				GHU_BuffFrames[unit]:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", x, y);
			end
		end
	end
end

function GHU_BuffIconButtonIconMove(self)
	if self and self.main and self.main.unit == "target" then
		GHU_PositionTargetBuffFrame();
		return;
	end
	if (not self.iconDrag and not iconpos) then
		return;
	end
	
	local xpos, ypos;
	
	if (iconpos) then 
		xpos = iconpos[1];
		ypos = iconpos[2];
	end
	
	if (not xpos and not ypos) then
		local x, y = GetCursorPosition();
		local s = self.main:GetEffectiveScale();
		
		xpos, ypos = x/s, y/s;
		
	end
	
	--GHU_MiscData = GHU_MiscData or {};
	Set(GHU_MiscData,"BuffPos",self.main.unit,{xpos+(self:GetWidth()/2), ypos-(self:GetHeight()/2)});
	
	-- Hide the tooltip
	GameTooltip:Hide();
	
	-- Set the position
		
	self.main:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", xpos+(self:GetWidth()/2), ypos-(self:GetHeight()/2));
end

-- ************ 		Player Buff frame		************
function GHU_BuffFrame_OnEnter(unit)
	if GHU_BuffFrames[unit] then
		GHU_BuffFrames[unit].button:Show();
	end
end
function GHU_BuffFrame_OnLeave(unit)
	if GHU_BuffFrames[unit] and not(GHU_BuffFrames[unit].button.iconDrag) then
		GHU_BuffFrames[unit].button:Hide();
	end
end

function GHU_BuffFrame_Update()
	for _,unit in pairs(supportedUnits) do if Get then
		-- Create new frames
		if not(GHU_BuffFrames[unit]) then 
			local f = CreateFrame("Button",nil,UIParent);
			--GHU_BuffFrame:SetPoint("TOPRIGHT", BuffFrame, "TOPRIGHT", 0, 40);
			
			local x = Get(GHU_MiscData,"BuffPos",unit,1) or UIParent:GetWidth()/2;
			local y = Get(GHU_MiscData,"BuffPos",unit,2) or UIParent:GetHeight()/2;
			--print("x: ",x," y: ",y);
			
			if unit == "target" and TargetFrame then
				f:SetPoint("TOPLEFT", TargetFrame, "BOTTOMLEFT", 5, 0);
			else
				f:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", x, y);
			end
			f:Show();
			
			f:SetFrameStrata("BACKGROUND")
			f:SetWidth(90)--*BUFFS_PER_ROW) 
			f:SetHeight(32)
			
			--f:SetScript("OnEnter",GHU_BuffFrame_OnEnter);
			f:SetScript("OnEnter",function() GHU_BuffFrame_OnEnter(this.unit); end);
			f:SetScript("OnLeave",function() GHU_BuffFrame_OnLeave(this.unit); end);
			
			
			local b = CreateFrame("Button",nil,f);	
			b:SetWidth(100)
			b:SetHeight(40);
			local t = b:CreateTexture(nil,"BACKGROUND")
			t:SetTexture("Interface\\CHATFRAME\\ChatFrameTab.blp")
			t:SetAllPoints(b)
			b.texture = t;
			b:SetPoint("BOTTOMRIGHT",f,"TOPRIGHT",10,-1);
			b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			b:SetScript("OnUpdate", function() GHU_BuffIconButtonIconMove(this); end)
			b:SetScript("OnDragStart", function() this.iconDrag = true; end)
			b:SetScript("OnDragStop", function() this.iconDrag = false; end)
			b:RegisterForDrag("LeftButton")
			b:SetMovable();
			b:Hide();
			
			local pf = b:CreateFontString();
			pf:SetFontObject("GameFontNormalSmall");
			pf:SetText("GH Buffs");
			pf:SetPoint("CENTER",0,0,b);
			
			local pf2 = b:CreateFontString();
			pf2:SetFontObject("GameFontHighlightSmall");
			pf2:SetText(strsub(strupper(unit),0,1)..strsub(strlower(unit),2));
			pf2:SetPoint("CENTER",0,-10,b);
					
			b:SetScript("OnEnter",function() GHU_BuffFrame_OnEnter(b.main.unit) end);
			b:SetScript("OnLeave",function() GHU_BuffFrame_OnLeave(b.main.unit) end);
			b.main = f
			
			f.unit = unit
			f.button = b;
			GHU_BuffFrames[unit] = f;
			if unit == "target" then
				GHU_PositionTargetBuffFrame();
			end
			
			-- Set position depending on load data
			
			--[[
			local t = GHU_BuffFrame:CreateTexture(nil,"BACKGROUND")
			t:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp")
			t:SetAllPoints(GHU_BuffFrame)
			GHU_BuffFrame.texture = t --]]

			--print("buff frame created");
		end
		
		if not(UnitExists(unit)) then
			GHU_BuffFrames[unit]:Hide();
			return;
		else
			if unit == "target" then
				GHU_PositionTargetBuffFrame();
			end
			GHU_BuffFrames[unit]:Show();
		end
		
		-- Handle Buffs
		-- hide those not in use
		--[[
		for i=1,BUFF_ACTUAL_DISPLAY do
			local b = getglobal("GHU_BuffButton"..i);
			if b then
				b:Hide();
				b.duration:Hide();
			end
		end--]]
		
		--for i=BUFF_ACTUAL_DISPLAY+1, BUFF_MAX_DISPLAY do
		for i=1, GHU_BUFF_MAX_DISPLAY do
			if ( GHU_AuraButton_Update("GHU_BuffButton", i, "HELPFUL",unit) ) then
				--BUFF_ACTUAL_DISPLAY = BUFF_ACTUAL_DISPLAY + 1;
			end
		end
		
		GHU_BuffFrame_UpdateAllBuffAnchors(unit);
		
		-- Handle debuffs
		--[[
		for i=1,DEBUFF_ACTUAL_DISPLAY do
			local b = getglobal("GHU_DebuffButton"..i);
			if b then
				b:Hide();
				b.duration:Hide();
			end
		end--]]
		
		--for i=DEBUFF_ACTUAL_DISPLAY+1, DEBUFF_MAX_DISPLAY do
		for i=1, GHU_DEBUFF_MAX_DISPLAY do
			if ( GHU_AuraButton_Update("GHU_DebuffButton", i, "HARMFUL",unit) ) then
				--DEBUFF_ACTUAL_DISPLAY = DEBUFF_ACTUAL_DISPLAY + 1;
			end
		end
		
		GHU_BuffFrame_UpdateAllDebuffAnchors(unit);
	end end
end

function GHU_AuraButton_Update(buttonName, index, filter,unit)
	self = GHU_BuffDisplay;
	
	local name, rank, texture, count, debuffType, duration, expirationTime, _, _, shouldConsolidate;-- = UnitAura(unit, index, filter);
	local refID,buffObj;

	local done;
	
	--if filter == "HELPFUL" and index > BUFF_ACTUAL_DISPLAY and index <= BUFF_ACTUAL_DISPLAY+ self:GetNumberBuffs("player",1) then
	if filter == "HELPFUL" and index <= self:GetNumberBuffs(unit,1) then
		--local t = self:GetBuffs("player",1)[index-BUFF_ACTUAL_DISPLAY];
		local t = self:GetBuffs(unit,1)[index];
		
		if type(t)=="table" then
			name = t.name or "";
			rank = t.rank or 0;
			texture = t.icon or "Interface\\Icons\\Ability_Marksmanship";
			duration = t.totalDuration or 0;
			expirationTime = t.expirationTime;
			count = t.count or 1;
			refID = t.refID;
			buffObj = t.buffObj;
		else
			name = "";
			count = 0;
			duration = 0;
			texture = "Interface\\Icons\\Ability_Marksmanship";
		end
	--elseif filter == "HARMFUL" and index > DEBUFF_ACTUAL_DISPLAY and index <= DEBUFF_ACTUAL_DISPLAY+ self:GetNumberBuffs("player",2) then
	elseif filter == "HARMFUL" and index <= self:GetNumberBuffs(unit,2) then
		local t = self:GetBuffs(unit,2)[index];
		if type(t)=="table" then
			name = t.name or "";
			rank = t.rank or 0;
			texture = t.icon or "Interface\\Icons\\Ability_Marksmanship";
			duration = t.totalDuration or 0;
			expirationTime = t.expirationTime;
			count = t.count or 1;
			debuffType = t.debuffType or "";
			refID = t.refID;
			buffObj = t.buffObj;
		else
			name = "";
			count = 0;
			duration = 0;
			texture = "Interface\\Icons\\Ability_Marksmanship";
		end
	end
		
	

	local buffName = buttonName..unit..index;
	local buff = getglobal(buffName);

	if ( not name ) then
		-- No buff so hide it if it exists
		if ( buff ) then
			buff:Hide();
			if unit == "player" and buff.duration then
				buff.duration:Hide();
			end
			buff.refID = nil;
		end
		return nil;
	else
		local helpful = (filter == "HELPFUL");
		
		-- If button doesn't exist make it
		if ( not buff ) then
			if ( helpful ) then
				buff = CreateFrame("Button", buffName, GHU_BuffFrames[unit], "BuffButtonTemplate");
				if not(unit == "player") then
					buff:SetHeight(17);
					buff:SetWidth(17);
				end
			else
				buff = CreateFrame("Button", buffName, GHU_BuffFrames[unit], "DebuffButtonTemplate");
				if not(unit == "player") then
					buff:SetHeight(17);
					buff:SetWidth(17);
				end
			end
			
			--print(unit,helpful,buff:GetHeight());
			
			buff.parent = GHU_BuffFrames[unit];
			buff.unit = unit;
			
			buff:SetScript("OnEnter",function()
					GameTooltip:SetOwner(buff, "ANCHOR_BOTTOMRIGHT");
					GameTooltip:SetFrameLevel(buff:GetFrameLevel() + 2);
					GHU_BuffDisplay:DisplayTooltip(buff);
					GHU_BuffFrame_OnEnter(buff.unit);
			end);
			buff:SetScript("OnLeave",function()
					GameTooltip:Hide();
					GHU_BuffFrame_OnLeave(buff.unit);
			end);
			buff:SetScript("OnUpdate",function()
					if ( GameTooltip:IsOwned(buff) ) then
						GHU_BuffDisplay:DisplayTooltip(buff);
					end
			end);
			
			if (helpful ) then
				buff:SetScript("OnClick",function()
					if type(buff.buffObj)=="table" then
						buff.buffObj:RemoveBuff(buff.refID,UnitGUID(buff.unit),1);
					end
				end);
			end
		end

		-- Vanilla/Turtle 1.12 templates create named child FontStrings but do
		-- not expose them as fields on the button as later FrameXML does.
		if unit == "player" then
			if not buff.duration then
				buff.duration = getglobal(buffName.."Duration");
				if not buff.duration then
					buff.duration = buff:CreateFontString(nil,"OVERLAY");
					buff.duration:SetFontObject("GameFontHighlightSmall");
					buff.duration:SetPoint("TOP",buff,"BOTTOM",0,0);
				end
			end
			if not buff.count then
				buff.count = getglobal(buffName.."Count");
				if not buff.count then
					buff.count = buff:CreateFontString(nil,"OVERLAY");
					buff.count:SetFontObject("NumberFontNormal");
					buff.count:SetPoint("BOTTOMRIGHT",buff,"BOTTOMRIGHT",-1,1);
				end
			end
		end
		
		-- Setup Buff
		buff.refID = refID;
		buff.buffObj = buffObj;
		
		buff:SetID(index);
		buff.unit = unit;
		buff.filter = filter;
		buff:SetAlpha(1.0);
		buff.exitTime = nil;
		buff.consolidated = nil;
		buff:Show();
		
		-- Set filter-specific attributes
		if ( not helpful ) then
			-- Anchor Debuffs
			--DebuffButton_UpdateAnchors(buttonName, index);

			-- Set color of debuff border based on dispel class.
			local debuffSlot = getglobal(buffName.."Border");
			if ( debuffSlot ) then
				local color;
				if ( debuffType ) then
					color = DebuffTypeColor[debuffType];
					if ( ENABLE_COLORBLIND_MODE == "1" ) then
						--buff.symbol:Show();
						--buff.symbol:SetText(DebuffTypeSymbol[debuffType] or "");
					else
						--buff.symbol:Hide();
					end
				else
					--buff.symbol:Hide();
					color = DebuffTypeColor["none"];
				end
				debuffSlot:SetVertexColor(color.r, color.g, color.b);
			end
		end
		
		if unit == "player" then
			if ( duration > 0 and expirationTime ) then
				if ( SHOW_BUFF_DURATIONS == "1" ) then
					buff.duration:Show();
				else
					buff.duration:Hide();
				end
				
				if ( not buff.timeLeft ) then
					buff.timeLeft = expirationTime - GetTime();
					buff:SetScript("OnUpdate", GHU_AuraButton_OnUpdate);
				else
					buff.timeLeft = expirationTime - GetTime();
				end
			else
				if buff.duration then buff.duration:Hide(); end
				if ( buff.timeLeft ) then
					buff:SetScript("OnUpdate", nil);
				end
				buff.timeLeft = nil;
			end
			
			-- Set the number of applications of an aura
			if ( count > 1 ) then
				buff.count:SetText(count);
				buff.count:Show();
			else
				buff.count:Hide();
			end
		else
			-- Handle cooldowns. TargetBuffFrameTemplate on 1.12 may not
			-- provide a Cooldown child, so treat it as optional.
			local frameCooldown = getglobal(buffName.."Cooldown");
			if frameCooldown then
				if ( duration > 0 and expirationTime ) then
					frameCooldown:Show();
					CooldownFrame_SetTimer(frameCooldown, expirationTime - duration, duration, 1);
				else
					frameCooldown:Hide();
				end
			end
		end 	
		-- Set Texture
		local icon = getglobal(buffName.."Icon");
		icon:SetTexture(texture);

		

		-- Refresh tooltip
		if ( GameTooltip:IsOwned(buff) ) then
			--GameTooltip:SetUnitAura(PlayerFrame.unit, index, filter);
			--todo: game tooltip
			self:DisplayTooltip(buff);
		end

		if ( CONSOLIDATE_BUFFS == "1" and shouldConsolidate ) then
			if ( buff.timeLeft and duration > 30 ) then
				buff.exitTime = expirationTime - max(10, duration / 10);
			end
			buff.expirationTime = expirationTime;			
			buff.consolidated = true;
			table.insert(consolidatedBuffs, buff);
		end
	end
	return 1;
end

function GHU_BuffFrame_UpdateAllBuffAnchors(unit)
	self = GHU_BuffDisplay;
	local buff, previousBuff, aboveBuff;
	local numBuffs = 0;
	local slack = 0;
	
	
	
	numBuffs = 0;
	
	--print("Unit:",unit);
	for i = 1, self:GetNumberBuffs(unit,1) do
		local buff = getglobal("GHU_BuffButton"..unit..i);
		
		numBuffs = numBuffs + 1;
		index = numBuffs + slack;
		if ( buff.parent ~= GHU_BuffFrames[unit] ) then
			buff.count:SetFontObject(NumberFontNormal);
			buff:SetParent(GHU_BuffFrames[unit]);
			buff.parent = GHU_BuffFrames[unit];
		end
		buff:ClearAllPoints();
		if ( (index > 1) and (mod(index, GHU_BUFFS_PER_ROW) == 1) ) and false then
			-- New row
			if ( index == GHU_BUFFS_PER_ROW+1 ) then
				buff:SetPoint("TOP", ConsolidatedBuffs, "BOTTOM", 0, -GHU_BUFF_ROW_SPACING);
			else
				buff:SetPoint("TOP", aboveBuff, "BOTTOM", 0, -GHU_BUFF_ROW_SPACING);
			end
			aboveBuff = buff;
		elseif ( index == 1 ) then --print("Set first");
			if unit == "player" then 
				buff:SetPoint("TOPRIGHT", GHU_BuffFrames[unit], "TOPRIGHT", 0, -2);
			else
				buff:SetPoint("TOPLEFT", GHU_BuffFrames[unit], "TOPLEFT", 0, -2);
			end
		else
			
			if unit == "player" then
				buff:SetPoint("RIGHT", previousBuff, "LEFT", -5, 0);
			else
				buff:SetPoint("LEFT", previousBuff, "RIGHT", 0, 0);
			end
		end
		previousBuff = buff;
		
	end

end

function GHU_BuffFrame_UpdateAllDebuffAnchors(unit)
	local numBuffs = 0; 
	self = GHU_BuffDisplay;
	
	local rows = ceil((numBuffs + self:GetNumberBuffs(unit,2))/GHU_BUFFS_PER_ROW);
	local buff;
	local buffHeight = TempEnchant1:GetHeight();
	local buttonName = "GHU_DebuffButton"..unit;
	
	
	numBuffs = 0
	-- todo: Set the anchors correct
	for index = 1, self:GetNumberBuffs(unit,2) do
		buff = getglobal(buttonName..index);
		-- Position debuffs
		if ( (index > 1) and (mod(index, GHU_BUFFS_PER_ROW) == 1) ) then
			-- New row
			buff:SetPoint("TOP", getglobal(buttonName..(index-GHU_BUFFS_PER_ROW)), "BOTTOM", 0, -GHU_BUFF_ROW_SPACING);
		elseif ( index == 1 ) then
			if unit == "player" then 
				buff:SetPoint("TOPRIGHT", GHU_BuffFrames[unit], "TOPRIGHT", 0, -47);
			else
				buff:SetPoint("TOPLEFT", GHU_BuffFrames[unit], "TOPLEFT", 0, -24	);
			end
			--[[
			if ( rows < 2 ) then
				buff:SetPoint("TOPRIGHT", ConsolidatedBuffs, "BOTTOMRIGHT", 0, -1*((2*GHU_BUFF_ROW_SPACING)+buffHeight));
			else
				buff:SetPoint("TOPRIGHT", ConsolidatedBuffs, "BOTTOMRIGHT", 0, -rows*(GHU_BUFF_ROW_SPACING+buffHeight));
			end --]]
		else
			if unit == "player" then
				buff:SetPoint("RIGHT", previousBuff, "LEFT", -5, 0);
			else
				buff:SetPoint("LEFT", previousBuff, "RIGHT", 0, 0);
			end
		end
		previousBuff = buff;
	end
	
end

-- ************ 		Target Buff frame		************
--[[
function GHU_TargetFrame_UpdateAuras(self)
	local frame, frameName;
	local frameIcon, frameCount, frameCooldown;
	local name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable;
	local frameStealable;
	local numBuffs = 0;
	local playerIsTarget = UnitIsUnit(PlayerFrame.unit, self.unit);
	local selfName = self:GetName();
	
	print("Inserting buffs");
	for i = 1, MAX_TARGET_BUFFS do
		--name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable = UnitBuff(self.unit, i);
		name = "test";
		icon = "Interface\\Icons\\Inv_misc_key_10";
		count = 1;
		duration = 0;
		
		
		frameName = selfName.."GHU_TargetBuff"..i;
		frame = getglobal(frameName);
		if ( not frame ) then
			if ( not icon ) then
				break;
			else
				frame = CreateFrame("Button", frameName, self, "BuffButtonTemplate");
				frame.unit = self.unit;
				print("Created "..frameName);
			end
		end
		if ( icon and ( not self.maxBuffs or i <= self.maxBuffs ) ) then
			frame:SetID(i);

			-- set the icon
			frameIcon = getglobal(frameName.."Icon");
			frameIcon:SetTexture(icon);

			-- set the count
			frameCount = getglobal(frameName.."Count");
			if ( count > 1 and self.showAuraCount ) then
				frameCount:SetText(count);
				frameCount:Show();
			else
				frameCount:Hide();
			end
			
			-- Handle cooldowns
			frameCooldown = getglobal(frameName.."Cooldown");
			if ( duration > 0 ) then
				frameCooldown:Show();
				CooldownFrame_SetTimer(frameCooldown, expirationTime - duration, duration, 1);
			else
				frameCooldown:Hide();
			end

			-- Show stealable frame if the target is not a player and the buff is stealable.
			frameStealable = getglobal(frameName.."Stealable");
			if ( not playerIsTarget and isStealable ) then
				frameStealable:Show();
			else
				frameStealable:Hide();
			end

			-- set the buff to be big if the target is not the player and the buff is cast by the player or his pet
			--largeBuffList[i] = (not playerIsTarget and PLAYER_UNITS[caster]);

			numBuffs = numBuffs + 1;

			frame:ClearAllPoints();
			frame:Show();
		else
			frame:Hide();
		end
	end

	local color;
	local frameBorder;
	local numDebuffs = 0;
	local isEnemy = UnitCanAttack("player", self.unit);
	for i = 1,MAX_TARGET_DEBUFFS do --  do
		--name, rank, icon, count, debuffType, duration, expirationTime, caster = UnitDebuff(self.unit, i);
		icon = nil;
		
		frameName = selfName.."GHU_TargetDebuff"..i;
		frame = getglobal(frameName);
		if ( not frame ) then
			if ( not icon ) then
				break;
			else
				frame = CreateFrame("Button", frameName, self, "DebuffButtonTemplate");
				frame.unit = self.unit;
			end
		end
		if ( icon and ( not self.maxDebuffs or i <= self.maxDebuffs ) and ( SHOW_CASTABLE_DEBUFFS == "0" or not isEnemy or caster == "player" ) ) then
			frame:SetID(i);

			-- set the icon
			frameIcon = getglobal(frameName.."Icon");
			frameIcon:SetTexture(icon);

			-- set the count
			frameCount = getglobal(frameName.."Count");
			if ( count > 1 and self.showAuraCount ) then
				frameCount:SetText(count);
				frameCount:Show();
			else
				frameCount:Hide();
			end

			-- Handle cooldowns
			frameCooldown = getglobal(frameName.."Cooldown");
			if ( duration > 0 ) then
				frameCooldown:Show();
				CooldownFrame_SetTimer(frameCooldown, expirationTime - duration, duration, 1);
			else
				frameCooldown:Hide();
			end

			-- set debuff type color
			if ( debuffType ) then
				color = DebuffTypeColor[debuffType];
			else
				color = DebuffTypeColor["none"];
			end
			frameBorder = getglobal(frameName.."Border");
			frameBorder:SetVertexColor(color.r, color.g, color.b);

			-- set the debuff to be big if the buff is cast by the player or his pet
			--largeDebuffList[i] = (PLAYER_UNITS[caster]);

			numDebuffs = numDebuffs + 1;

			frame:ClearAllPoints();
			frame:Show();
		else
			frame:Hide();
		end
	end
	
	self.auraRows = 0;
	local haveTargetofTarget;
	if ( self.totFrame ) then
		haveTargetofTarget = self.totFrame:IsShown();
	end
	self.spellbarAnchor = nil;
	local maxRowWidth;
	-- update buff positions
	maxRowWidth = ( haveTargetofTarget and self.TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH;
	TargetFrame_UpdateAuraPositions(self, selfName.."Buff", numBuffs, numDebuffs, {}, TargetFrame_UpdateBuffAnchor, maxRowWidth, 3);
	-- update debuff positions
	maxRowWidth = ( haveTargetofTarget and self.auraRows < NUM_TOT_AURA_ROWS and self.TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH;
	TargetFrame_UpdateAuraPositions(self, selfName.."Debuff", numDebuffs, numBuffs, {}, TargetFrame_UpdateDebuffAnchor, maxRowWidth, 4);
	-- update the spell bar position
	if ( self.spellbar ) then
		Target_Spellbar_AdjustPosition(self.spellbar);
	end
end
--]]

--[[
local largeBuffList = {};
local largeDebuffList = {};

-- todo: MUST BE TESTED FOR TAINT

-- aura positioning constants
local AURA_START_X = 5;
local AURA_START_Y = 32;
local AURA_OFFSET_Y = 3;
local LARGE_AURA_SIZE = 21;
local SMALL_AURA_SIZE = 17;
local AURA_ROW_WIDTH = 122;
local TOT_AURA_ROW_WIDTH = 101;
local NUM_TOT_AURA_ROWS = 2;

local PLAYER_UNITS = {
	player = true,
	vehicle = true,
	pet = true,
};

function GHU_TargetFrame_UpdateAuras (self)  -- replaces orig function
	
	
	local frame, frameName;
	local frameIcon, frameCount, frameCooldown;
	local name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable;
	local frameStealable;
	local numBuffs = 0;
	local playerIsTarget = UnitIsUnit(PlayerFrame.unit, self.unit);
	local selfName = self:GetName();
	
	--if playerIsTarget then print("update"); end
	
	local buffsCounted = false;
	local totalBuffs = 0;
	for i = 1, MAX_TARGET_BUFFS do
		local name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable = UnitBuff(self.unit, i);
		
		if (buffsCounted == false and not(icon)) then
			totalBuffs = i-1;
			buffsCounted = true;
		end
		
		
		
		local isGHU;
		
		if not(icon) and (i > totalBuffs) then
			local t = GHU_BuffDisplay:GetBuffs("target",1)[i-totalBuffs];
			
			if type(t)=="table" then
				name = t.name or "";
				rank = t.rank or 0;
				icon = t.icon or "Interface\\Icons\\Ability_Marksmanship";
				duration = t.totalDuration or 0;
				expirationTime = t.expirationTime;
				count = t.count or 1;
				refID = t.refID;
				buffObj = t.buffObj;
				
				isGHU = true;
			end
		end

		frameName = selfName.."Buff"..i;
		frame = getglobal(frameName);
		if ( not frame ) then
			if ( not icon ) then
				break;
			else
				frame = CreateFrame("Button", frameName, self, "BuffButtonTemplate");
				frame.unit = self.unit;
				frame.origOnEnter = frame:GetScript("OnEnter");
				frame.origOnUpdate = frame:GetScript("OnUpdate");
			end
		end
		
		--set tooltip function
		if isGHU then
			--frame:SetScript("OnUpdate",function(self) if ( GameTooltip:IsOwned(self) ) then GHU_BuffDisplay:DisplayTooltip(self); end end);
			local f = frame;
			f:SetScript("OnEnter",function() 
					GameTooltip:SetOwner(f, "ANCHOR_BOTTOMRIGHT");
					GameTooltip:SetFrameLevel(f:GetFrameLevel() + 2);
					GHU_BuffDisplay:DisplayTooltip(f);
			end);
			f:SetScript("OnUpdate",function()
					if ( GameTooltip:IsOwned(f) ) then
						GHU_BuffDisplay:DisplayTooltip(f);
					end
			end);
			f.refID = refID;
		else
			frame:SetScript("OnEnter",frame.origOnEnter);
			frame:SetScript("OnUpdate",frame.origOnUpdate);
		end
		
		if ( icon and ( not self.maxBuffs or i <= self.maxBuffs ) ) then
			frame:SetID(i);

			-- set the icon
			frameIcon = getglobal(frameName.."Icon");
			frameIcon:SetTexture(icon);

			-- set the count
			frameCount = getglobal(frameName.."Count");
			if ( count > 1 and self.showAuraCount ) then
				frameCount:SetText(count);
				frameCount:Show();
			else
				frameCount:Hide();
			end
			
			-- Handle cooldowns
			frameCooldown = getglobal(frameName.."Cooldown");
			if ( duration > 0 ) then
				frameCooldown:Show();
				--print(format("start %s end %s lasts %s",expirationTime - duration,expirationTime,duration));
				CooldownFrame_SetTimer(frameCooldown, expirationTime - duration, duration, 1);
			else
				frameCooldown:Hide();
			end

			-- Show stealable frame if the target is not a player and the buff is stealable.
			frameStealable = getglobal(frameName.."Stealable");
			if ( not playerIsTarget and isStealable ) then
				frameStealable:Show();
			else
				frameStealable:Hide();
			end

			-- set the buff to be big if the target is not the player and the buff is cast by the player or his pet
			largeBuffList[i] = (not playerIsTarget and PLAYER_UNITS[caster]);

			numBuffs = numBuffs + 1;

			frame:ClearAllPoints();
			frame:Show();
		else
			frame:Hide();
		end
	end

	local color;
	local frameBorder;
	local numDebuffs = 0;
	local isEnemy = UnitCanAttack("player", self.unit);
	totalBuffs = 0;
	buffsCounted = false;
	for i = 1, MAX_TARGET_DEBUFFS do
		local name, rank, icon, count, debuffType, duration, expirationTime, caster = UnitDebuff(self.unit, i);
		
		if (buffsCounted == false and not(icon)) then
			totalBuffs = i-1;
			buffsCounted = true;
		end
		
		
		local isGHU;
		if  not(icon) and (i > totalBuffs) then
			local t = GHU_BuffDisplay:GetBuffs("target",2)[i-totalBuffs];
			if type(t)=="table" then
				name = t.name or "";
				rank = t.rank or 0;
				icon = t.icon or "Interface\\Icons\\Ability_Marksmanship";
				duration = t.totalDuration or 0;
				expirationTime = t.expirationTime;
				count = t.count or 1;
				refID = t.refID;
				debuffType = t.debuffType or "";
				buffObj = t.buffObj;
				isGHU = true;
			end
			
		end
		
		frameName = selfName.."Debuff"..i;
		frame = getglobal(frameName);
		if ( not frame ) then
			if ( not icon ) then
				break;
			else
				frame = CreateFrame("Button", frameName, self, "DebuffButtonTemplate");
				frame.unit = self.unit;
				frame.origOnEnter = frame:GetScript("OnEnter");
				frame.origOnUpdate = frame:GetScript("OnUpdate");
			end
		end
		
		if isGHU then
			local f = frame;
			f:SetScript("OnEnter",function() 
					GameTooltip:SetOwner(f, "ANCHOR_BOTTOMRIGHT");
					GameTooltip:SetFrameLevel(f:GetFrameLevel() + 2);
					GHU_BuffDisplay:DisplayTooltip(f);
			end);
			f:SetScript("OnUpdate",function()
					if ( GameTooltip:IsOwned(f) ) then
						GHU_BuffDisplay:DisplayTooltip(f);
					end
			end);
			f.refID = refID;
		else
			frame:SetScript("OnEnter",frame.origOnEnter);
			frame:SetScript("OnUpdate",frame.origOnUpdate);
		end
		
		if ( icon and ( not self.maxDebuffs or i <= self.maxDebuffs ) and ( SHOW_CASTABLE_DEBUFFS == "0" or not isEnemy or caster == "player" ) ) then
			frame:SetID(i);

			-- set the icon
			frameIcon = getglobal(frameName.."Icon");
			frameIcon:SetTexture(icon);

			-- set the count
			frameCount = getglobal(frameName.."Count");
			if ( count > 1 and self.showAuraCount ) then
				frameCount:SetText(count);
				frameCount:Show();
			else
				frameCount:Hide();
			end

			-- Handle cooldowns
			frameCooldown = getglobal(frameName.."Cooldown");
			if ( duration > 0 ) then
				frameCooldown:Show();
				CooldownFrame_SetTimer(frameCooldown, expirationTime - duration, duration, 1);
			else
				frameCooldown:Hide();
			end
			
			-- set debuff type color
			if ( debuffType ) then
				color = DebuffTypeColor[debuffType];
			else
				color = DebuffTypeColor["none"];
			end
			frameBorder = getglobal(frameName.."Border");
			frameBorder:SetVertexColor(color.r, color.g, color.b);

			-- set the debuff to be big if the buff is cast by the player or his pet
			largeDebuffList[i] = (PLAYER_UNITS[caster]);

			numDebuffs = numDebuffs + 1;

			frame:ClearAllPoints();
			frame:Show();
		else
			frame:Hide();
		end
	end
	
	self.auraRows = 0;
	local haveTargetofTarget;
	if ( self.totFrame ) then
		haveTargetofTarget = self.totFrame:IsShown();
	end
	self.spellbarAnchor = nil;
	local maxRowWidth;
	-- update buff positions
	maxRowWidth = ( haveTargetofTarget and self.TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH;
	
	TargetFrame_UpdateAuraPositions(self, selfName.."Buff", numBuffs, numDebuffs, largeBuffList, TargetFrame_UpdateBuffAnchor, maxRowWidth, 3);
	-- update debuff positions
	maxRowWidth = ( haveTargetofTarget and self.auraRows < NUM_TOT_AURA_ROWS and self.TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH;
	TargetFrame_UpdateAuraPositions(self, selfName.."Debuff", numDebuffs, numBuffs, largeDebuffList, TargetFrame_UpdateDebuffAnchor, maxRowWidth, 4);
	-- update the spell bar position
	if ( self.spellbar ) then
		Target_Spellbar_AdjustPosition(self.spellbar);
	end
end


--]]


GHU_Buff = {}
GHU_Buff.__index = GHU_Buff;
GHU_Buff.hooked ={};

-- 	standard
function GHU_Buff:Create(varName)
		
	setglobal(varName,GHU_Buff); 
	
	local obj = {}          
	setmetatable(obj, getglobal(varName))  
		
	setglobal(varName,obj); 
	
	obj.buffs = {};
	obj.debuffs = {};
	
	obj.display = GHU_BuffDisplay:RegisterBuffObj(obj);
	return obj;
end



function GHU_Buff:SetFeedbackFunc(func)
	if not(type(func)=="function") then return end;
	self.feedbackFunc = func;
end

function GHU_Buff:CastBuff(filter,refID,guid,name,description,icon,totalDuration,endTime,count,debuffType,stackable) --API
	-- totalDuration = 0 => LastUntillCanceled
	filter = strlower(tostring(filter or ""));
	if not(guid) then return nil end
	
	
	-- make sure it is a valid debuff type
	local realDebuffType;
	for index,_ in pairs(DebuffTypeColor) do
		if strlower(index) == strlower(debuffType or "") then
			realDebuffType = index;
		end
	end
	
	local t={
		refID = refID, 
		name=name, 
		description = description, 
		icon=icon, 
		totalDuration=totalDuration, 
		expirationTime=endTime, 
		count = stackable and count or 1, 
		debuffType = realDebuffType
	};

	
	if filter=="debuff" or filter=="harmful" or filter=="2" then 
		self.debuffs[guid] = self.debuffs[guid] or {};
		local found;
		for i,buff in pairs(self.debuffs[guid]) do
			if (buff.refID == refID) then
				found = i;
			end
		end
		if found == nil then
			table.insert(self.debuffs[guid],t);
		else
			local t_old = self.debuffs[guid][found];
			if stackable then
				t.count = (t.count or 0) + (t_old.count or 1);
			else
				t.count = 1;
			end
			self.debuffs[guid][found] = t;
		end
	else
		self.buffs[guid] = self.buffs[guid] or {};
		local found;
		for i,buff in pairs(self.buffs[guid]) do
			if (buff.refID == refID) then
				found = i;
			end
		end
		if found == nil then
			table.insert(self.buffs[guid],t);
		else
			local t_old = self.buffs[guid][found];
			if stackable then
				t.count = (t.count or 0) + (t_old.count or 1);
			else
				t.count = 1;
			end
			
			self.buffs[guid][found] = t;
		end
	end
	
	-- i_f the guid is a supported unit for displaying, th en update DB
	for _,unit in pairs(supportedUnits) do
		if UnitGUID(unit) == guid then
			self.display:UpdateDB(unit);
		end
	end
	
	if self.feedbackFunc then self.feedbackFunc(guid); end
end

function GHU_Buff:GetBuffs(guid,buffType)	
	if buffType == 1 then return self.buffs[guid] or {}; end
	if buffType == 2 then return self.debuffs[guid] or {}; end;
	
	return {};
end

function GHU_Buff:SetBuffs(guid,buffType,info) -- overwrites buffs from other ghu_buffs too?
	if buffType == 1 then self.buffs[guid] = info; end
	if buffType == 2 then self.debuffs[guid] = info;  end;
	for _,unit in pairs(supportedUnits) do
		if UnitGUID(unit) == guid then
			self.display:UpdateDB(unit);
		end
	end
end

function GHU_Buff:Serialize(guid)
	local buffs = {};
	local t1 = self:GetBuffs(guid,1);
	for i=1,table.getn(t1) do
		buffs[i] = t1[i];
		buffs[i].buffObj = nil;
	end
	
	local debuffs = {};
	local t2 = self:GetBuffs(guid,2);
	for i=1,table.getn(t2) do
		debuffs[i] = t2[i];
		debuffs[i].buffObj = nil;
	end
	return buffs,debuffs;
end

function GHU_Buff:Deserialize(guid,buffData,debuffData)
	self:SetBuffs(guid,1,buffData);
	self:SetBuffs(guid,2,debuffData);
end


function GHU_Buff:RemoveBuff(refID,guid,count) --API
		
	local found;
	local t;
	local aBuff;
	if type(self.buffs[guid]) == "table" then
		for i,buff in pairs(self.buffs[guid]) do
			if (buff.refID == refID) then
				found = i;
				t = buff;
				aBuff = true;
			end
		end
	end
	if found == nil then
		if type(self.debuffs[guid]) == "table" then
			for i,buff in pairs(self.debuffs[guid]) do
				if (buff.refID == refID) then
					found = i;
					t = buff;
				end
			end
		end
	end
	
	if found and type(t)=="table" then
		if ((t.count or 0) > count) and not(count == 0) then
			t.count = t.count - count;
		else
			if aBuff then
				table.remove(self.buffs[guid],found);
			else
				table.remove(self.debuffs[guid],found);
			end
		end
	end
	
	-- i_f the guid is a supported unit for displaying, th en update DB
	
	for _,unit in pairs(supportedUnits) do
		--print("%s == %s",UnitGUID(unit),guid);
		if UnitGUID(unit) == guid then
			self.display:UpdateDB(unit);
		end
	end
	
	if self.feedbackFunc then self.feedbackFunc(guid); end
end

function GHU_Buff:ClearAllBuffs(guid) --API
	if not(guid) then return end
	self.buffs[guid] = {};
	self.debuffs[guid] = {};
		
	-- i_f the guid is a supported unit for displaying, th en update DB
	
	for _,unit in pairs(supportedUnits) do
		--print("%s == %s",UnitGUID(unit),guid);
		if UnitGUID(unit) == guid then
			self.display:UpdateDB(unit);
		end
	end
	
	if self.feedbackFunc then self.feedbackFunc(guid); end
end



function BuffTest()
	local b = GHU_New("buff");
	--b:CastBuff("buff","a",UnitGUID("player"),"A test buff","Interface\\Icons\\Inv_misc_key_12",nil,nil);
	b:CastBuff("buff","b1",UnitGUID("player"),"Test Buff A","A buff for testing","Interface\\Icons\\Inv_misc_key_12",60*10,GetTime()+60*10,2,nil);
	b:CastBuff("debuff","b2",UnitGUID("player"),"Test deBuff","A buff for testing","Interface\\Icons\\Inv_misc_key_12",60*5,GetTime()+60*5,2,"POISON");
	b:CastBuff("buff","b3",UnitGUID("player"),"Test Buff B","A buff for testing","Interface\\Icons\\Inv_misc_key_12",60*5,GetTime()+60*5,2,nil);

end

function BuffTest2()
	local b = GHU_New("buff");
	for i=1,20 do
		b:CastBuff("buff","b"..i,UnitGUID("player"),"Test Buff A","A buff for testing","Interface\\Icons\\Inv_misc_key_10",60*10,GetTime()+30,2,nil);
	end
end

function BuffEmpty()
	local b = GHU_New("buff");
end
--BuffEmpty();
--BuffTest2();
