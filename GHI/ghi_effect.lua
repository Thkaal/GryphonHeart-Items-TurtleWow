--[[
	This file consists of a lot unused grafic effect functions. These are orriginally intented  as item effects for the comming Brewmaster professions in GHP.
]]


GHI_EffectColors = {};
GHI_ColorList = {}
local color = {};

color.r = 1; color.g = 0.0; color.b = 0.0; GHI_EffectColors["red"] = color; table.insert(GHI_ColorList,"red"); color = {};
color.r = 1; color.g = 1; color.b = 0.0; GHI_EffectColors["yellow"] = color; table.insert(GHI_ColorList,"yellow"); color = {};
color.r = 0.5; color.g = 0.5; color.b = 0.0; GHI_EffectColors["gold"] = color; table.insert(GHI_ColorList,"gold"); color = {};
color.r = 0.0; color.g = 1; color.b = 0.0; GHI_EffectColors["green"] = color; table.insert(GHI_ColorList,"green"); color = {};
color.r = 0.0; color.g = 0.5; color.b = 0.0; GHI_EffectColors["green2"] = color; table.insert(GHI_ColorList,"green2"); color = {};
color.r = 0.0; color.g = 0.0; color.b = 1; GHI_EffectColors["blue"] = color;  table.insert(GHI_ColorList,"blue"); color = {};
color.r = 0.0; color.g = 0.0; color.b = 0.5; GHI_EffectColors["blue2"] = color;  table.insert(GHI_ColorList,"blue2"); color = {};
color.r = 0.5; color.g = 0.0; color.b = 0.5; GHI_EffectColors["purple"] = color; table.insert(GHI_ColorList,"purple"); color = {};
color.r = 0.0; color.g = 0.5; color.b = 0.5; GHI_EffectColors["teal"] = color; table.insert(GHI_ColorList,"teal"); color = {};
color.r = 0.8; color.g = 0.4; color.b = 0.0; GHI_EffectColors["orange"] = color; table.insert(GHI_ColorList,"orange"); color = {};
color.r = 0.4; color.g = 0.8; color.b = 0.0; GHI_EffectColors["Lgreen"] = color; table.insert(GHI_ColorList,"Lgreen"); color = {};
color.r = 0.0; color.g = 0.4; color.b = 0.8; GHI_EffectColors["Lblue"] = color; table.insert(GHI_ColorList,"Lblue"); color = {};
color.r = 0.0; color.g = 0.8; color.b = 0.4; GHI_EffectColors["Dgreen"] = color; table.insert(GHI_ColorList,"Dgreen"); color = {};
color.r = 0.8; color.g = 0.0; color.b = 0.4; GHI_EffectColors["Pink"] = color; table.insert(GHI_ColorList,"Pink"); color = {};
color.r = 0.4; color.g = 0.0; color.b = 0.8; GHI_EffectColors["Dblue"] = color; table.insert(GHI_ColorList,"Dblue"); color = {};
color.r = 0.5; color.g = 0.0; color.b = 0.0; GHI_EffectColors["brown"] = color; table.insert(GHI_ColorList,"brown"); color = {};
color.r = 0.5; color.g = 0.5; color.b = 0.5; GHI_EffectColors["gray"] = color; table.insert(GHI_ColorList,"gray"); color = {};
color.r = 1; color.g = 1; color.b = 1; GHI_EffectColors["white"] = color; table.insert(GHI_ColorList,"white"); color = {};





function GHI_EffectHookings()
	GHI_EffectFrameEffect0:SetAlpha(0); 
	GHI_EffectFrameEffect1:SetAlpha(0); 
	GHI_EffectFrameEffect2:SetAlpha(0); 
	GHI_EffectFrameEffect3:SetAlpha(0); 
	GHI_EffectFrameEffect4:SetAlpha(0); 
	
	GHI_EffectFrameEffect0Texture:SetVertexColor(0.0, 0.0, 0.1);
	GHI_EffectFrameEffect1Texture:SetVertexColor(0.0, 0.0, 0.1);
	GHI_EffectFrameEffect2Texture:SetVertexColor(0.0, 0.0, 0.1);
	GHI_EffectFrameEffect3Texture:SetVertexColor(0.0, 0.0, 0.1);
	GHI_EffectFrameEffect4Texture:SetVertexColor(0.0, 0.0, 0.1);
	
end



