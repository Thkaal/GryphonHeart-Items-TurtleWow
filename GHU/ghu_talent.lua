
GHU_Talent = {}
GHU_Talent.__index = GHU_Talent;
GHU_Talent.hooked ={};

-- 	standard
function GHU_Talent:Create(varName,name,icon)
		
	setglobal(varName,GHU_Talent); 
	
	local obj = {}             -- our new object
	setmetatable(obj, getglobal(varName))  -- make GHU_Talent handle lookup
	
	obj.tabs = {};
	obj.unspentPoints = 0;
	obj.SHOW_INSCRIPTION_LEVEL = SHOW_INSCRIPTION_LEVEL;
	obj.previewTalents = GetCVarBool("previewTalents");
	obj.name = name;
	
	GHU_Tabs:NewTab("Talent",obj,name,icon)
	
	setglobal(varName,obj);
	
	obj:InitHooks(varName);  
end
	
function GHU_Talent:Hook(funcName,varName)
	
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

function GHU_Talent:InitHooks(varName)
	if not PlayerTalentFrame then self.isHooked=true; return; end
	if not(self.isHooked) then
		local obj = getglobal(varName);
		
		self:Hook("GetNumTalentTabs",varName)
		self:Hook("GetTalentTabInfo",varName)
		self:Hook("GetNumTalents",varName)
		self:Hook("GetTalentInfo",varName)
		self:Hook("GetTalentPrereqs",varName)
		self:Hook("LearnTalent",varName)
		self:Hook("TalentFrame_Update",varName)
		self:Hook("GetActiveTalentGroup",varName)
		self:Hook("GetUnspentTalentPoints",varName)
		self:Hook("GetGroupPreviewTalentPointsSpent",varName)
				
		self.fName = varName;
				
		self.isHooked = true;
	end
end

function GHU_Talent:InitHooksAfterLoad(varName)
	if not(self.isHookedAfterLoad) then
				
		self:Hook("PlayerTalentFrameTalent_OnEnter",varName) -- needs to be loaded
		self:Hook("PlayerTalentFrameTalent_OnClick",varName)
		
		-- setup talent buttons
		local button;
		for i = 1, MAX_NUM_TALENTS do
			button = getglobal("PlayerTalentFrameTalent"..i);
			if ( button ) then
				button:SetScript("OnClick", PlayerTalentFrameTalent_OnClick);
				button:SetScript("OnEvent", PlayerTalentFrameTalent_OnEvent);
				button:SetScript("OnEnter", PlayerTalentFrameTalent_OnEnter);
			end
		end
						
		self.isHookedAfterLoad = true;
	end
end

-- ======================== Show / Hide ========================
function GHU_Talent:Show()
	self.shown = 1;
	-- set glyph level
	SHOW_INSCRIPTION_LEVEL = 255;
	SetCVar("previewTalents",nil);
	
	if PlayerTalentFrame_OnShow then 
		PlayerTalentFrame_OnShow(); 
		PlayerTalentFrameTitleText:SetText(self.name);
		PlayerTalentFrameStatusFrame:Hide();
	end
end

function GHU_Talent:Hide()
	self.shown = nil;
	-- set glyph back
	SHOW_INSCRIPTION_LEVEL = self.SHOW_INSCRIPTION_LEVEL;
	SetCVar("previewTalents",self.previewTalents);
	
	
	if PlayerTalentFrame_OnShow then PlayerTalentFrame_OnShow(); end
end

-- ======================== Hooks ========================
-- GetNumTalentTabs([inspect[,pet]])
function GHU_Talent:GetNumTalentTabs(inspect,pet)
	self = gself;
	if self.shown and not(inspect) and not(pet) and not(GHU_Tabs.settingTalentTabs) then
		return table.getn(self.tabs);
	end
	return self.orig.GetNumTalentTabs(inspect,pet);
end

-- GetTalentTabInfo(tabIndex[,inspect][,isPet][, groupIndex])
-- name, iconTexture, pointsSpent, background, previewPointsSpent
function GHU_Talent:GetTalentTabInfo(tabIndex,inspect,pet,groupIndex) -- problem. This is both used for the side tabs, but also to get the name.
	self = gself;
	
	if self.shown and not(inspect) and not(pet) and not(GHU_Tabs.settingTalentTabs) then
		local t = self.tabs[tabIndex];
		if type(t) == "table" then
			return t.name,"",t.pointsSpent,t.background,0;
		end
		return;
	end
	return self.orig.GetTalentTabInfo(tabIndex,inspect,pet,groupIndex);
end

-- GetNumTalents(tabIndex[,inspect[,pet]])
function GHU_Talent:GetNumTalents(tabIndex,inspect,pet)
	self = gself;
	if self.shown and not(inspect) and not(pet) then
		if type(self.tabs[tabIndex])=="table" then
			return table.getn(self.tabs[tabIndex].talents);
		end
		return 0;
	end
	return self.orig.GetNumTalents(tabIndex,inspect,pet);
end

-- GetTalentInfo(tabIndex[,inspect][,isPet][, groupIndex])
-- return name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq.
function GHU_Talent:GetTalentInfo(tabIndex,talentIndex,inspect,pet, groupIndex)
	self = gself;
	if self.shown and not(inspect) and not(pet) then
		if type(self.tabs[tabIndex])=="table" then
			local t = self.tabs[tabIndex].talents[talentIndex];
			if type(t)=="table" then
				local a,_,meetsPrereq = self:GetTalentPrereqs(tabIndex,talentIndex);
				if not(a) then meetsPrereq = true; end
				
				return t.name, t.icon, t.tier, t.column, t.currentRank, t.maxRank, 1, meetsPrereq,t.currentRank,meetsPrereq;
			end			
		end
		return nil;
	end
	return self.orig.GetTalentInfo(tabIndex,talentIndex,inspect,pet, groupIndex);
end

-- GetTalentPrereqs(tabIndex,talentIndex[,inspect] [, groupIndex])
--return tier, column, isLearnable
function GHU_Talent:GetTalentPrereqs(tabIndex,talentIndex,inspect, groupIndex)
	self = gself;
	if self.shown and not(inspect) then
		if type(self.tabs[tabIndex])=="table" then
			local t = self.tabs[tabIndex].talents[talentIndex];
			if t then
				local tabI2,talentI2 = self:GetIndex(self.tabs[tabIndex].tabRefID,t.preReqRefID);
				assert(tabI2 == tabIndex,"Found in other tab incorrectly.");
				if talentI2 then
					local t2 = self.tabs[tabI2].talents[talentI2];
					return t2.tier,t2.column,(t2.currentRank == t2.maxRank and 1 or nil);
				end
			end
		end
		return;
	end
	return self.orig.GetTalentPrereqs(tabIndex,talentIndex,inspect, groupIndex);
end

-- LearnTalent(tabIndex,talentIndex) 
function GHU_Talent:LearnTalent(tabIndex,talentIndex)
	self = gself;
	if self.shown then
		if self.learnFunction and type(self.tabs[tabIndex])=="table" and type(self.tabs[tabIndex].talents[talentIndex])=="table" then
			self.learnFunction(self.tabs[tabIndex].tabRefID,self.tabs[tabIndex].talents[talentIndex].refID);
		end
		return;
	end
	return self.orig.LearnTalent(tabIndex,talentIndex);
end

-- todo: hook the update frame to insert a custom background.
function GHU_Talent:TalentFrame_Update(TalentFrame)
	self = gself;
	self.orig.TalentFrame_Update(TalentFrame);
	
	-- set up custom background
	if self.shown then
		local selectedTab = PanelTemplates_GetSelectedTab(TalentFrame);
		local talentFrameName = TalentFrame:GetName();
		local name, icon, pointsSpent, background, previewPointsSpent = GetTalentTabInfo(selectedTab, TalentFrame.inspect, TalentFrame.pet,TalentFrame.talentGroup);
		if background and string.sub(string.upper(background),0,9) == "INTERFACE" then -- a custom background
			base = background.."-";
			local backgroundPiece = getglobal(talentFrameName.."BackgroundTopLeft");
			backgroundPiece:SetTexture(base.."TopLeft");
			SetDesaturation(backgroundPiece, false);
			backgroundPiece = getglobal(talentFrameName.."BackgroundTopRight");
			backgroundPiece:SetTexture(base.."TopRight");
			SetDesaturation(backgroundPiece, false);
			backgroundPiece = getglobal(talentFrameName.."BackgroundBottomLeft");
			backgroundPiece:SetTexture(base.."BottomLeft");
			SetDesaturation(backgroundPiece, false);
			backgroundPiece = getglobal(talentFrameName.."BackgroundBottomRight");
			backgroundPiece:SetTexture(base.."BottomRight");
			SetDesaturation(backgroundPiece, false);

		end
	end
end


function GHU_Talent:GetActiveTalentGroup(inspect,pet)
	self = gself;
	if self.shown and not(inspect) and not(pet) then
		if PlayerTalentFrame then
			return PlayerTalentFrame.talentGroup
		end
		return 1;
	end
	return self.orig.GetActiveTalentGroup(inspect,pet);
end

function GHU_Talent:GetUnspentTalentPoints(inspect,pet,group)
	self = gself;
	if self.shown and not(inspect) and not(pet) then
		return self.unspentPoints or 0;
	end
	return self.orig.GetUnspentTalentPoints(inspect,pet,group);
end

function GHU_Talent:GetGroupPreviewTalentPointsSpent(pet,group)
	self = gself;
	if self.shown and not(pet) then
		return 0;
	end
	return self.orig.GetGroupPreviewTalentPointsSpent(pet,group);
end

function GHU_Talent:PlayerTalentFrameTalent_OnEnter(b)
	self = gself;
	if self.shown and not(PlayerTalentFrame.inspect) and not(PlayerTalentFrame.pet) then
		self:SetTooltip(b);
		return;	
	end
	return self.orig.PlayerTalentFrameTalent_OnEnter(b);
end

function GHU_Talent:PlayerTalentFrameTalent_OnClick(s, button)
	self = gself;
	if self.shown and not(PlayerTalentFrame.inspect) and not(PlayerTalentFrame.pet) then
		if button == "LeftButton" then
			local talI = s:GetID();
			local tabI = PanelTemplates_GetSelectedTab(PlayerTalentFrame);
			local tal = self.tabs[tabI].talents[talI];
			
			if tal.preReqRefID then
				local tabI2,talentI2 = self:GetIndex(self.tabs[tabI].tabRefID,tal.preReqRefID);
				assert(tabI2 == tabI,"Found in other tab incorrectly.");
				if talentI2 then
					local tal2 = self.tabs[tabI2].talents[talentI2];
					if not(tal2.currentRank == tal2.maxRank) then
						return;
					end
				end
			end
			
			if not((self.tabs[tabI].pointsSpent or 0) >= (tal.tier-1) * 5) then
				return;
			end
			
			if self.learnFunction then
				self.learnFunction(self.tabs[tabI].tabRefID,self.tabs[tabI].talents[talI].refID);
			end
		end
		return
	end
	return self.orig.PlayerTalentFrameTalent_OnClick(s, button);
end

-- ======================== Set API ========================

function GHU_Talent:AddTab(tabRefID,name,background)
	-- validate input
	assert(type(tabRefID)=="string" or type(tabRefID)=="number","Illigal tabRefID");
	assert(type(name)=="string","Illigal name.");
	assert(type(background)=="string","Illigal background. Got "..type(background)..".");
	-- insert
	local t = {
		["tabRefID"] = tabRefID,
		["name"] = name,
		["background"] = background,
		["pointsSpent"] = 0;
		["talents"] = {};
	}
	table.insert(self.tabs,t);
end

function GHU_Talent:AddTalent(tabRefID,refID,name,icon,tier,column,maxRank,preReqRefID)
	-- validate input
	assert(type(refID)=="string" or type(refID)=="number","Illigal refID");
	assert(type(tabRefID)=="string" or type(tabRefID)=="number","Illigal tabRefID");
	assert(type(name)=="string","Illigal name.");
	assert(type(icon)=="string","Illigal icon.");
	assert(type(tier)=="number","Illigal tier.");
	assert(type(column)=="number" and column > 0 and column < 5,"Illigal column.");
	assert(type(maxRank)=="number","Illigal maxRank.");
	
	local tabI,talentI = self:GetIndex(tabRefID,refID);
	assert(tabI,"Tab not found.");
	assert(not(talentI),"Talent already inserted");
	-- insert
	local t = {
		["refID"] = refID,
		["name"] = name,
		["icon"] = icon,
		["currentRank"] = 0,
		["maxRank"] = maxRank,
		["preReqRefID"] = preReqRefID,
		["tier"] = tier,
		["column"] = column,
		["description"] = "",
		["whiteText"] = {},
	}
	table.insert(self.tabs[tabI].talents,t);
end

function GHU_Talent:SetUnspentPoints(points)
	assert(type(points)=="number","Unspend points must be a number");
	self.unspentPoints = points;
end

function GHU_Talent:SetSpentPoints(tabRefID,points)
	assert(type(tabRefID)=="string" or type(tabRefID)=="number","Illigal tabRefID");
	assert(type(points)=="number","Spent points must be a number");
	local tabI = self:GetIndex(tabRefID);
	assert(tabI,"Tab not found.");
	self.tabs[tabI].pointsSpent = points;
end

function GHU_Talent:SetCurrentRank(tabRefID,refID,points)
	assert(type(tabRefID)=="string" or type(tabRefID)=="number","Illigal tabRefID");
	assert(type(refID)=="string" or type(refID)=="number","Illigal refID");
	assert(type(points)=="number","Points must be a number");
	local tabI,talentI = self:GetIndex(tabRefID,refID);
	assert(tabI and talentI,"Talent dosent exsist");
	self.tabs[tabI].talents[talentI].currentRank = points;
	
	local newTotal = 0;
	for i,talent in pairs(self.tabs[tabI].talents) do
		newTotal = newTotal + (talent.currentRank or 0);
	end
	self:SetSpentPoints(tabRefID,newTotal);
	TalentFrame_Update(PlayerTalentFrame);
	PlayerTalentFrameTitleText:SetText(self.name);
	self:UpdateEvtTooltip();
end

function GHU_Talent:SetLearnFunction(f)
	assert(type(f)=="function","Not a function as argument for learn function");
	self.learnFunction = f;
end

function GHU_Talent:SetTalentDetails(tabRefID,refID,description,...)
	assert(type(refID)=="string" or type(refID)=="number","Illigal refID");
	assert(type(tabRefID)=="string" or type(tabRefID)=="number","Illigal tabRefID");
	assert(type(description)=="string","Illigal description.");
	
	local tabI,talentI = self:GetIndex(tabRefID,refID);
	assert(tabI,"Tab not found.");
	assert(talentI,"Talent not found.");
	
	local t = arg;
	local whiteText = {};
	local i = 1;
	while i <= table.getn(t) do
		table.insert(whiteText,{t[i],t[i+1]});
		i = i + 2;
	end
	
	self.tabs[tabI].talents[talentI].description = description;
	self.tabs[tabI].talents[talentI].whiteText = whiteText;
end

function GHU_Talent:Clear()
	if self.shown then
		self.Hide();
	end
	self.tabs = {};
	self.unspentPoints = 0;
end

-- ======================== Internal API ========================
function GHU_Talent:GetIndex(tabRefID,refID)
	assert(type(tabRefID)=="number" or type(tabRefID)=="string","Illigal tab ref");
	for i=1,table.getn(self.tabs) do
		if self.tabs[i].tabRefID == tabRefID then
			if refID then
				for j=1,table.getn(self.tabs[i].talents) do
					if self.tabs[i].talents[j].refID == refID then
						return i,j;
					end
				end
			end
			return i;
		end
	end
	return nil;
end

function GHU_Talent:SetTooltip(b)
	local i = b:GetID();
	local t = PanelTemplates_GetSelectedTab(PlayerTalentFrame);
	local tal = self.tabs[t].talents[i];
	
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT");
	GameTooltip:AddLine(tal.name,1,1,1);  -- GameTooltipHeader?
	
	-- rank
	GameTooltip:AddLine(format(TOOLTIP_TALENT_RANK,tal.currentRank,tal.maxRank),1,1,1);
	
	-- reqiorement from prereq (TOOLTIP_TALENT_PREREQ)
	if tal.preReqRefID then
		local tabI2,talentI2 = self:GetIndex(self.tabs[t].tabRefID,tal.preReqRefID);
		assert(tabI2 == t,"Found in other tab incorrectly.");
		if talentI2 then
			local tal2 = self.tabs[tabI2].talents[talentI2];
			if not(tal2.currentRank == tal2.maxRank) then
				GameTooltip:AddLine(format(TOOLTIP_TALENT_PREREQ,tal2.maxRank,tal2.name),1,0,0,1,1);
			end
		end
	end
	
	-- requirement tier  ( TOOLTIP_TALENT_TIER_POINTS)
	if not((self.tabs[t].pointsSpent or 0) >= (tal.tier-1) * 5) then
		GameTooltip:AddLine(format(TOOLTIP_TALENT_TIER_POINTS,(tal.tier-1) * 5,self.tabs[t].name),1,0,0,1,1);
	end
	
	
	-- white text
	for i,p in pairs(tal.whiteText) do
		if type(p)=="table" then
			GameTooltip:AddDoubleLine(p[1] or "",p[2] or "",1,1,1,1,1,1,1,1,1,1);
		end
	end
	
	-- description
	GameTooltip:AddLine(tal.description,1, 0.82, 0,  1, 1);

	GameTooltip:Show();
	
end

function GHU_Talent:UpdateEvtTooltip()
	if self.shown then
		if GameTooltip:GetOwner() and GameTooltip:GetOwner():GetName() then
			if string.sub(GameTooltip:GetOwner():GetName() or "",0,23) == "PlayerTalentFrameTalent" then
				self:SetTooltip(GameTooltip:GetOwner())
			end
		end
	end
end

-- === temp test
--tt = GHU_New("Talent","Test","");
--tt:AddTab("T1","Test 1","RogueCombat");
--tt:AddTalent("T1","ta1","Testing","Interface\\Icons\\Ability_Marksmanship",1,3,5)


