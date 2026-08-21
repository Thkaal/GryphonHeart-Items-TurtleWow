
GHU_QL = {}
GHU_QL.__index = GHU_QL;
GHU_QL.hooked ={};


-- 	standard
function GHU_QL:Create(varName,name)
		
	setglobal(varName,GHU_QL); 
	
	local obj = {}             -- our new object
	setmetatable(obj, getglobal(varName))  -- make GHU_NPC handle lookup
	obj.questName = name;
	local _,id = strsplit("_",varName);
	--print(id);
	obj.questID = id;
	--print(obj.questID);
	-- initialize our object
--
	self.quests = {};
	self.headers = {};
	self.index = {};
	
	setglobal(varName,obj);

	obj:InitHooks(varName);  

end
	
function GHU_QL:Hook(funcName,varName)
	
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

function GHU_QL:InitHooks(varName)
	if not(self.isHooked) then
		local obj = getglobal(varName);
		
		self:Hook("GetNumQuestLogEntries",varName)
		self:Hook("ExpandQuestHeader",varName)
		self:Hook("CollapseQuestHeader",varName)
	    self:Hook("GetQuestLogQuestText",varName)
		self:Hook("GetQuestLogSelection",varName)
		self:Hook("GetQuestLogTitle",varName)
		self:Hook("SelectQuestLogEntry",varName)
		 self:Hook("GetNumQuestLeaderBoards",varName)
		self:Hook("GetNumQuestLogChoices",varName)
		self:Hook("GetNumQuestLogRewards",varName)
		self:Hook("GetQuestLogLeaderBoard",varName)
		self:Hook("GetQuestLogQuestText",varName)
		self:Hook("GetQuestLogPushable",varName);
		self:Hook("GetQuestLogRequiredMoney",varName);
		self:Hook("GetQuestLogRewardInfo",varName);
		--self:Hook("GetQuestLogRewardMoney",varName);
		self:Hook("GetProgressText",varName);
		self:Hook("GetQuestLogCompletionText",varName);
		self:Hook("GetQuestLogChoiceInfo",varName);
		
		--self:Hook("QuestLog_Update",varName)
		--self:Hook("PlaySound",varName)
		
		self.isHooked = true;
	end
end


-- =================	Control of display  ==============
--[[These functions is used to decide if the quest information from this.
	Quest Log object is being shown, or if the original values is being shown.
	
	When the self.shown value is true, then the hooked function should return 
	the modified value. Otherwise it should return the original function.
--]]
function GHU_QL:Show() 
	GHU_QL.shown = true;
	QuestLog_Update();
end

function GHU_QL:Hide()
	GHU_QL.shown = nil;
	QuestLog_Update();
end


-- =================	The hooked functions ==================
function GHU_QL:GetNumQuestLogEntries()  -- for this we also need to know how many headers we got. It shall return the number of headers plus quests
	self = gself
     --print(type(self.quests));
	--[[
	  local numEntries, numQuests = self.orig.GetNumQuestLogEntries()
		local hn,qn = self:GetNumTotalGHUQuests()
		numEntries = numEntries+hn;--all
		numQuests = numQuests+qn;
		print("GHUQ")
		print(numEntries,numQuests);
		print("0000")
		return numEntries,numQuests
	end
	print(self.orig.GetNumQuestLogEntries());
	return self.orig.GetNumQuestLogEntries() --+ self:GetNumTotalGHUQuests()]]

  self = gself
  if self.shown==true then
		--return self:GetNumTotalGHUQuests()
		return table.getn(self.index)
  end
  return self.orig.GetNumQuestLogEntries();

end


function GHU_QL:SelectQuestLogEntry(i)
	self = gself
	--print("SelectQuestLogEntry ID");
	--print(i)
	--print("000")
	
	if self.shown then
		if type(self.index[i])=="table" then
			local refID = self.index[i].refID;
			--print(refID);
			--print(refID);
			if refID then
				self.selectedQuest = refID;
		
				--return self.selectedQuest;
			else
			 self.selectedQuest = i;
			 --return self.selectedQuest;
	
			end
		--[[ el se
		self.selectedQuest = i;
		return self.selectedQuest;]]
		end
	end

	--return self.orig.SelectQuestLogEntry(i)
end

function GHU_QL:GetQuestLogSelection()
	self = gself
		
	if self.shown then
		--print(self.selectedQuest);
		return self.selectedQuest;
	end
		
	return self.orig.GetQuestLogSelection()
end


function GHU_QL:GetQuestLogTitle(i) -- id is the id in the quest log
	self = gself

	--[[
	print(" GetQuestLogTitle");
	print(id)
	print("000")
	if self.shown then
		if self.quests[id] then -- 
			return self.quests[id].questTitle,self.quests[id].level,self.quests[id].questTag,self.quests[id].suggestedGroup,self.quests[id].isHeader,self.quests[id].isCollapsed,self.quests[id].isComplete,self.quests[id].isDaily,self.quests[id].questID;
		end
	end --]]
	if self.shown then
		if type(self.index[i])=="table" then
			local refID = self.index[i].refID;
			if not(refID) then -- header
			     --print(self.index[i].isCollapsed)
			   --GHI_PrintArray(self.index[i]);
				return self.index[i].name,nil,nil,nil,1,self.index[i].isCollapsed; --todo: insert collapsed info
			elseif type(self.quests[refID])=="table" then
				return self.quests[refID].questTitle,self.quests[refID].level,self.quests[refID].questTag,self.quests[refID].suggestedGroup,nil,nil,self.quests[refID].isComplete,self.quests[refID].isDaily,self.quests[refID].questID;
			end
		end
		return nil;
	end

	return self.orig.GetQuestLogTitle(i)

end


function GHU_QL:GetNumQuestLeaderBoards(i)
self = gself

if self.shown then 
---this has to do with objectives, or the number of objectives a quest has

if not(i) then
i = i or self.selectedQuest;
end

--local refID = self.index[i].refID
if type(self.index[i]) == "table" then 
-- todo: return 0 if it is a header
local refID = self.index[i].refID
--print(refID)


if not(refID) then -- header---refid was not being passed so this is coming back as 0 always
return 0;

elseif type(self.quests[refID].objective)=="table" then
--print("array for numquestloglboard")
--GHI_PrintArray(self.quests[refID].objective)
 local objNum = 0;

 for k,v in pairs(self.quests[refID].objective) do objNum=objNum+1  end
--print("pong");
 print(objNum)
 
return objNum;
 end
 end 

end


return self.orig.GetNumQuestLeaderBoards(refID,objID);
end

function GHU_QL:GetNumQuestLogChoices()
--Returns the number of available item reward choices for the selected quest in the quest log. 
--This function refers to quest rewards for which the player is allowed to choose one item from among several; 

self = gself
if self.shown then 

local i = self.selectedQuest;

if type(self.index[i]) == "table" then 
local refID = self.index[i].refID;
if not(refID) then
--do nothing
elseif type(self.quests[refID])=="table" then
 local rewardNum = table.getn(self.quests[refID].rewards);--again need a check for one or all rewards given.
 return rewardNum;
 end
 end 
end
 return self.orig.GetNumQuestLogChoices();
end

function GHU_QL:GetNumQuestLogRewards()
--Returns the number of item rewards for the selected quest in the quest log. 
--This function refers to items always awarded upon quest completion; 
self = gself

if self.shown then 

local i = self.selectedQuest;

if type(self.index[i]) == "table" then 
local refID = self.index[i].refID;
if not(refID) then
--do nothing
elseif type(self.quests[refID])=="table" then
 local rewardNum = table.getn(self.quests[refID].rewards);--again need a check for one or all rewards given.
 return rewardNum;
 end
 end 
 

end
return self.orig.GetNumQuestLogRewards()
end

function GHU_QL:GetQuestLogLeaderBoard(objID, i)
--[[Returns information about objectives for a quest in the quest log
Signature:
text, type, finished = GetQuestLogLeaderBoard(objective [, questIndex])
Arguments:
    * objective - Index of a quest objective (between 1 and GetNumQuestLeaderBoards()) (number)
    * questIndex - Index of a quest in the quest log (between 1 and GetNumQuestLogEntries()); if omitted, defaults to the selected quest (number)
Returns:
      text - Text of the objective (e.g. "Gingerbread Cookie: 0/5") (string)
    *type - Type of objective (string)
          o event - Requires completion of a scripted event
          o item - Requires collecting a number of items
          o monster - Requires slaying a number of NPCs
          o object - Requires interacting with a world object
          o reputation - Requires attaining a certain level of reputation with a faction
    *finished - 1 if the objective is complete; otherwise nil (1nil)]]
	
	self = gself
--print("indexobjID "..objID)

if self.shown then 
--GHI_PrintArray(self.quests[refID].objective);
---this has to do with objectives, or the number of objectives a quest has
--print("indexobjID "..objID)
local i = i or self.selectedQuest;
if type(self.index[i]) == "table" then 
local refID = self.index[i].refID;

--print(refID)
if type(self.quests[refID].objective)=="table" then

--GHI_PrintArray(self.quests[refID].objective);
 local object = self.quests[refID].objective;
 --print(objID)

 return object[objID].tarText,object[objID].objType,object[objID].isComplete;
 end
 end 

end
return self.orig.GetQuestLogLeaderBoard(objID,i)

end


--[[GetQuestLogPushable
Return whether the selected quest in the quest log can be shared to party members
Signature:
shareable = GetQuestLogPushable()
Returns

    * shareable - 1 if the quest is shareable; otherwise nil (1nil)

	Possible to handle on the GHD end of things still need to add a field for it somwehre in the table, unsure.
	]]
	
function GHU_QL:GetQuestLogPushable()

return self.orig.GetQuestLogPushable()
end
	
function GHU_QL:GetQuestLogQuestText()
self = gself
  --  *  questDescription - Full description of the quest (as seen in the NPC dialog when accepting the quest) (string)
    --* questObjectives - A (generally) brief summary of quest objectives (string)


if self.shown then
local refID = self.index[self.selectedQuest];
if type(self.quests[refID])=="table" then
 local qtext,objSum = self.quests[refID].questDescription,self.quests[refID].questObjectives;
 --print(qtext);
 return qtext, objSum;
 end
 end 



return self.orig.GetQuestLogQuestText;
end



function GHU_QL:GetQuestLogRequiredMoney()

--[[Returns the amount of money required for the selected quest in the quest log

Signature:

money = GetQuestLogRequiredMoney()

Returns:

    * money - The amount of money required to complete the quest (in copper) (number)
	
	For use with a GHP Currancy?
]]

return self.orig.GetQuestLogRequiredMoney()
end


function GHU_QL:GetQuestLogRewardInfo()
--[[Returns information about item rewards for the selected quest in the quest log. 
This function refers to items always awarded upon quest completion; for quest rewards for which the player 
is allowed to choose one item from among several, see GetQuestLogChoiceInfo.

Signature:

name, texture, numItems, quality, isUsable = GetQuestLogRewardInfo(index)

Arguments:

    * index - Index of a quest reward (between 1 and GetNumQuestLogRewards()) (number)

Returns:

    * name - Name of the item (string)
    * texture - Path to an icon texture for the item (string)
    * numItems - Number of items in the stack (number)
    * quality - Quality of the item (number, itemQuality)
    * isUsable - 1 if the player can use or equip the item; otherwise nil (1nil)
	alot of this will need to come from the GHI ]]
	
return self.orig.GetQuestLogRewardInfo()	
end

--[[Returns the money reward for the selected quest in the quest log

Signature:

money = GetQuestLogRewardMoney()

Returns:

    * money - Amount of money rewarded for completing the quest (in copper) (number)
	
	GHP Related possibly]]
	
	function GHU_QL:GetQuestLogRewardMoney()
	return self.orig.GetQuestLogRewardMoeny()
	end
	

	--[[Returns the quest progress text presented by a questgiver. Only valid when the questgiver UI is showing the progress stage of a quest dialog (between the QUEST_PROGRESS  and QUEST_FINISHED  events); otherwise may return the empty string or a value from the most recently displayed quest.

Signature:

text = GetProgressText()

Returns:

    * text - Progress text for the quest (string)
]]

function GHU_QL:GetProgressText()
if self.shown then
local refID = self.index[self.selectedQuest];
if not(refID) then
--do nothing
elseif type(self.quests[refID])=="table" then
 local progress = self.quests[refID].progress;
 return progress
 end
 end 
 
 return self.orig.GetProgressText()
 end

 --[[Returns the completion text for the selected quest in the quest log. 
 Completion text usually includes instructions on to whom and where to hand in the quest once it 
 has been completed. Example: "Return to William Pestle at Goldshire in Elwynn Forest."

Signature:

completionText = GetQuestLogCompletionText()

Returns:

    * completionText - Completion instructions for the quest (string)]]
	
function GHU_QL:GetQuestLogCompletionText()
if self.shown then
local refID = self.index[self.selectedQuest];
if not(refID) then
--do nothing
elseif type(self.quests[refID])=="table" then
 local finish = self.quests[refID].finish;
 return finish;
 end
 end 
 
 return self.orig.GetQuestLogCompletionText()
 end

 
 
--[[ Returns information about available item rewards for the selected quest in the quest log. This function refers to quest rewards for which the player is allowed to choose one item from among several; for items always awarded upon quest completion, see GetQuestLogRewardInfo.

Signature:

name, texture, numItems, quality, isUsable = GetQuestLogChoiceInfo(index)

Arguments:

    * index - Index of a quest reward choice (between 1 and GetNumQuestLogChoices()) (number)

Returns:

    * name - Name of the item (string)
    * texture - Path to an icon texture for the item (string)
    * numItems - Number of items in the stack (number)
    * quality - Quality of the item (number, itemQuality)
    * isUsable - 1 if the player can use or equip the item; otherwise nil (1nil)
	More GHI Stuff]]
	
	function GHU_QL:GetQuestLogChoiceInfo(i)
	return self.orig.GetQuestLogChoiceInfo(i)
	end


	---Unsure on the following
	--[[
	Returns the talent point reward for the selected quest in the quest log. Returns 0 for quests which do not award talent points.

(Very few quests award talent points; currently this functionality is only used within the Death Knight starting experience.)

Signature:

talents = GetQuestLogRewardTalents()

Returns:

    * talents - Number of talent points to be awarded upon completing the quest (number)

	Returns the talent point reward for the selected quest in the quest log. Returns 0 for quests which do not award talent points.

(Very few quests award talent points; currently this functionality is only used within the Death Knight starting experience.)

Signature:

talents = GetQuestLogRewardTalents()

Returns:

    * talents - Number of talent points to be awarded upon completing the quest (number)

	
	]]
	
function GHU_QL:ExpandQuestHeader(i)
	self = gself
	if self.shown then
		if i > 0 then
			(self.headers[self.index[i].name] or {}).isCollapsed = nil;
		else --its zero so we need to make sure we collapse our headers
			for i=1,table.getn(self.index) do
				(self.headers[self.index[i].name] or {}).isCollapsed = nil;
			end
		end
		self:MaintainIndex();
		return;
	else
		return self.orig.ExpandQuestHeader();
	end
end

function GHU_QL:CollapseQuestHeader(i)
	self = gself
	if self.shown then
		if i > 0 then
			(self.headers[self.index[i].name] or {}).isCollapsed = 1;
		else --its zero so we need to make sure we collapse our headers
			for i=1,table.getn(self.index) do
				(self.headers[self.index[i].name] or {}).isCollapsed = 1;
			end
		end
		self:MaintainIndex()
		return;
	else
		return self.orig.CollapseQuestHeader();--fun fact, initially this does not return ANYTHING
	end
end

--======================================================--other

function GHU_QL:GetNumTotalGHUQuests()
local qt= {}


		
print(self.orig.GetNumQuestLogEntries())
for k,v in pairs(self.quests) do

if not (self.quests[k].isHeader == 1) then
tinsert(qt, self.quests[k])--serpeate quest headers from quests, put quests in temp table
end
end


	--print("Num entries:"..table.getn(self.quests or {}).."NumQuests:"..table.getn(qt or {}))
	return table.getn(self.quests or {}),table.getn(qt or {});
end

function GHU_QL:AddQuest(refID,qTitle,lvl,tag,group,header,comp,daily)
	
	-- the id needs to be an integer for the originial ui to regronice it. Since we also use id's to let the addon programmer using GHU identify his quest, it is nessesary to make sure that it is checked.
	assert(type(refID)=="number" or type(refID)=="string",format("ID of a quest must be a number or string. Got %s.",type(id)));
	assert(type(lvl)=="number","Level must be a number");
	assert(type(header)=="string","Header must be a string");
	assert(type(qTitle)=="string","Quest title must be a string");
	
	-- Let header be the name of the header. In that way it shall check if the header exsists and add it if it dosent.
	
	
	local t = {
	questTitle = qTitle,
	 level=lvl, 
	 questTag=tag, 
	 suggestedGroup=group,
	 headerName=header,
    -- isCollapsed=nil,	 
	 isComplete= comp, 
	 isDaily= daily,
	 refID = refID,
	}
	local t2 = self.quests or {};
	--table.insert(t2,t)
	--print(refID);
	t2[refID] = t;
	self.quests = t2;

	--QuestLog_Update();
	self:MaintainHeaders();
end

function GHU_QL:AddText(refID,questDescription, questObjectives,progress,finish)
--I am putting this here unless theres another idea on howe to do it.

local qtexts = self.quests;
local t = {questDescription = questDescription,questObjectives = questObjectives,progress = progress,finish=finish}
--print(qtexts);
qtexts[refID] = t;
self.quests = qtexts;

end


function GHU_QL:AddObj(refID,objID,objType,tarText,tarValue)
--objtype can be kill, explore, escort and so o.
--tartext what to kill,explore or escort,
--tarvalue relavent to anything but explore, or how many to kill.
--objID is a referance to the Objective so you can have more then one
local t ={};
 t[objID] = {
objType = objType,
tarText = tarText,
tarValue = tarValue,
isComplete = nil,
  }



--print(refID)
 local t2 = self.quests or {};
	t2[refID].objective = {};
	t2[refID].objective[objID] = t[objID];
	self.quests = t2;

--print("--------")
--GHI_PrintArray(self.quests[refID].objective);
--print("--------")
 
end

function GHU_QL:AddReward(refID,rewardID,GHIID,GHINew)
--Can do this one of two ways, Either set it to use a current GHI Item
--or call the function to make a new one,
--thus i am currently including GHINew (nill or 1 value)
--The item would only be made when the quest in comepleted however.
--need a check to give one or all rewards

local t = {

rewardID = {
GHIID = GHIID,
GHINew = GHINEW,
}

}
 local t2 = {} or self.quests
 t2[refID].rewards = t;
 self.quests = t2;

 
end

-- Internal
function GHU_QL:CheckObjComplete(refID)
--checks for completed objectives
local obj = self.quests.refID.objective
print(obj);
if type(obj) == "table" then 
  for k,v in pairs(obj) do
     if obj[k].objType == "Explore" and obj.isComplete == nil then
	   if obj[k].tarText == GetSubZoneText() then
	    obj[k].isComplete = 1;
		end
	
	 end
  end
  
  --i am kind of setting up an example here cuase the others might need a bit more thought.
end

end



function GHU_QL:MaintainHeaders()-- also maintains order
	local oldHeaders = self.headers or {};
	self.headers = {};
	for i,quest in pairs(self.quests) do
		local t = self.headers[quest.headerName] or {};
		local inserted = false;
		for i=1,table.getn(t) do -- go trough all quests for the header
			if quest.level < t[i].level and inserted == false then
				table.insert(t,i,{refID = quest.refID,level = quest.level,name = quest.name,isCollapsed = quest.isCollapsed});
				inserted = true;
				break;
			elseif quest.level == t[i].level and strbyte(quest.name) <= strbyte(t[i].name) and inserted == false then
				table.insert(t,i,{refID = quest.refID,level = quest.level,name = quest.name,isCollapsed = quest.isCollapsed});
				inserted = true;
				break;
			end
		end
		if inserted == false then
			table.insert(t,{refID = quest.refID,level = quest.level,isCollapsed = quest.isCollapsed});
		end
		self.headers[quest.headerName] = t; 
		
		-- Insert info if the header is collapsed or not.
		self.headers[quest.headerName].isCollapsed = (oldHeaders[quest.headerName] or {}).isCollapsed
		
	end
	
	self:MaintainIndex()
	
end

function GHU_QL:MaintainIndex()
	-- todo: save the selected index refID and the select the new one after maintaince
	self.index = {};
	for header,quests in pairs(self.headers) do
		if type(quests)=="table" then
			table.insert(self.index,{name = header,isCollapsed = self.headers[header].isCollapsed});
			if self.headers[header].isCollapsed == nil then
				for i=1,table.getn(quests) do
					table.insert(self.index,{refID = quests[i].refID, name = self.quests[quests[i].refID].questTitle,isCollapsed = self.quests[quests[i].refID].isCollapsed});
				end
			end
		end
	end
end


function GHUTQL()
local q = GHU_New("QuestLog","TEST")
--print(q.questID);
--local id = q.questID;
--print(id);
q:GetNumTotalGHUQuests();
q:AddQuest("17","Title1",30,"Dungeon",3,"Examples",1,nil);
	q:AddQuest("18","Title2",50,nil,nil,"Examples",nil,-1);
	q:AddQuest("19","Title3",10,nil,nil,"Elwynn",-1,nil);
q:Show();
q:GetNumTotalGHUQuests();
end

--[[npc funcs
     GetActiveLevel(index) - Gets the level of an active quest (only available after QUEST_GREETING event). 
    GetActiveTitle(index) - Gets the title of an active quest (only available after QUEST_GREETING event). 
    GetAvailableLevel(index) - Gets the level of an available quest (only available after QUEST_GREETING event). 
    GetAvailableTitle(index) - Gets the title of an available quest (only available after QUEST_GREETING event). 
    GetGreetingText() 
    GetNumActiveQuests - Gets the number of currently active quests from this NPC (only available after QUEST_GREETING event). 
    GetNumAvailableQuests - Gets the number of currently available quests from this NPC (only available after QUEST_GREETING event). 
	    event). 
    GetNumQuestChoices - Returns the number of rewards available for choice for quest currently in gossip window. 
    GetNumQuestItems - Returns the number of items necessary to complete a particular quest. 
	
	plus some i am unsure of
	
	
	]]
