GHU_Skill = {}
GHU_Skill.__index = GHU_Skill;
GHU_Skill.hooked ={};

-- 	standard
function GHU_Skill:Create(varName,name)
	
	setglobal(varName,GHU_Skill); 
	
	local obj = {}             -- our new object
	setmetatable(obj, getglobal(varName))  -- make GHU_Skill handle lookup
	obj.headerName = name;      -- initialize our object

	obj.SelectedSkill = 0;
	
	setglobal(varName,obj);
	
	obj:InitHooks(varName);   
	
end
	
function GHU_Skill:Hook(funcName,varName) -- warning: Uses 2kb mermory each time it is run!!!
	
	if not(type(self.orig)=="table") then self.orig ={}; end
	assert(type(self[funcName])=="function","No function found for "..funcName);
	
	self.orig[funcName] = getglobal(funcName);
	G1();		
	local hookObject = getglobal(varName);
	hookObject.hooked[funcName] = function(...)
		gself = getglobal(varName);
		local hookTarget = getglobal(varName);
		return hookTarget[funcName](hookTarget, unpack(arg));
	end
	G2();	
	setglobal(funcName,getglobal(varName)["hooked"][funcName]);
	
	
end

function GHU_Skill:InitHooks(varName)
	if not(self.isHooked) then
		local obj = getglobal(varName);
		
		self:Hook("GetNumSkillLines",varName)
		self:Hook("GetSkillLineInfo",varName)
		self:Hook("SetSelectedSkill",varName)
		self:Hook("GetSelectedSkill",varName)
		
		self.isHooked = true;
	end
end


--	Hooks
function GHU_Skill:GetNumSkillLines()
	self = gself; -- give self info for hooked functions.
	
	return self.orig.GetNumSkillLines() + self:GetNumSkills() + 1;
end

function GHU_Skill:GetSkillLineInfo(line)

	self = gself; -- give self info for hooked functions.
	
	local index = self:GetOwnIndex(line);
	--local skillName, header, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType = GetSkillLineInfo(skillIndex);

	if index == -1 then
	
		return self.orig.GetSkillLineInfo(line);
	elseif index == 0 then
		return self.headerName,1,1,0,0,0,0,0,0,0;
	elseif index <= self:GetNumSkills() then
		local skillName, header, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType, description;
		skillName = self:GetSkillName(index);
		header = nil;
		isExpanded = nil;
		skillRank = self:GetSkillRank(index);
		numTempPoints = 0; --  hidden buff of skill
		skillModifier = 0; -- show buff of skill
		skillMaxRank = self:GetSkillMaxRank(index); -- If 1 the_n it will be all filled and greyed out
		isAbandonable = ((self:GetOnAbandon() and 1) or nil);
		stepCost = nil;	-- learnable skill (cost pr step)
		rankCost = nil; --  trainable skill (cost pr step)  if nil, the_n it is not a trainable skill.
		minLevel = 0;  ---  level for learnable skill. Bugged?
		skillCostType = 1; -- color of buyable skill bars:  1: green, 2: yellow, 3: red, other numbers: purple/grey
		description = self:GetSkillDescription(index);
		return skillName, header, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType, description;
		--return self:GetSkillName(index),nil,nil,self:GetSkillRank(index),0,0,self:GetSkillMaxRank(index),((self:GetOnAbandon() and 1) or nil),nil,1,0,1,self:GetSkillDescription(index);
	end
end


function GHU_Skill:SetSelectedSkill(skill)
	self = gself; -- give self info for hooked functions.
	
	self.orig.SetSelectedSkill(skill);
	self.SelectedSkill = skill;
end

function GHU_Skill:GetSelectedSkill()
	self = gself; -- give self info for hooked functions.
	
	local a = self.orig.GetSelectedSkill();
	if a == 0 then
		return self.SelectedSkill;
	else
		return a;
	end
end

function GHU_Skill:CheckSkillIndex(i)
	if not(type(i)=="number") then i = self:GetIDIndex(i); end
	
	if not(type(self.skills)=="table") then
		self.skills={};
	end
	if type(self.skills[i]) == "table" then
		return true, i;
	end
	
	return false, i;
end

function GHU_Skill:AbandonSkill(i)
	self = gself;
	local index = self:GetOwnIndex(i);
	if index == -1 then
		return self.orig.AbandonSkill(i);
	else
		local abandon = self:GetOnAbandon(index);
		if abandon then
			return abandon(self.id);
		end
	end
	
end

-- intern
function GHU_Skill:GetOwnIndex(line)
	local index = 0;
	if line <= self.orig.GetNumSkillLines() then
		return -1;
	else
		index = line - self.orig.GetNumSkillLines() - 1;
	end
	return index;
end

--	Data
function GHU_Skill:SetSkill(id,name,description,onAbandon) --API  -- uses 3 kb memory
	
	if not(type(self.skills)=="table") then
		self.skills={};
	end
	assert(type(id)=="string","ID for a skill must be a string. Recieved "..type(id)..".");
	
	local i = self:GetIDIndex(id)
	if not(i) then
		
		local skill = {};
		skill.id = id;
		skill.name = name or "";
		skill.description = description or "";
		skill.onAbandon = onAbandon;
		
		table.insert(self.skills,skill);
		
		if CharacterFrame:IsShown() then
			SkillFrame_UpdateSkills(); -- uses 2.15 kb memory the first time it is run
		end
		
		return table.getn(self.skills);
	else
		self.skills[i].name = name or "";
		self.skills[i].description = description or "";
		self.skills[i].onAbandon = onAbandon;		
		if CharacterFrame:IsShown() then
			SkillFrame_UpdateSkills();
		end
		
		return i;
	end
	
end

function GHU_Skill:RemoveSkill(i) --API
	local ok,i = self:CheckSkillIndex(i);
	if ok then
		table.remove(self.skills,i);
		SkillFrame_UpdateSkills();
	end
end

function GHU_Skill:GetHeaderName()
   return self.headerName;
end

function GHU_Skill:GetNumSkills()
	return table.getn(self.skills or {});
end

function GHU_Skill:GetSkillID(i)
	local ok,i = self:CheckSkillIndex(i);
	if ok then
		return self.skills[i].id;
	end
end

function GHU_Skill:GetSkillName(i)
	local ok,i = self:CheckSkillIndex(i);
	if ok then
		return self.skills[i].name;
	end
end

function GHU_Skill:GetOnAbandon(i)
	local ok,i = self:CheckSkillIndex(i);
	if ok then
		return self.skills[i].onAbandon;
	end
end

function GHU_Skill:GetSkillDescription(i)
	local ok,i = self:CheckSkillIndex(i);
	if ok then
		return self.skills[i].description;
	end
end

function GHU_Skill:GetIDIndex(id) --API
	for i = 1,self:GetNumSkills() do
		if self.skills[i].id == id then
			return i;
		end
	end
end

function GHU_Skill:SetSkillRank(i,rank) --API
	local ok,i = self:CheckSkillIndex(i);
	if ok then
		self.skills[i].skillRank = rank;
		if CharacterFrame:IsShown() then
			SkillFrame_UpdateSkills(); 
		end
	end
end

function GHU_Skill:GetSkillRank(i)
	local ok,i = self:CheckSkillIndex(i);
	if ok then
		return (self.skills[i].skillRank or 0);
	end
	return 0;
end

function GHU_Skill:SetSkillMaxRank(i,rank) --API
	local ok,i = self:CheckSkillIndex(i);
	if ok then
		self.skills[i].skillMaxRank = rank;
		if CharacterFrame:IsShown() then
			SkillFrame_UpdateSkills();
		end
	end
end

function GHU_Skill:GetSkillMaxRank(i)
	local ok,i = self:CheckSkillIndex(i);
	if ok then
		return (self.skills[i].skillMaxRank or 0);
	end
	return 0;
end

function GHU_Skill:IncreaseSkill(i)
	local ok,i = self:CheckSkillIndex(i);
	if ok then
		self:SetSkillRank(i,self:GetSkillRank(i)+1);
		return true;
	end
	return false;
end



--[[

function GHU_Test()
	GHU_New("Skill","GHU1","Gryphonheart Professions (Official)");
	
	GHU1:SetSkill("GHP_01","Lumbering","Lumbering is the fine craft of being a Lumberjack (and be OK). Lumberjacks are known for wrestling bears and searching for traps.");
	--local i = GetIDIndex("GHP_01");
	GHU1:SetSkillMaxRank("GHP_01",75);
	GHU1:SetSkillRank("GHP_01",30);
	
	GHU1:SetSkill("GHP_02","Woodworking","Crafting tools, containers, instruments, figures and other things in wood.");
	GHU1:SetSkillMaxRank("GHP_02",75);
	GHU1:SetSkillRank("GHP_02",1);

end

function GHU_Test2()
	GHU2 = GHU_New("Skill","Gryphonheart Professions (User Made)");
	GHU2:SetSkill("GHP_Pilus_01","Programming","Doing codes, as always");
	GHU2:SetSkillMaxRank("GHP_Pilus_01",300);
	GHU2:SetSkillRank("GHP_Pilus_01",222);
	

end

function GHU_Test3()
	GHU_New("Skill","GHU3","Gryphonheart Professions (talents)");
	
	GHU3:SetSkill("GHP_01","Physical work","Defines your speed and stamina in physical work. +5 to Lumbering, Claydigging and Farming.");
	--local i = GetIDIndex("GHP_01");
	GHU3:SetSkillMaxRank("GHP_01",75);
	GHU3:SetSkillRank("GHP_01",30);
	
	GHU3:AddSkill("GHP_02","Creativity","");
	GHU3:SetSkillMaxRank("GHP_02",75);
	GHU3:SetSkillRank("GHP_02",1);

end --]]
