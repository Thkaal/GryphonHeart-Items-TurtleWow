

GHU_Achievement = {}
GHU_Achievement.__index = GHU_Achievement;
GHU_Achievement.hooked ={};

-- 	standard
function GHU_Achievement:Create(varName,name)
		
	setglobal(varName,GHU_Achievement); 
	
	local obj = {}             -- our new object
	setmetatable(obj, getglobal(varName))  -- make GHU_Achievement handle lookup
	
	obj.catagoryName = name;      -- initialize our object
	local _,id = strsplit("_",varName);
	obj.id = tonumber(id);
	
	setglobal(varName,obj);
	
	obj:InitHooks(varName);  
end
	
function GHU_Achievement:Hook(funcName,varName)
	
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

function GHU_Achievement:InitHooks(varName)
	if not GetAchievementInfo then self.isHooked=true; return; end
	if not(self.isHooked) then
		local obj = getglobal(varName);
		
		self:Hook("GetCategoryList",varName)
		self:Hook("GetCategoryInfo",varName)
		self:Hook("GetCategoryNumAchievements",varName)
		self:Hook("GetAchievementInfo",varName)
		--self:Hook("AchievementFrameCategories_DisplayButton",varName)
		--self:Hook("GetInboxNumItems",varName)
		--self:Hook("GetLatestThreeSenders",varName)
		--self:Hook("GetInboxText",varName)
		
		--self:Hook("PlaySound",varName)
		
		--FEAT_OF_STRENGTH_DESCRIPTION = "";
		
		self.isHooked = true;
		
	end
end

-- Hooking
function GHU_Achievement:GetCategoryList(id)
	self = gself; -- give self info for hooked functions
	local t = self.orig.GetCategoryList(id);
	for i = 1,3 do 
		table.insert(t,tonumber(self.id.."."..i));
	end
	
	return t;
end

function GHU_Achievement:GetCategoryInfo(id)
	self = gself; -- give self info for hooked functions
	--GHI_Message(id);
	local ownID,num = strsplit(".",tostring(id));
	--GHI_Message( (ownID or "nil").." == "..self.id);
	ownID = tonumber(ownID);
	if ownID == self.id then
		num = tonumber(num);
		if num == 1 then
			return "Gryphonheart",-1,0;
		elseif num == 2 then
			return "Professions", tonumber(self.id..".1"),1;
		else
			return "Wealth", tonumber(self.id..".1"),1;
		end
	end
	return self.orig.GetCategoryInfo(id);
end

function GHU_Achievement:GetCategoryNumAchievements(id)
	self = gself; -- give self info for hooked functions
	--GHI_Message(id);
	local ownID,num = strsplit(".",tostring(id));
	ownID = tonumber(ownID);
	if ownID == self.id then
		num = tonumber(num);
		return 2,2;
	end
	return self.orig.GetCategoryNumAchievements(id);
end

function GHU_Achievement:GetAchievementInfo(id,index)
	self = gself; -- give self info for hooked functions
	--GHI_Message(id);
	local ownID,num = strsplit(".",tostring(id));
	ownID = tonumber(ownID);
	if ownID == self.id then
		num = tonumber(num);
		if index == 1 then
			return 0,"Pioneer",0,true,29,04,09,"Recieve the wealth rank of Pioneer",0,"Interface\\Icons\\INV_Pick_01","";
		else 
			return 0,"Citizen",0,false,nil,nil,nil,"Recieve the wealth rank of Citizen",0,"Interface\\Icons\\INV_Pick_02","";
		end
	end
	return self.orig.GetAchievementInfo(id,index);
end
--[[ 	
	/script GHU_New("Achievement","GHP");
	
--]]--


-- Database
function GHU_Achievement:GetCat()

end


local test2 = {};
function GHU_Achievement:AddTest(num)
	table.insert(test2,num);
end
function GHU_Achievement:GetTest()
	return test2;
end
