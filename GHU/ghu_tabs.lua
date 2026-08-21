
GHU_Tabs = CreateFrame("Frame");
GHU_Tabs.hooked ={};

-- unlike the other ghu modules, the tabs is not a copyable class. There shall only be one.

function GHU_Tabs:NewTab(tabType,obj,name,icon)
	if tabType == "Talent" then
		self:RegisterTalentTab(obj,name,icon)
	else
		error(format("Illigal tab type %S.",tabType));
	end
end


function GHU_Tabs:OnEvent(event,arg1,arg2,arg3)

	if event == "ADDON_LOADED" and arg1 == "Blizzard_TalentUI" then
		self:SetupTalentTabs()
	end

end

GHU_Tabs:SetScript("OnEvent", function() GHU_Tabs:OnEvent(event,arg1,arg2,arg3); end);
GHU_Tabs:RegisterEvent("ADDON_LOADED");

function GHU_Tabs:Hook(funcName)
	local varName = "GHU_Tabs";
	if not(type(self.orig)=="table") then self.orig ={}; end
	assert(type(self[funcName])=="function","No function found for "..funcName);
	assert(type(getglobal(funcName))=="function","Original function not found for "..funcName)
	self.orig[funcName] = getglobal(funcName);
		
	local hookObject = getglobal(varName);
	hookObject.hooked[funcName] = function(...)
		gself = getglobal(varName);
		local hookTarget = getglobal(varName);
		return hookTarget[funcName](hookTarget, unpack(arg));
	end
	setglobal(funcName,getglobal(varName)["hooked"][funcName]);
end



-- ============= Talent tabs ==============
local talentTabs = {};
local talentsHooked = false;
function GHU_Tabs:RegisterTalentTab(obj,name,icon)
	assert(type(obj.Show)=="function","Object does not have a show function");
	assert(type(obj.Hide)=="function","Object does not have a show function");
	
	local t = {
		["name"] = name,
		["icon"] = icon,
		["obj"] = obj,
	};
	table.insert(talentTabs,t);
	
end

function GHU_Tabs:SetupTalentTabs() -- this should first be run when the talent tab is initialized and loaded.
	if talentsHooked == false and PlayerTalentFrame and table.getn(talentTabs) > 0 then
		
		self:Hook("PlayerTalentFrame_UpdateSpecs");
		self:Hook("PlayerSpecTab_OnClick");
		
		for i,v in pairs(talentTabs) do
			v.obj:InitHooksAfterLoad(v.obj.fName);
		end
		
		talentsHooked = true;
	end
end

GHU_Tabs.TalentButtons = {};

function GHU_Tabs:PlayerTalentFrame_UpdateSpecs(a,b,c,d)
	GHU_Tabs.settingTalentTabs = 1;
	local res = GHU_Tabs.orig.PlayerTalentFrame_UpdateSpecs(a,b,c,d);
	GHU_Tabs.settingTalentTabs = nil;	
	
	-- all needed group tabs is visiable now
	local shown;
	if not(PlayerSpecTab1:IsShown()) then
		shown = 0;
	elseif not(PlayerSpecTab2:IsShown()) and not(PlayerSpecTab3:IsShown()) then -- should not happend
		shown = 1;
	elseif (PlayerSpecTab2:IsShown()) and (PlayerSpecTab3:IsShown()) then -- hunter with pet and duel spec
		shown = 3;
	else -- either dual spec or pet shown
		shown = 2;
	end
	
	--]]
	
	
	-- if there is 0 tabs shown, then it is nessesary to show a tab for the original spec
	local displayFirst;
	if shown == 0 then
		shown = 1;
		PlayerSpecTab1:Show();
	else
	
	end
	-- create needed frames if they are not already created.
	-- update the id for the custom frames
	for i=1,max(shown + table.getn(talentTabs),table.getn(GHU_Tabs.TalentButtons)) do
		local f = GHU_Tabs:CreateExtraTalentTab(i);
		if i==1 and displayFirst then
			--f:Show();
			--f.talentI = 0;
			
		elseif i <= shown then
			f:Hide();
			f.talentI = 0;
		else
			f:Show();
			f.talentI = i - shown;
			local tex = f:GetNormalTexture();
			tex:SetTexture(talentTabs[f.talentI].icon);
		end
		
	end
	
	return res;
end

function GHU_Tabs:PlayerSpecTab_OnClick(self, button, down)
	if not(GHU_Tabs.clickingTab) then
		GHU_Tabs.clickingTab = 1;
		GHU_Tabs:SelectTalentTab(0);
		
	end
	GHU_Tabs.clickingTab = nil;
	
	return GHU_Tabs.orig.PlayerSpecTab_OnClick(self, button, down);
end

function GHU_Tabs:TalentTabOnEnter(self)
	
	
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:AddLine(talentTabs[self.talentI].name);
	GameTooltip:Show();
end

function GHU_Tabs:CreateExtraTalentTab(num) -- num refers to its position
	assert(type(num)==	"number" and num > 0,"Tab must have a number");
	if not(self.TalentButtons[num]) then
		local f = CreateFrame("CheckButton","GHU_TalentTab"..num,PlayerTalentFrame,"PlayerSpecTabTemplate");
		if num == 1 then -- will not happend
			f:SetPoint("CENTER","PlayerSpecTab1","CENTER");
		else
			f:SetPoint("TOPLEFT",self.TalentButtons[num-1],"BOTTOMLEFT",0,-22);
		end
		
		f:SetScript("OnClick",function() GHU_Tabs:SelectTalentTab(this.talentI or 0); end);
		f:SetScript("OnEnter",function() GHU_Tabs:TalentTabOnEnter(this); end);
		
		self.TalentButtons[num] = f;
	end
	return self.TalentButtons[num];
end

function GHU_Tabs:SelectTalentTab(num) -- 0 is original
	for i,b in pairs(self.TalentButtons) do
				
		if b.talentI == num then
			b:SetChecked(1);
		else
			b:SetChecked(nil);
		end
	end
	for i=1,table.getn(talentTabs) do
		if i == num then
			-- do later, since all other tabs need to be hidden before the new one is shown (due to global set of glyph value)
			
		else
			talentTabs[i].obj:Hide();
			
		end
	end
	if type(talentTabs[num])=="table" then
		talentTabs[num].obj:Show(); --talentTabs[num]);
	end
	
	if not(num==0) then
		PlayerSpecTab1:SetChecked(nil);
		PlayerSpecTab2:SetChecked(nil);
		PlayerSpecTab3:SetChecked(nil);
	end
	
end

