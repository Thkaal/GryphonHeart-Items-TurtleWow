


GHU_TalkDisplay = {};


function GHU_TalkDisplay:AddTalkCollection(talk)
	if not(type(self.talks)=="table") then
		self.talks = {};
		
		-- set up the display first time
		
	end

end


GHU_Talk = {}
GHU_Talk.__index = GHU_Talk;
GHU_Talk.hooked ={};

-- 	standard
function GHU_Talk:Create(varName)
		
	setglobal(varName,GHU_Talk); 
	
	local obj = {}          
	setmetatable(obj, getglobal(varName))  
		
	setglobal(varName,obj); 
	return obj;
end

--GHI_DoScript("ShowUIPanel(GHU_GossipFrame)",4)

--  /dump GHU_GossipFrameGreetingPanelModel:SetPosition(2,0,-0.7)
--  /dump GHU_GossipFrameGreetingPanelModel:SetRotation(-0.3)
--  /dump GHU_GossipFrameGreetingPanelModel:SetSequence(0);
--	/script GHU_GossipFrameGreetingPanelModel:SetSequenceTime(30, 1) 
