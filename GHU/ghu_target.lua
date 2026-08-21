

GHU_Target = CreateFrame("Frame");
GHU_Target.__index = GHU_Target;
GHU_Target.hooked ={};

GHU_Target.buttons = {};

-- 	standard
function GHU_Target:Create(varName)
	
	setglobal(varName,GHU_Target);	-- there is no need for more than one object
end

function GHU_Target:OnEvent()
	if self.mainButton then
		if UnitExists("target") and UnitIsPlayer("target") and UnitFactionGroup("target") == UnitFactionGroup("player")  then
			self.mainButton:Show();
		else
			self.mainButton:Hide();	
		end
	end
end
GHU_Target:SetScript("OnEvent", function() GHU_Target:OnEvent(); end);
GHU_Target:RegisterEvent("PLAYER_TARGET_CHANGED");



local function CreateTargetButton(name)
	--local button = CreateFrame("Button", name, UIParent, "SecureHandlerClickTemplate")
	local button = CreateFrame("Button", name, UIParent)
	button:SetHeight(33);
	button:SetWidth(33);

	local overlay = button:CreateTexture(nil, "OVERLAY");
	overlay:SetWidth(56);
	overlay:SetHeight(56);
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder");
	overlay:SetPoint("TOPLEFT", 0, 0);
	button.overlay = overlay;
	
	local icon = button:CreateTexture(nil,"BACKGROUND");
	icon:SetWidth(18);
	icon:SetHeight(18);
	icon:SetTexture("Interface\\AddOns\\GHU\\Textures\\GH_RoundIcon")
	icon:SetPoint("TOPLEFT", 8, -8);
	icon:SetTexCoord(.075,.925,.075,.925)
	button.icon = icon;
	
	-- Vanilla 1.12 has no PreClick script; play the click sound on mouse down instead.

	button:SetFrameStrata("MEDIUM");
	button:SetFrameLevel(8);
	button:Hide();
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	
	button:SetScript("OnMouseDown", function() PlaySound("igMainMenuOptionCheckBoxOn"); this.icon:SetTexCoord(0,1,0,1); end);
	button:SetScript("OnMouseUp", function() this.icon:SetTexCoord(.075,.925,.075,.925); end);
	return button;
end

function GHU_Target:AddButton(refID,icon,tooltipFunc,clickFunc,targetType)
	
	assert(type(refID)=="string" or type(refID)=="number","RefID must be a number or string.");
	assert(self.buttons[refID] == nil,format("Button %s already made",refID));
	
	self:SetUpMainButton();
	
	local button = CreateTargetButton("GHU_TargetButton"..refID);	
	
	button:SetParent(self.mainButton);
	
	button:SetScript("OnEnter", tooltipFunc)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	button:SetScript("OnClick", clickFunc)
	
	self.buttons[refID] = button;
	
	
	self:ChangeButtonSetup();
	
end

function GHU_Target:SetUpMainButton()
	if not(self.mainButton) then
		
		local button = CreateTargetButton("GHU_MainTargetButton");
		button:RegisterForDrag("LeftButton")
		button:SetMovable();
		
		button:SetScript("OnUpdate", function() this.obj:UnitIconButtonIconMove(); end)
		button:SetScript("OnDragStart", function() this.obj.iconDrag = true; end)
		button:SetScript("OnDragStop", function() this.obj.iconDrag = false; end)
		button:SetScript("OnLeave", function() GameTooltip:Hide() end)	
		
			
		
		button.obj = self;
			
		self.mainButton = button;
		
		self:UnitIconButtonIconMove((GHU_MiscData or {})["TargetButtonPos"] or {UIParent:GetWidth()/2,UIParent:GetHeight()/2});
	end
end

function GHU_Target:NumButtons()
	local c = 0;
	for _,b in pairs(self.buttons) do
		c = c+1;
	end
	return c;
end

function GHU_Target:ChangeButtonSetup()
	
	if self:NumButtons() == 1 then
		-- hide button one
		local button;
		for ref,b in pairs(self.buttons) do
			b:Hide();
			button = b;
		end		
		
		-- set up main button with its info
		self.mainButton:SetScript("OnEnter", button:GetScript("OnEnter"));
		self.mainButton:SetScript("OnClick", button:GetScript("OnClick"));
		
		-- set up button to have texture as the buttens texture
		--self.mainButton:SetNormalTexture("Interface\\Addons\\GHT\\Textures\\GHT-TargetButtonUp");
		--self.mainButton:SetPushedTexture("Interface\\Addons\\GHT\\Textures\\GHT-TargetButtonDown");
		
	else
		-- set up main button to only have main button into
		self.mainButton:SetScript("OnEnter", function() 
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
			GameTooltip:ClearLines()
			GameTooltip:AddLine("Click to toggle buttons.",1,0.8196079,0);
			GameTooltip:Show()
			this.UpdateTooltip = nil;
		end);
		self.mainButton:SetScript("OnClick", function() if arg1 == "LeftButton" then this.obj:Toggle(); end; end);
		--self.mainButton:SetNormalTexture("Interface\\Addons\\GHT\\Textures\\GHT-TargetButtonUp");
		--self.mainButton:SetPushedTexture("Interface\\Addons\\GHT\\Textures\\GHT-TargetButtonDown");
		
		
		-- place icons around main icon and show them
		
	end
end

function GHU_Target:Toggle()
	if self:NumButtons() > 1 then
		for i,btn in pairs(self.buttons) do
			btn:Show();
		end
		
	end
end

function GHU_Target:UnitIconButtonIconMove(iconpos)
	
		
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
		local s = self.mainButton:GetEffectiveScale();
		
		xpos, ypos = x/s, y/s;
		
	end
	
	GHU_MiscData = GHU_MiscData or {};
	GHU_MiscData["TargetButtonPos"] = {xpos,ypos};
	
	-- Hide the tooltip
	GameTooltip:Hide();
	
	-- Set the position
		
	self.mainButton:SetPoint("CENTER", UIParent, "BOTTOMLEFT", xpos, ypos);
end


--	/script FFF = GHU_New("target"); FFF:AddButton("b1","",print,print); FFF.mainButton:Show(); FFF:AddButton("b21","",print,print);
