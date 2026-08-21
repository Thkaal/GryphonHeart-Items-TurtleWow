-- Turtle WoW / WoW 1.12 compatibility helpers
-- IsModifierKeyDown() was added after the Vanilla client.  GHI uses it
-- for item pickup/link/copy decisions, so emulate the later API from the
-- modifier functions that exist on WoW 1.12/TurtleWoW.
if not IsModifierKeyDown then
	function IsModifierKeyDown()
		local shift = false;
		local ctrl = false;
		local alt = false;
		if type(IsShiftKeyDown) == "function" then shift = IsShiftKeyDown(); end
		if type(IsControlKeyDown) == "function" then ctrl = IsControlKeyDown(); end
		if type(IsAltKeyDown) == "function" then alt = IsAltKeyDown(); end
		return (shift and true) or (ctrl and true) or (alt and true) or false;
	end
end
if not math.modf then
	function math.modf(value)
		local whole;
		if value < 0 then whole = math.ceil(value); else whole = math.floor(value); end
		return whole, value - whole;
	end
end
-- Lua 5.0.2 on the Vanilla client does not expose all of the 2.x/3.x
-- string conveniences used by the original 2010 source.
if not string.match then
    function string.match(text, pattern, init)
        local r = {string.find(text, pattern, init)};
        if not r[1] then return nil; end
        if table.getn(r) > 2 then
            table.remove(r,1);
            table.remove(r,1);
            return unpack(r);
        end
        return string.sub(text,r[1],r[2]);
    end
end
if not string.gmatch and string.gfind then
    string.gmatch = string.gfind;
end
if not strsplit then
    function strsplit(delimiter, text, pieces)
        text = tostring(text or "");
        delimiter = tostring(delimiter or "");
        if delimiter == "" then return text; end
        local out = {};
        local start = 1;
        local limit = tonumber(pieces);
        while not limit or table.getn(out) < limit-1 do
            local a,b = string.find(text, delimiter, start, true);
            if not a then break; end
            table.insert(out,string.sub(text,start,a-1));
            start = b+1;
        end
        table.insert(out,string.sub(text,start));
        return unpack(out);
    end
end
if not strjoin then
    function strjoin(delimiter,...)
        return table.concat(arg, delimiter or "");
    end
end
if not string.split then
    string.split = strsplit;
end
if not UnitGUID then
	function UnitGUID(unit) return UnitName(unit) or unit; end
end
if not InCombatLockdown then
	function InCombatLockdown() return false; end
end
-- Do NOT provide a global hooksecurefunc() shim here.
-- GHI/GHM/GHU do not actively require it on TurtleWoW, and defining a
-- process-wide fallback can be picked up by other addons (notably
-- ChatThrottleLib users such as TurtleRP) before their own compatibility
-- layer loads.  Leaving it undefined here avoids changing other addons.

-- test

local timersSetup;
local timers = {};

function GHU_New(Type,name,arg1)
	local varName;
	local c = 1000;
	while (varName == nil) do
		if (getglobal("GHU_"..c) == nil) then
			varName = "GHU_"..c;
		end
		c = c+1;
	end
	Type = strlower(Type);
	
	if Type=="skill" then
		GHU_Skill:Create(varName,name);
	elseif Type=="npc" then
		GHU_NPC:Create(varName);
	elseif Type=="mail" then
		GHU_Mail:Create(varName);
	elseif Type=="achievement" then
		GHU_Achievement:Create(varName,name);
	elseif Type=="profession" then
		error("Profession GHU dosent exsist. Use craft");
	elseif Type=="cast" then
		GHU_Cast:Create(varName);
	elseif Type=="loot" then
		GHU_Loot:Create(varName);
	elseif Type=="book" then
		GHU_Book:Create(varName);
	elseif Type=="questlog" then
		GHU_QL:Create(varName);
	elseif Type=="talent" then
		GHU_Talent:Create(varName,name,arg1); -- arg1 being icon 
	elseif Type=="craft" then
		GHU_Craft:Create(varName);
	elseif Type=="buff" then
		GHU_Buff:Create(varName);
	elseif Type=="target" then
		GHU_Target:Create(varName);
	end
	
	if not(timersSetup) then
		local Old_Script = WorldFrame:GetScript("OnUpdate");
		WorldFrame:SetScript("OnUpdate", function() if Old_Script then Old_Script(); end GHU_OnWF(); end);
	
	end
	
	return getglobal(varName);
end

function GHU_RegTimer(s,func)
	table.insert(timers,{s = s, func = func});
end

function GHU_OnWF()
	for _,t in pairs(timers) do
		--print(type(t.s));
		t.func(t.s);
	end

end



