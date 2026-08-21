


GHU_NPC = {}
GHU_NPC.__index = GHU_NPC;
GHU_NPC.hooked ={};

-- 	standard
function GHU_NPC:Create(varName,name)
		
	setglobal(varName,GHU_NPC); 
	
	local obj = {}             -- our new object
	setmetatable(obj, getglobal(varName))  -- make GHU_NPC handle lookup
	obj.headerName = name;      -- initialize our object
	
	setglobal(varName,obj);
	
	obj:InitHooks(varName);  
	obj:NewCurrentNPC();
end
	
function GHU_NPC:Hook(funcName,varName)
	
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

function GHU_NPC:InitHooks(varName)
	if not(self.isHooked) then
		local obj = getglobal(varName);
		
		self:Hook("GetGossipOptions",varName)
		self:Hook("GossipFrame_OnEvent",varName)
		self:Hook("CloseGossip",varName)
		self:Hook("SelectGossipOption",varName)
		self:Hook("GetGossipText",varName)
		self:Hook("MerchantFrame_OnEvent",varName)
		self:Hook("MerchantFrame_OnShow",varName)
		--self:Hook("PlaySound",varName)
		
		self.isHooked = true;
	end
end


--	Hooks
function GHU_NPC:GossipFrame_OnEvent(o_self, event, ...)   ---	No longer used
	self = gself; -- give self info for hooked functions
	self.orig.GossipFrame_OnEvent(o_self, event, unpack(arg));
end

function GHU_NPC:CloseGossip()
	self = gself; -- give self info for hooked functions.
	if self:GetCurrentAllowVendor() == false then
		MerchantFrame_OnHide();
	end
	self:NewCurrentNPC();
end

function GHU_NPC:GetGossipOptions()
	self = gself; -- give self info for hooked functions.
	-- type:   banker, battlemaster, binder, gossip, healer, petition, tabard, taxi, trainer, unlearn, or vendor 
	--[[
	t={};
	table.insert(t,"SW Bank");
	table.insert(t,"banker");
	table.insert(t,"Join Battle");
	table.insert(t,"battlemaster");
	table.insert(t,"binder");
	table.insert(t,"binder");
	table.insert(t,"Want to hear something?");
	table.insert(t,"gossip");
	table.insert(t,"Heal me");
	table.insert(t,"healer");
	table.insert(t,"petition");
	table.insert(t,"petition");
	table.insert(t,"Gief Tabard");
	table.insert(t,"tabard");
	table.insert(t,"Get to dah choppah!");
	table.insert(t,"taxi");
	table.insert(t,"Train me!");
	table.insert(t,"trainer");
	table.insert(t,"unlearn");
	table.insert(t,"unlearn");
	table.insert(t,"Let me shop!");
	table.insert(t,"vendor");
	
	if true then return unpack(t); end --]]
	
	local orig_gossip = {self.orig.GetGossipOptions()};
	local name = UnitName("npc");
	local npc_i = self:FindNPC(name);
	if npc_i then
		local zone = self:GetZone(npc_i);
		if not(zone) or zone == GetRealZoneText() then
			local page,isOrig = self:GetCurrentPage();
			local t = {}; 
			for i=1,self:GetNumGossip(npc_i,page) do
				table.insert(t,self:GetGossipDetail(npc_i,page,i));
				table.insert(t,self:GetGossipType(npc_i,page,i));
			end
			local gossip = {};
			if isOrig == false or self:HideOrigGossip(npc_i,page) == true then
				gossip = t; 
			elseif self:ShowGossipFirst(npc_i) == true then
				gossip = t; 
				for i=1,table.getn(orig_gossip) do table.insert(gossip,orig_gossip[i]) end
			else
				gossip = orig_gossip; 
				for i=1,table.getn(t) do table.insert(gossip,t[i]) end
			end
			
			return unpack(gossip);
		end
	end
	return unpack(orig_gossip);
end

function GHU_NPC:SelectGossipOption(i)
	self = gself; -- give self info for hooked functions.
	local name = UnitName("npc");
	local npc_i = self:FindNPC(name);
	if npc_i and tonumber(i) then
		local zone = self:GetZone(npc_i);
		if not(zone) or zone == GetRealZoneText() then
			local page,isOrig = self:GetCurrentPage();
			local num_newGossip = self:GetNumGossip(npc_i,page);
			local orig_gossip = {self.orig.GetGossipOptions()};
			local num_origGossip = table.getn(orig_gossip);
			
			local new_i = nil;
			local orig_i = nil;
			if isOrig == false or self:HideOrigGossip(npc_i,page) == true then
				new_i = i;
			else
				if self:ShowGossipFirst(npc_i) then
					if i <= num_newGossip then
						new_i = i;
					else 
						orig_i = i - num_newGossip;
					end
				else
					if i > num_origGossip then
						new_i = i - num_origGossip;
					else 
						orig_i = i;
					end
				end
			end
			if new_i then
				if new_i > num_newGossip then return end
				local linkType,linkDetail = self:GetGossipLink(npc_i,page,new_i);
				if linkType == "ChangePage" then
					if type(linkDetail)=="number" then
						if linkDetail < 1 then
							self:SetCurrentPage(linkDetail,true);
						else
							self:SetCurrentPage(linkDetail,false);
						end
						GossipFrameUpdate();
					end			
				elseif linkType == "vendor" then
					self:SetCurrentAllowVendor(true);
					
					MerchantFrame_OnEvent(MerchantFrame,"MERCHANT_SHOW");
					GossipFrame:Hide();
				elseif linkType == "Script" then
					
				end
				return;
			else
				self:SetCurrentPage(0,true); -- makes GHU think that it is in page 0 when the user is viewing original sub pages
				return self.orig.SelectGossipOption(orig_i);
			end
		end
	end
	return self.orig.SelectGossipOption(i);
end

function GHU_NPC:GetGossipText()
	self = gself; -- give self info for hooked functions.
	local name = UnitName("npc");
	local npc_i = self:FindNPC(name);
	if npc_i then
		local zone = self:GetZone(npc_i);
		if not(zone) or zone == GetRealZoneText() then
			local page,isOrig = self:GetCurrentPage();
			local text = self:GetGossipPageText(npc_i,page);
			if isOrig == false then
				return (text or "");
			elseif not(text == nil) then
				return text;
			else
				return self.orig.GetGossipText();
			end
		end
	end
	return self.orig.GetGossipText();
end

function GHU_NPC:MerchantFrame_OnEvent(o_self, event, ...)
	self = gself; -- give self info for hooked functions.
	GHI_Message(event or "nil");
	if ( event == "MERCHANT_SHOW" ) then
		local name = UnitName("NPC");
		local npc_i = self:FindNPC(name);
		if npc_i then
			local zone = self:GetZone(npc_i);
			if not(zone) or zone == GetRealZoneText() then
				if self:OverruleVendor(npc_i) == true and self:GetCurrentAllowVendor() == false then
					GossipFrame_OnEvent(GossipFrame,"GOSSIP_SHOW");
					return;
				end
			end
			GHI_Message("Zone not matching "..zone);
		end
		GHI_Message("No npc");
	end
	self.orig.MerchantFrame_OnEvent(o_self, event, unpack(arg));

end

function GHU_NPC:MerchantFrame_OnShow()
	self = gself;
	local name = UnitName("NPC");
	local npc_i = self:FindNPC(name);
	if npc_i then
		local zone = self:GetZone(npc_i);
		if not(zone) or zone == GetRealZoneText() then
			if self:OverruleVendor(npc_i) == true and self:GetCurrentAllowVendor() == false then
				GossipFrame_OnEvent(GossipFrame,"GOSSIP_SHOW");
				return;
			end
		end
		GHI_Message("Zone not matching "..zone);
	end
	GHI_Message("No npc");
	self.orig.MerchantFrame_OnShow();
end

--	=======================	NPC functions	======================
--	Intern
function GHU_NPC:CheckNPCData(i)
	if not(type(self.NPCs)=="table") then
		self.NPCs ={};
	end
	if i then
		if not(type(self.NPCs[i])=="table") then
			self.NPCs[i] ={};
		end
	end
end


--	Current NPC
function GHU_NPC:NewCurrentNPC()
	self:SetCurrentPage(1,true);
	self:SetCurrentAllowVendor(false);
end

function GHU_NPC:SetCurrentPage(CurrentPage,isOriginal) -- use negative for origianal pages?
	self.CurrentPage = CurrentPage;
	self.isOriginal = isOriginal;
end
function GHU_NPC:GetCurrentPage()
	return (self.CurrentPage or 1),self.isOriginal;
end

function GHU_NPC:SetCurrentAllowVendor(allowVendor)
	self.CurrentAllowVendor = allowVendor;
end
function GHU_NPC:GetCurrentAllowVendor()
	return self.CurrentAllowVendor;
end


-- 	Data Input
function GHU_NPC:GetIndex(refID)
	self:CheckNPCData()
	for index,value in pairs(self.NPCs) do 
		if type(value) == "table" then
			if value.refID == refID then
				return index;
			end
		end		
	end
	return nil;
end
function GHU_NPC:FindNPC(name)
	self:CheckNPCData()
	for index,value in pairs(self.NPCs) do 
		if self:GetName(index) == name then
			return index;
		end
	end
	return nil;
end

-- 	Name of NPC
function GHU_NPC:AddNPC(refID,name)
	local i = self:GetIndex(refID);
	assert(not(i),"A NPC with the reference "..refID.." already exsists.");
	local t = {};
	t.refID = refID;
	t.name = name;
	table.insert(self.NPCs,t);
end
function GHU_NPC:GetName(i)
	self:CheckNPCData(i)	
	return self.NPCs[i].name;
end
function GHU_NPC:GetRefID(i)
	self:CheckNPCData(i)	
	return self.NPCs[i].RefID;
end

--	Zone the NPC if found in.
function GHU_NPC:SetZone(i,zone)
	self:CheckNPCData(i)	
	self.NPCs[i].zone = zone;
end
function GHU_NPC:GetZone(i)
	self:CheckNPCData(i)	
	return self.NPCs[i].zone;
end

-- 	if the new gossip shall be shown before the original gossip.  Warning: Might hide official gossip from being shown in case of overflow.
function GHU_NPC:SetShowGossipFirst(i,show)
	self:CheckNPCData(i)	
	self.NPCs[i].showFirst = show;
end
function GHU_NPC:ShowGossipFirst(i)
	self:CheckNPCData(i)	
	return self.NPCs[i].showFirst;
end

--	Show gossip frame instead of vendor frame for this npc.
function GHU_NPC:SetOverruleVendor(i,overule)
	self:CheckNPCData(i)	
	self.NPCs[i].OverruleVendor = overule;
end
function GHU_NPC:OverruleVendor(i)
	self:CheckNPCData(i)	
	return self.NPCs[i].OverruleVendor;
end



-- 	=====================	Gossip functions 	=================================
--	Intern
function GHU_NPC:CheckGossipData(npc_i,page,i)
	if not(type(self.NPCs)=="table") then
		self.NPCs ={};
	end
	if npc_i then
		if not(type(self.NPCs[npc_i])=="table") then
			self.NPCs[npc_i] ={};
		end
	else
		return;
	end
	if page then
		if not(type(self.NPCs[npc_i].gossip)=="table") then
			self.NPCs[npc_i].gossip ={};
		end
		if not(type(self.NPCs[npc_i].gossip[page])=="table") then
			self.NPCs[npc_i].gossip[page] ={};
		end
	else
		return;
	end
	if i then
		if not(type(self.NPCs[npc_i].gossip[page][i])=="table") then
			self.NPCs[npc_i].gossip[page][i] ={};
		end
	end
end

-- 	Data Input
function GHU_NPC:GetGossipIndex(npc,page,refID)
	self:CheckGossipData(npc,page)
	for index,value in pairs(self.NPCs[npc].gossip[page]) do 
		if type(value) == "table" then
			if value.refID == refID then
				return index;
			end
		end		
	end
	return nil;
end
function GHU_NPC:GetNumGossip(npc_i,page)
	self:CheckGossipData(npc_i,page);
	return table.getn(self.NPCs[npc_i].gossip[page]);
end

function GHU_NPC:SetGossipPageText(npc_i,page,text)
	self:CheckGossipData(npc_i,page)	
	self.NPCs[npc_i].gossip[page].text = text;
end
function GHU_NPC:GetGossipPageText(npc_i,page)
	self:CheckGossipData(npc_i,page,i)	
	return self.NPCs[npc_i].gossip[page].text;
end

function GHU_NPC:SetHideOrigGossip(npc_i,page,HideOrigGossip)
	self:CheckGossipData(npc_i,page)	
	self.NPCs[npc_i].gossip[page].HideOrigGossip = HideOrigGossip;
end
function GHU_NPC:HideOrigGossip(npc_i,page)
	self:CheckGossipData(npc_i,page,i)	
	return self.NPCs[npc_i].gossip[page].HideOrigGossip;
end


--	gossip
function GHU_NPC:AddGossip(refID,npc_i,page,text,gossipType) --API
	local i = self:GetGossipIndex(npc_i,page,refID);
	assert(not(i),"Gossip with the reference "..refID.." already exsists.");
	local t = {};
	t.refID = refID;
	t.text = text;
	t.gossipType = gossipType;
	table.insert(self.NPCs[npc_i].gossip[page],t);
	
end
function GHU_NPC:RemoveGossip(refID,npc_i,page) --API
	local i = self:GetGossipIndex(npc_i,page,refID);
	assert((i),"Gossip with the reference "..refID.." dosent exsists.");
	table.remove(self.NPCs[npc_i].gossip[page]);	
end
function GHU_NPC:GetGossipDetail(npc_i,page,i) --API
	self:CheckGossipData(npc_i,page,i)	
	return self.NPCs[npc_i].gossip[page][i].text;
end
function GHU_NPC:GetGossipType(npc_i,page,i)
	self:CheckGossipData(npc_i,page,i)	
	return self.NPCs[npc_i].gossip[page][i].gossipType;
end

function GHU_NPC:SetGossipLink(npc_i,page,i,linkType,linkDetail) --API -- ChangePage or Script  -- todo: more actions than one on link click?
	self:CheckGossipData(npc_i,page,i)	
	self.NPCs[npc_i].gossip[page][i].linkType = linkType;
	self.NPCs[npc_i].gossip[page][i].linkDetail = linkDetail;
end
function GHU_NPC:GetGossipLink(npc_i,page,i)
	self:CheckGossipData(npc_i,page,i)	
	return self.NPCs[npc_i].gossip[page][i].linkType, self.NPCs[npc_i].gossip[page][i].linkDetail;
end

function GHU_NPC_Test()
	GHP_NPC = GHU_New("NPC");
	local p = GHP_NPC;
	p:AddNPC("GHP_NPC-SW_Guard","Stormwind Guard");
	local i = p:GetIndex("GHP_NPC-SW_Guard");
	p:SetShowGossipFirst(i,true);
	p:AddGossip("GHP_Trainers",i,1,"Gryphonheart Profession Trainer","gossip");
	p:AddGossip("GHP_Officials",i,1,"Gryphonheart Officials","gossip");
	local g1 = p:GetGossipIndex(i,1,"GHP_Trainers");
	p:SetGossipLink(i,1,g1,"ChangePage",2);
	p:SetGossipPageText(i,2,"You might have seen some known Stormwind locals taking interest in the Gryphonheart project. Some of them are quite skilled and is willing to teach other.\n\nWhat are you interested in learning?");
	p:AddGossip("GHP_Lumber",i,2,"Lumbering","gossip");
	p:AddGossip("GHP_Wood",i,2,"Woodworking","gossip");
	p:AddGossip("GHP_Farming",i,2,"Farming","gossip");
	p:AddGossip("GHP_Clay",i,2,"Claydigging","gossip");
	p:AddGossip("GHP_Potter",i,2,"Pottery","gossip");
	p:AddGossip("GHP_HCook",i,2,"Home Cooking","gossip");
	p:AddGossip("GHP_Brew",i,2,"Brewing","gossip");
	p:AddGossip("GHP_Art",i,2,"Art","gossip");
	p:AddGossip("GHP_Tool",i,2,"Toolsmithing","gossip");
	--p:AddGossip("GHP_Dummy1",i,2," ");
	p:AddGossip("GHP_Noble",i,2,"I would like to learn about more noble professions.","gossip");
	
	
	local n = "Marshal Marris"; 
	p:AddNPC("GHP_NPC-"..n,n); 
	local i = p:GetIndex("GHP_NPC-"..n);
	p:SetShowGossipFirst(i,true);
	p:AddGossip("GHP_Status",i,1,"What is the current threat situation Marshal?","gossip");
	
	local n = "Ian Drake"; 
	p:AddNPC("GHP_NPC-"..n,n); 
	local i = p:GetIndex("GHP_NPC-"..n);
	p:SetShowGossipFirst(i,true);
	p:SetHideOrigGossip(i,1,true);
	p:SetGossipPageText(i,1,"Greetings. Stay a while and listen.");
	p:AddGossip("ID_GP",i,1,"Tell me about the Gryphonheart project.","gossip");
	p:AddGossip("ID_tip",i,1,"Can you give me a tip that can aid me on my way to wealth?","binder");
	p:AddGossip("ID_worldEvent",i,1,"I would like to speak to you about the Worldwide International Event.","gossip");
	local g1 = p:GetGossipIndex(i,1,"ID_worldEvent");
	p:SetGossipLink(i,1,g1,"ChangePage",0);
	
	local n = "Charity Mipsy"; 
	p:AddNPC("GHP_NPC-"..n,n); 
	local i = p:GetIndex("GHP_NPC-"..n);
	p:SetShowGossipFirst(i,true);
	p:SetOverruleVendor(i,true);
	p:SetGossipPageText(i,1,"Greetings. What can I do for you?");
	p:AddGossip("V1",i,1,"Heard any interesting stories lately?","gossip");
	local g1 = p:GetGossipIndex(i,1,"V1");
	p:SetGossipLink(i,1,g1,"ChangePage",2);
	p:AddGossip("V2",i,1,"I would like to trade with you.","vendor");
	local g2 = p:GetGossipIndex(i,1,"V2");
	p:SetGossipLink(i,1,g2,"vendor",0);
	
	
	GHI_Message("GHP NPC test set up");
end
--[[ 

/script GHI_PrintArray(GHP_NPC.NPCs);

/script GHU_NPC_Test();

/script local n = "Marshal Marris"; GHP_NPC:AddNPC("GHP_NPC-"..n,n); local i 

/script GHP_NPC
--]]
