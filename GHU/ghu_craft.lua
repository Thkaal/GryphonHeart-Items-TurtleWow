GHU_Craft = {}
GHU_Craft.__index = GHU_Craft;
GHU_Craft.hooked ={};

-- 	standard
function GHU_Craft:Create(varName,name,icon)
		
	setglobal(varName,GHU_Craft); 
	
	local obj = {}             -- our new object
	setmetatable(obj, getglobal(varName))  -- make GHU_Craft handle lookup
	
	
	--GHU_Tabs:NewTab("Talent",obj,name,icon)
	obj.crafts = {};
	obj.currentShown = nil;
	
	setglobal(varName,obj);
	
	obj:InitHooks(varName);  
end
	
function GHU_Craft:Hook(funcName,varName)
	
	if not(type(self.orig)=="table") then self.orig ={}; end
	assert(type(self[funcName])=="function","No function found for "..funcName);
	self.orig[funcName] = getglobal(funcName);
		
	local hookObject = getglobal(varName);
	hookObject.hooked[funcName] = function(...)
		gself = getglobal(varName);
		local hookTarget = getglobal(varName);
		return hookTarget[funcName](hookTarget, unpack(arg));
	end
	setglobal(funcName,getglobal(varName)["hooked"][funcName]);
end

function GHU_Craft:InitHooks(varName)
	if not(self.isHooked) then
		local obj = getglobal(varName);
		
		self:Hook("GetTradeSkillLine",varName)
		
				
		self.fName = varName;
				
		self.isHooked = true;
	end
end

-- =========== hooked ==================
-- GetTradeSkillLine() - Returns information about the selected skill line. 
function GHU_Craft:GetTradeSkillLine()
	self = gself;
	if self.shown then
		local t = self:GetCurrentCraft();
		return t.name or "UNKNOWN 2",t.level or 0,t.max or 0;
	end
	return self.orig.GetTradeSkillLine();
end

-- CloseTradeSkill() - Closes an open trade skill window. 
function GHU_Craft:CloseTradeSkill()
	self = gself;
	if self.shown then
		self:Hide();
	end
	return self.orig.CloseTradeSkill();
end

-- CollapseTradeSkillSubClass(index) - Collapses the specified subclass header row. 
function GHU_Craft:CollapseTradeSkillSubClass(index)
	self = gself;
	if self.shown then
		local craft = self:GetCurrentCraft();
		local header = self:GetIndexInfo(index);
		craft.collapsed[header] = true;
		self:UpdateIndexInfoList();
		return;
	end
	return self.orig.CollapseTradeSkillSubClass(index)
end

-- ExpandTradeSkillSubClass(index) - Expands the specified subclass header row. 
function GHU_Craft:ExpandTradeSkillSubClass(index)
	self = gself;
	if self.shown then
		local craft = self:GetCurrentCraft();
		local header = self:GetIndexInfo(index);
		craft.collapsed[header] = false;
		self:UpdateIndexInfoList();
		return;
	end
	return self.orig.ExpandTradeSkillSubClass(index)
end

-- GetFirstTradeSkill() - Returns the index of the first non-header trade skill entry. 
function GHU_Craft:GetFirstTradeSkill()
	self = gself;
	if self.shown then
		local index = 1;
		local header,ability = self:GetIndexInfo(index);
		while (header and not(ability)) do
			index = index + 1;
			header,ability = self:GetIndexInfo(index);
		end
		return index;
	end
	return self.orig.GetFirstTradeSkill();
end

-- GetNumTradeSkills() - Get the number of trade skill entries (including headers). 
function GHU_Craft:GetNumTradeSkills()
	self = gself;
	if self.shown then
		return table.getn(self.lines);
	end
	return self.orig.GetNumTradeSkills();
end

-- GetTradeSkillCooldown(index) - Returns the number of seconds left for a skill to cooldown. 
function GHU_Craft:GetTradeSkillCooldown(index)
	self = gself;
	if self.shown then
		local _,id = self:GetIndexInfo(index);
		if id then
			local craft = self:GetCurrrentCraft();
			if type(craft.abilities[id])=="table" then
				local sec = (craft.abilities[id].cd or 0) - time();
				return (sec > 0 and sec) or 0;
			end
		end
		return 0;
	end
	return self.orig.GetTradeSkillCooldown(index);
end

-- 	GetTradeSkillDescription(index) - Returns the description text of the indicated trade skill. 
function GHU_Craft:GetTradeSkillDescription(index)
	self = gself;
	if self.shown then
		local _,id = self:GetIndexInfo(index);
		if id then
			local craft = self:GetCurrrentCraft();
			if type(craft.abilities[id])=="table" then
				return craft.abilities[id].description or "";
			end
		end
		return "";
	end
	return self.orig.GetTradeSkillDescription(index);
end

-- GetTradeSkillIcon(index) - Returns the texture name of a tradeskill's icon. 
function GHU_Craft:GetTradeSkillIcon(index)
	self = gself;
	if self.shown then
		local _,id = self:GetIndexInfo(index);
		if id then
			local craft = self:GetCurrrentCraft();
			if type(craft.abilities[id])=="table" then
				return craft.abilities[id].icon or "";
			end
		end
		return "";
	end
	return self.orig.GetTradeSkillIcon(index);
end

-- GetTradeSkillInfo(index) - Retrieves information about a specific trade skill. 
-- returning skillName, skillType, numAvailable, isExpanded, altVerb
function GHU_Craft:GetTradeSkillInfo(index)
	self = gself;
	if self.shown then
		local header,id = self:GetIndexInfo(index);
		if not(id) then -- header
			return header,"header";
		else
			local craft = self:GetCurrrentCraft();
			if type(craft.abilities[id])=="table" then
				local a = craft.abilities[id];
				local name,Type,numAvaliable,isExpanded, altVerb;
				
				-- name
				name = a.name;
				
				-- Type
				if craft.level < a.reqLevel then -- should not happend
					Type = "difficult";
				elseif craft.level < a.normalLevel then
					Type = "optimal";
				elseif craft.level < a.easyLevel then
					Type = "medium";
				elseif craft.level < a.trivialLevel then
					Type = "easy";
				else
					Type = "trivial";
				end
				
				-- num avaliable
				numAvaliable = 1; -- todo: Reference to an outside function.
				
				-- isExpanded
				isExpanded = craft.collapsed[header];
				
				-- alt verb
				altVerb = a.altVerb;
				
			end
		end
		return "";
	end
	return self.orig.GetTradeSkillInfo(index);
end



-- =========== Internal ==================
function GHU_Craft:Show()
	self.shown = true;
	self:UpdateIndexInfoList();
end

function GHU_Craft:Hide()
	self.shown = false;
end

function GHU_Craft:GetCurrentCraft()
	local i = self.currentShown;
	if i and type(self.crafts[i])=="table" then
		return self.crafts[i];
	end
	return {};
end

function GHU_Craft:GetIndexInfo(index)
	local t = self.lines[index] or {};
	return t[1] or "", t[2];
end

function GHU_Craft:UpdateIndexInfoList()
	local craft = self:GetCurrentCraft();
	local lines = {};
	for header,abilities in pairs(craft.sorted) do
		table.insert(lines,{header});
		if not(craft.collapsed[header]) then
			for i = 1,table.getn(abilities) do
				if type((abilities[i] or {}).reqLevel) == "number" and abilities[i].reqLevel <= craft.level then 
					table.insert(lines,{header,abilities[i] or ""});
				end
			end
		end
	end
	self.lines = lines;
	if self.shown then
		-- todo: call ui update
	end
end

-- =========== Set API ==================
function GHU_Craft:SetCraft(craftRefID,skillName,level,maxLevel) --API --This must be set when updating data aswell
	
	self.crafts[craftRefID] = {
		["name"]=skillName,
		["level"]=level,
		["max"] = maxLevel,
		["abilities"] = (self.crafts[craftRefID] or {}).abilities or {},
		["sorted"] = (self.crafts[craftRefID] or {}).sorted or {},
		["collapsed"] = (self.crafts[craftRefID] or {}).collapsed or {},
	};
end

function GHU_Craft:SetAbility(abilityID,craftRefID,name,description,icon,headerName,reqLevel,normalLevel,easyLevel,trivialLevel,cooldownTime,altVerb) --API
	assert(type(abilityID)=="string" or type(abilityID)=="number","Illigal ability ref id");
	assert(type(craftRefID)=="string" or type(craftRefID)=="number","Illigal craft ref id");
	assert(type(self.crafts[craftRefID])=="table","Unknown craft id");
	
	-- todo: validate
	
	local c = self.crafts[craftRefID];
	
	c[abilityID] = {
		["name"]=name,
		["header"] = headerName,
		["reqLevel"] = reqLevel, -- same as "hardLevel"
		["normalLevel"] = normalLevel,
		["easyLevel"] = easyLevel,
		["trivialLevel"] = trivialLevel,
		["description"] = description,
		["cd"] = cooldownTime,
		["icon"] = icon,
		["altVerb"] = altVerb,
	};
	
	-- maintain sorted list of abilities
	local s = {};
	for i,ability in pairs(c.abilities) do
		local t = s[ability.header] or {};
		local inserted = false;
		for j=1,table.getn(t) do
			if type(c[t[j]]) == "table" and c[t[j]].reqLevel > ability.reqLevel then
				table.insert(t,j,i);
				inserted = true;
				break;			
			end
		end
		if inserted == false then
			table.insert(t,i);
		end
		s[ability.header] = t;
	end
	c.sorted = s;
	
	self:UpdateIndexInfoList()
end

function GHU_Craft:ToggleCraft(refID) --API
	self.currentShown = refID;
	self:Show();
end
