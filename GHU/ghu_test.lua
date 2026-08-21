
local debug = -1 --  -1 = none, 0 = all, 1..+ = a specific one of the tests
--[[					UNIT TEST FOR GHU MODULES
	This file is unit tests for the ghu modules. Debug should be set to -1 at public releases, 
	but set to other values when testing or developing new modules. 
	
	
--]]



local function printTable(t)
	if type(t) == "nil" then
		return "nil";
	elseif type(t) == "table" then
		local s = "{";
		local d = "";
		local lastNum = 0;
		for i,v in pairs(t) do
			if false and type(v)=="number" then
				for j=lastNum+1,i-1 do
					s = s..",["..j.."]=nil";
				end
			end
			s = s..d.."["..i.."]="..printTable(v);
			d = ",";
			lastNum = i;
		end
		return s.."}"
	elseif type(t) == "boolean" then
		if t == true then
			return "true";
		end
		return "false";
	elseif type(t) == "number" or type(t) == "string" then
		return t;
	else
		return type(t);
	end
end
local function test(a,b)
	if not(printTable(b) == printTable(a)) then
		error("Expected "..printTable(b)..", got "..printTable(a));
	end
end



if debug == 0 or debug == 1 then -- craft
	local c = GHU_New("craft");
	
	assert(type(c)=="table","Craft object incorrect");
	
	c:SetCraft("test1","Test Skill",45,75);
	
	
	c:ToggleCraft("test1");
	test({GetTradeSkillLine()},{"Test Skill",45,75});
	

end

if debug == 0 or debug == 2 then  -- quest
	local q = GHU_New("QuestLog");
	
	assert(type(q)=="table","QuestLog object incorrect");
	
	q:Show();
	--before insert
	for i=1,10 do	test({GetQuestLogTitle(i)},{}); end
	
	-- insert examples
	q:AddQuest("e1","Title1",30,"Dungeon",3,"Examples",1,nil);
	q:AddQuest("e2","Title2",50,nil,nil,"Examples",nil,-1);
	q:AddQuest("e3","Title3",10,nil,nil,"Elwynn",-1,nil);
	
	-- GetQuestLogTitle test
	test({GetQuestLogTitle(1)},{"Elwynn",nil,nil,nil,1});
	test({GetQuestLogTitle(2)},{"Title3",10,nil,nil,nil,nil,-1,nil,nil});
	test({GetQuestLogTitle(3)},{"Examples",nil,nil,nil,1});
	test({GetQuestLogTitle(4)},{"Title1",30,"Dungeon",3,nil,nil,1,nil,nil});
	test({GetQuestLogTitle(5)},{"Title2",50,nil,nil,nil,nil,nil,-1,nil});
	test({GetQuestLogTitle(6)},{});
	
	-- Collapse / expand test
	CollapseQuestHeader(0); -- collaps all
	test({GetQuestLogTitle(1)},{"Elwynn",nil,nil,nil,1,1});
	test({GetQuestLogTitle(2)},{"Examples",nil,nil,nil,1,1});
	test({GetQuestLogTitle(3)},{});
	
	ExpandQuestHeader(1);
	test({GetQuestLogTitle(1)},{"Elwynn",nil,nil,nil,1,nil});
	test({GetQuestLogTitle(3)},{"Examples",nil,nil,nil,1,1});
	test({GetQuestLogTitle(4)},{});
	
	ExpandQuestHeader(3);
	CollapseQuestHeader(1);
	test({GetQuestLogTitle(1)},{"Elwynn",nil,nil,nil,1,1});
	test({GetQuestLogTitle(2)},{"Examples",nil,nil,nil,1,nil});
	test({GetQuestLogTitle(5)},{});
	
	---GetNumQuestLeaderBoards
	q:AddObj("e2","test2","Explore","Elwynn Forest",1);
	q:AddObj("e1","test1","Explore","Elwynn Forest",1);
	--q:AddText("e3","Testestest moo", "Explore Elwynn forest for cows","Done yet?","Return to someone");
	--q:AddObj("e2","test3","Explore","Elwynn Forest",1);
	--q:AddText("e2","Testestest moooo", "Explore Elwynn forest for cows","Done yet?","Return to someone");
	
	--q:AddText("e1","Testestest moomoo", "Explore Elwynn forest for cows","Done yet?","Return to someone");
	CollapseQuestHeader(1); -- expand all
	test({GetNumQuestLeaderBoards(2)},{1}); -- input is the number, not the refID--keeps returning 0
	test({GetQuestLogLeaderBoard("test1","e1")},{"Elwynn Forest","Explore",nil});--keeps giving me ..\AddOns\GHU\ghu_ql.lua line 315:
  -- Usage: GetQuestLogLeaderBoard(index)

	--test({GetQuestLogQuestText()},{"Testestest moo", "Explore Elwynn forest for cows"});--returns as a function this ones odd..
	
	
	
end






