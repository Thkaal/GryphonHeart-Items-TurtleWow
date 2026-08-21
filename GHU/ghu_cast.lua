GHU_Cast = {}
GHU_Cast.__index = GHU_Cast;
GHU_Cast.hooked ={};

-- 	standard
function GHU_Cast:Create(varName,name)
		
	setglobal(varName,GHU_Cast); 
	
	local obj = {}             -- our new object
	setmetatable(obj, getglobal(varName))  -- make GHU_Cast handle lookup
	obj.headerName = name;      -- initialize our object

	
	setglobal(varName,obj);
	
	obj:InitHooks(varName);  
end
	
function GHU_Cast:Hook(funcName,varName)
	
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

function GHU_Cast:InitHooks(varName)
	if not UnitCastingInfo then self.isHooked=true; return; end
	if not(self.isHooked) then
		local obj = getglobal(varName);
		
		self:Hook("UnitCastingInfo",varName)
		
		self.isHooked = true;
	end
end


--	Hooks
function GHU_Cast:UnitCastingInfo(unit)  
	self = gself; -- give self info for hooked functions
	if string.lower(unit)=="player" then
		if self.name then
		
			if (self.endTime or 0) > (GetTime()*1000) then
				
				return self.name,"Rank 1",self.name,self.icon,self.start,self.endTime,true,nil;
				
			end
		end
	end
	return self.orig.UnitCastingInfo(unit);
end

function GHU_Cast:StartCastBar(name,icon,color,duration)
	self.name = name or "";
	self.icon = icon or "";
	-- todo: color
	self.start = GetTime()*1000;
	self.endTime = (GetTime() + (duration or 0))*1000;	
	
	CastingBarFrame_OnEvent(CastingBarFrame,"UNIT_SPELLCAST_START","player",name,1);
end

function GHU_Cast:StopCastBar()
	if self.endTime then
		if (self.endTime or 0) > (GetTime()*1000) then
			CastingBarFrame_OnEvent(CastingBarFrame,"UNIT_SPELLCAST_INTERRUPTED","player",name,1);
			UIErrorsFrame:AddMessage(SPELL_FAILED_INTERRUPTED, 1.0, 0.0, 0.0, 53, 5);
		end
		self.name = nil;
		self.icon = nil;
		self.start = nil;
		self.endTime = nil;
	end
end


