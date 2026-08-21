
local GiveWarnings = false;
local ShowLines = false;
local function Warning(msg)
	if GiveWarnings == true then
		local info = ChatTypeInfo["COMBAT_XP_GAIN"];
		DEFAULT_CHAT_FRAME:AddMessage(msg, info.r, info.g, info.b, info.id);
	end
end


--- intern data 
local LabelValues = {};
local lastestEditbox = nil;

local function GetFrameType(name)
	if name == "Editbox" then
		return "Editbox";
	elseif name == "StackSlider" or name == "TimeSlider" or name == "SlotSlider" or name == "CustomSlider" then
		return "Slider";
	elseif name == "CheckBox" then
		return "CheckButton";
	elseif name == "Button" or name == "Icon" then
		return "Button";
	elseif name == "ImageList" then
		return "ScrollFrame";
	end
	
	return "Frame";

end

local function CreateObject(num, profile,parent)
	if not(profile.type) then return 0; end
	local offsetX = 0;
	local offsetY = 0;
	local extraX = 0;
	local extraY = 0;
	local main = parent:GetParent():GetParent();
	
	--	Create object
	parent.tempdata = profile.data;
	local obj = CreateFrame(GetFrameType(profile.type),parent:GetName().."_O"..num,parent,"GHM_"..profile.type.."_Template");
	
	obj.main = main;
	-- Explicitly enable mouse input for interactive controls on the Vanilla client.
	if profile.type == "Editbox" or profile.type == "StackSlider" or profile.type == "TimeSlider" or profile.type == "SlotSlider" or profile.type == "CustomSlider" or profile.type == "CheckBox" or profile.type == "Button" or profile.type == "Icon" or profile.type == "QualityDD" or profile.type == "CustomDD" or profile.type == "ImageList" then
		obj:EnableMouse(true);
	end
	if GiveWarnings == true then
		local objType = profile.type;
		if obj.GetObjectType then objType = obj:GetObjectType(); end
		Warning("Inserted object "..num..", type: "..profile.type.." = "..tostring(objType)..", name: "..obj:GetName());
	end
	
	local l = main.GetLabel(profile.label);
	if not(l == nil) then
		Warning("Label "..profile.label.." already registered.");
		obj.label = nil;
	else
		obj.label = profile.label;
		main.RegisterLabel(obj.label,obj);
	end
	
	local height = obj:GetHeight();
	
	obj.type = profile.type;
	if profile.type == "Text" then
		local label = getglobal(obj:GetName().."Label");
		label:SetText(profile.text);
		if profile.color == "white" then
			label:SetTextColor(1,1,1);
			--GHI_Message("Making "..obj:GetName().." white");
		end
		
		if profile.align == "c" then
			label:SetJustifyH("CENTER");
		elseif profile.align == "r" then
			label:SetJustifyH("RIGHT");
		else
			label:SetJustifyH("LEFT");
		end
		
		if profile.fontSize then
			label:SetFont("Fonts\\FRIZQT__.TTF",profile.fontSize);
		end
		if profile.width then
			obj:SetWidth(profile.width);
		end
		if profile.singleLine == true then
			obj:SetHeight(label:GetHeight());
		end
		
		height = label:GetHeight();
	elseif profile.type == "Editbox" then
		local label = getglobal(obj:GetName().."TextLabel");
		label:SetText(profile.text);
		offsetX = 10 ;
		offsetY = -(label:GetHeight() / 2);
		height = height + label:GetHeight();
		
		if type(profile.size) == "number" then -- 1 to 256
			obj:SetMaxLetters(profile.size);
		end
		if type(profile.width) == "number" then
			obj:SetWidth(profile.width);
			getglobal(obj:GetName().."Left"):SetWidth(profile.width-10);
			
		end
		
		if not(lastestEditbox == nil) then
			lastestEditbox.next = obj;
			lastestEditbox:SetScript("OnTabPressed", function() this:ClearFocus(); this.next:SetFocus(); end);
		end
		lastestEditbox = obj;
		if type(profile.startText) == "string" then
			obj:SetText(profile.startText)
		else
			obj:SetText("");
		end
		
		if profile.numbersOnly == true then
			obj.t = "";
			obj:SetScript("OnChar", function() 
				if not(tonumber(arg1) or string.byte(arg1) == 45 or string.byte(arg1) == 46) then
					obj:SetText(obj.t);
				else
					obj.t = obj:GetText();
					obj.main.SetLabel(this.label,obj.t);
				end
			end);
			obj.numbersOnly = true;
		end
		if type(profile.onchange) == "function" then
			obj.onchange = profile.onchange;
		end
		
	elseif profile.type == "StackSlider" then
		local label = getglobal(obj:GetName().."Label1");
		height = height + label:GetHeight();
		offsetY = -5;
		obj:SetValue(2);
		obj:SetValue(1);
		if profile.text then label:SetText(profile.text); end
		if type(profile.width) == "number" then
			obj:SetWidth(profile.width);
		end
	elseif profile.type == "SlotSlider" then
		local label = getglobal(obj:GetName().."Label1");
		height = height + label:GetHeight();
		offsetY = -5;
		obj:SetValue(2);
		obj:SetValue(1);
		if profile.text then label:SetText(profile.text); end
		if type(profile.width) == "number" then
			obj:SetWidth(profile.width);
		end
	elseif profile.type == "TimeSlider" then
		local label = getglobal(obj:GetName().."Label1");
		if type(profile.text) == "string" then
			label:SetText(profile.text);
		end
		height = height + label:GetHeight();
		offsetY = -5;
		obj:SetValue(2);
		obj:SetValue(1);
		if type(profile.values)=="table" then
			obj.SliderValues = profile.values;
			obj:SetMinMaxValues(1,table.getn(profile.values));
			obj:SetValue(2);
			obj:SetValue(1);
		end
		if type(profile.width) == "number" then
			obj:SetWidth(profile.width);
		end
	elseif profile.type == "CustomSlider" then
		local label = getglobal(obj:GetName().."Label1");
		if type(profile.text) == "string" then
			label:SetText(profile.text);
		end
		height = height + label:GetHeight();
		offsetY = -5;
		obj:SetValue(2);
		obj:SetValue(1);
		if type(profile.values)=="table" then
			obj.SliderValues = profile.values;
			obj:SetMinMaxValues(1,table.getn(profile.values));
			obj:SetValue(2);
			obj:SetValue(1);
		end
		if type(profile.width) == "number" then
			obj:SetWidth(profile.width);
		end
	elseif profile.type == "CheckBox" then
		local label = getglobal(obj:GetName().."TextLabel");
		if type(profile.text) == "string" then
			label:SetText(profile.text);
		end
	
		if profile.checked == true then
			--obj:SetChecked(1);	
			main.ForceLabel(obj.label,true);
		else
			main.ForceLabel(obj.label,false);
		end
		if profile.align == "r" then
			offsetX = label:GetStringWidth();
		end
	elseif profile.type == "QualityDD" then
		local label = getglobal(obj:GetName().."Label");
		if type(profile.text) == "string" then
			label:SetText(profile.text);
		end
		local label2 = getglobal(obj:GetName().."TextLabel");
		if type(profile.initPos) == "number" then
			local color = ITEM_QUALITY_COLORS[profile.initPos];
			label2:SetText("|CFF" ..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255) .." "..getglobal("ITEM_QUALITY" ..profile.initPos.. "_DESC").."|r"); 
			main.SetLabel(obj.label,profile.initPos);
		else
			local color = ITEM_QUALITY_COLORS[1];
			label2:SetText("|CFF" ..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255) .." "..getglobal("ITEM_QUALITY1_DESC").."|r"); 
			main.SetLabel(obj.label,1);
		end
		obj:SetWidth(155);
		height = height + label:GetHeight();
		offsetY = -5;
		extraX = 0; -- (obj:GetWidth()/2)
		--if profile.align == "r" then
		--	extraX = extraX - 87;
		--elseif profile.align == "c" then
		--	extraX = extraX; -- 40;
		--end
	elseif profile.type == "CustomDD" then
		local label = getglobal(obj:GetName().."Label");
		if type(profile.text) == "string" then
			label:SetText(profile.text);
		end
		if profile.width then
			obj:SetWidth(profile.width);
			getglobal(obj:GetName().."Middle"):SetWidth(profile.width-40);
		else
			obj:SetWidth(155);
		end
		local label2 = getglobal(obj:GetName().."TextLabel");
		local pos = profile.initPos;
		local t = profile.data;
		if type(t) == "table" then
			if type(pos) == "number" then
				label2:SetText(t[pos]); 
				if profile.returnIndex == true then
					main.SetLabel(obj.label,pos);
				else
					main.SetLabel(obj.label,t[pos]);
				end
			else
				label2:SetText(t[1]); 
				if profile.returnIndex == true then
					main.SetLabel(obj.label,1);
				else
					main.SetLabel(obj.label,t[1]);
				end
			end
		else
			label2:SetText("");
		end
		
		height = height + label:GetHeight();
		offsetY = -5;
		--[[extraX = - (obj:GetWidth()/2)
		if profile.align == "r" then
			extraX = extraX - 87;
		elseif profile.align == "c" then
			extraX = extraX - 40;
		end ]]
		obj.returnIndex = profile.returnIndex;
	elseif profile.type == "Button" then
		local label = getglobal(obj:GetName().."Text");
		if label then
			if type(profile.text) == "string" then
				label:SetText(profile.text);
			end
			if profile.fontSize then
				--label:SetFont("Fonts\\FRIZQT__.TTF",profile.fontSize);
			end
			
			if profile.compact == true then
				obj:SetHeight(label:GetHeight()+8);
				obj:SetWidth(label:GetWidth()+8);
			else
				local origWidth = obj:GetWidth();
				obj:SetWidth(200);
				if label:GetWidth() > (origWidth - 10) then
					obj:SetWidth(label:GetWidth() + 10);
				else
					obj:SetWidth(origWidth);
				end
			end
			if profile.width then
				obj:SetWidth(profile.width);
			end
			
		end
		
		if type(profile.onclick) == "function" then
			obj:SetScript("OnClick",profile.onclick);
		end
	elseif profile.type == "Icon" then
		local label = getglobal(obj:GetName().."TextLabel");
		if type(profile.text) == "string" then
			label:SetText(profile.text);
		end
		height = height + label:GetHeight()*1.8;
		offsetY = -10;
		if profile.framealign then
			obj.framealign = profile.framealign;
		else
			obj.framealign = "c";
		end
	elseif profile.type == "List" then
		height = obj.SetUpList(profile.lines,profile.column)
		obj.onclick = profile.onclick;
		obj.UpdateAll();
	elseif profile.type == "Dummy" then
		obj:SetHeight(profile.height);
		obj:SetWidth(profile.width);
		height = profile.height;
	elseif profile.type == "EditField" then
		obj:SetHeight(profile.height);
		obj:SetWidth(profile.width);
		height = profile.height;
	elseif profile.type == "ImageList" then
		obj:SetHeight(profile.height);
		obj:SetWidth(profile.width);
		if profile.scaleX or profile.scaleY then
			obj.SetScale(profile.scaleX or 1,profile.scaleY or 1)
		end
		height = profile.height;
	end
	obj:ClearAllPoints() 
	
	extraX = profile.xOff or 0;
	extraY = profile.yOff or 0;
	
	if profile.align == "c" then
		obj:SetPoint("CENTER", parent, "CENTER", 0 + extraX, offsetY + extraY);
	elseif profile.align == "r" then
		if parent.lastRight then
			local y = 0;
			if parent.lastRight.type == "CustomDD" or parent.lastRight.type == "QualityDD" then
				y = 5;
			elseif parent.lastRight.type == "Icon" then
				y = 10;
			end
			obj:SetPoint("RIGHT", parent.lastRight, "LEFT", -offsetX + extraX, offsetY + extraY + y);
			parent.lastRight = obj;
		else
			obj:SetPoint("RIGHT", parent, "RIGHT", -offsetX + extraX, offsetY + extraY);
			parent.lastRight = obj;
		end
		
	else
		if parent.lastLeft then
			local y = 0;
			if parent.lastLeft.type == "CustomDD" or parent.lastLeft.type == "QualityDD" then
				y = 5;
			elseif parent.lastLeft.type == "Icon" then
				y = 10;
			end
			obj:SetPoint("LEFT", parent.lastLeft, "RIGHT", offsetX + extraX, offsetY + extraY + y);
			parent.lastLeft = obj;
		else
			obj:SetPoint("LEFT", parent, "LEFT", offsetX + extraX, offsetY + extraY);
			parent.lastLeft = obj;
		end
	end
	
	--GHI_Message((profile.label or "nil")..": "..type(profile.OnLoad));
	if type(profile.OnLoad) == "function" then
		local This = this;
		this = obj;
		profile.OnLoad();
		this = This;
	end
	obj:Show();
	
	return height;
end

local function CreateLine(num,profile,parent,offset)
	if type(profile) == "table" and type(offset) == "number" then
		local tallest = 0;
		local line = CreateFrame("Frame",parent:GetName().."_L"..num,parent); 
		local main = parent:GetParent();
		Warning("Inserted line "..num.." Start at "..offset);
		line:SetPoint("TOPLEFT", parent:GetParent(), "TOPLEFT", main.frame_offset_x, offset);
		line:SetWidth(main.frame_x);
		line:SetHeight(20);
		
		if ShowLines == true then
			line:SetBackdrop( { 
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background", 
				edgeFile = "edgeFile", tile = false, tileSize = 0, edgeSize = 32, 
				insets = { left = 0, right = 0, top = 0, bottom = 0 }
			});
			local color = {["r"]=0.4,["g"]=0.5,["b"]=0.6}
			if GHI_EffectColors then
				color = GHI_EffectColors[GHI_ColorList[mod(num,6)+1]];
			end
			line:SetBackdropColor(color.r, color.g, color.b,1);
		end
		local i = 1;
		while type(profile[i]) == "table" do
			local height = CreateObject(i,profile[i],line);
			if height > tallest then
				tallest = height;
			end
			i = i+1;
		end
		if tallest == 0 then -- force line height to 20
			tallest = 20;
		end
		line:Show();
		line:SetHeight(tallest);
		if main.lineDistance then
			offset = offset - tallest - main.lineDistance;
		else
			offset = offset - tallest - 3;
		end
	end
	return offset;
end

local function CreatePage(num,profile,parent)
	if type(profile) == "table" then
		local page = CreateFrame("Frame",parent:GetName().."_P"..num,parent);  Warning("Inserted page "..num);
		local i = 1;
		local offset = -parent.frame_offset_y;
		lastestEditbox = nil
		while type(profile[i]) == "table" and -offset <(parent.frame_offset_y + parent.frame_y) do
			
			offset = CreateLine(i,profile[i],page,offset);
			i = i+1;
			
		end
		if num == 1 then
			page:Show();
		else
			page:Hide();
		end
		
	end
end


function GHM_NewFrame(profile)
	-- TurtleWoW / WoW 1.12: capture the calling frame before CreateFrame/template
	-- OnLoad handlers get a chance to alter the implicit global `this`.
	local caller = this;
	if type(profile) == "table" and type(profile.name) == "string" then
		if getglobal(profile.name) then
			local existing = getglobal(profile.name);
			Warning("A frame named "..profile.name.." already exsists.");
			if not(existing.GHM_Initialized) then
				if GHI_Message then GHI_Message("GHM: incomplete frame '"..profile.name.."' detected. Please /reload after updating the addon."); end
				return nil;
			end
			return existing;
		end
		local theme = profile.theme
		if not(theme) then
			theme = "StdTheme";
		end
		
		
		local main = CreateFrame("Frame",profile.name,UIParent,"GHM_"..theme.."_Template");

		-- Establish the parent level BEFORE creating pages/controls.  On the 1.12
		-- client, raising a mouse-enabled parent after its children have been
		-- created can leave the parent hit surface above those children.
		local baseLevel = 1;
		if caller and caller.GetFrameLevel then
			baseLevel = caller:GetFrameLevel() or 1;
		end
		main:SetFrameLevel(baseLevel + 5);

		-- TurtleWoW / 1.12 does not reliably propagate a parent's new frame
		-- level to children that were instantiated by the XML template during
		-- CreateFrame().  Raise the stock theme controls explicitly so they are
		-- rendered and clicked above the dialog backdrop.
		local templateChildren = {"Ok", "Cancel", "Back", "Next", "CloseButton"};
		for ti = 1, table.getn(templateChildren) do
			local child = getglobal(profile.name..templateChildren[ti]);
			if child then
				if child.SetFrameLevel then child:SetFrameLevel(main:GetFrameLevel() + 2); end
				if child.EnableMouse then child:EnableMouse(true); end
			end
		end

		-- The Std/Wizard backdrops have no click behavior of their own.  Leaving
		-- the parent mouse-enabled can place an invisible hit surface over footer
		-- buttons on the Vanilla client after the parent level is raised.
		if theme == "WizardTheme" or theme == "StdTheme" then
			main:EnableMouse(false);
		end

		getglobal(profile.name.."TitleString"):SetText(profile.title);
		main.LabelData = {};
		main.LabelFrame = {};
		
		main.icon = icon;
		if profile.height then
			main:SetHeight(profile.height);
		end
		if profile.width then
			main:SetWidth(profile.width);
			main.frame_x = profile.width - 100;
		end
		if theme == "SpellBookTheme" then
			main.frame_y = main:GetHeight() - (main.frame_offset_y + 120);
			local icon = getglobal(main:GetName().."Icon");
			icon.SetIcon(icon,profile.icon);
		end
		
		--	function initlization
		main.RegisterLabel = function(label,frame) assert(not(type(label)=="table"),"a table?"); if not(label == nil) then 
			main.LabelFrame[label] = frame;
		end; end;
		main.SetLabel = function(label,data) if not(label == nil) then 
			if not(main.LabelFrame[label]) then
				main.RegisterLabel(label,this);
			end
			main.LabelData[label] = data; 
		end; end;
		main.GetLabel = function(label) if not(label == nil) then return main.LabelData[label]; end; end;
		main.ForceLabel = function(label,data) if not(label == nil) then 
			local f = main.LabelFrame[label];
			if f and type(f.Force) == "function" then
				f.Force(data);
			else print("Could not force label: ",label);
			end
			main.SetLabel(label,data);
		end end;
		main.GetLabelFrame = function(label) 
			return main.LabelFrame[label];
		end;
		main.ClearAll = function()
			for index,value in pairs(main.LabelFrame) do
				if type(value) == "table" and type(value.Clear) == "function" then
					value.Clear();
				end
			end
			if main.bn then
				main.currentPage = 1;
				main.UpdatePages();
			end
		end;
		
		
		local i = 1;
		while type(profile[i]) == "table" do
			CreatePage(i,profile[i],main);
			i = i+1;
		end
		main.numPages = i-1;
		main.currentPage = 1;
		main.autohide = profile.autohide;
		
		main.madeBy = caller;
		
		-- funciton handeling
		main.OnOk = function() end;
		if type(profile.OnOk) == "function" then
			main.OnOk = profile.OnOk;
		end
		
		if type(profile.OnShow) == "function" then
			main:SetScript("OnShow",profile.OnShow);
		end
		
		-- page and button handling
		if theme == "WizardTheme" then
			main.bb = getglobal(main:GetName().."Back");
			main.bn = getglobal(main:GetName().."Next");
			
			-- setup handle
			main.UpdatePages = function()
				if main.currentPage == 1 then
					main.bb:Disable();
				else
					main.bb:Enable();
					local f = getglobal(main:GetName().."_P"..main.currentPage-1);
					if f then f:Hide(); end
				end
				if main.currentPage == main.numPages then
					main.bn:SetText("Finish");
				else
					main.bn:SetText("Next \62");
					local f = getglobal(main:GetName().."_P"..main.currentPage+1);
					if f then f:Hide(); end
				end
				local f = getglobal(main:GetName().."_P"..main.currentPage);
				if f then 
					f:Show(); 
				end
			end
			
			
			main.bb:SetScript("OnClick",function()
				local main = this:GetParent();
				if main.currentPage > 1 then
					main.currentPage = main.currentPage - 1;
				end
				main.UpdatePages()
				
			end);
			
			main.bn:SetScript("OnClick",function()
				local main = this:GetParent();
				if  main.currentPage < main.numPages then
					main.currentPage = main.currentPage + 1;
				elseif main.currentPage == main.numPages then
					main.OnOk();
					if not(main.autohide == false) then
						main:Hide();
					end
				end
				main.UpdatePages()
			end);
			
			
			main.UpdatePages();
		elseif theme == "SpellBookTheme" then 
			main.ok = getglobal(main:GetName().."Ok");
			main.cancel = getglobal(main:GetName().."Cancel");
			main.ok:SetScript("OnClick",function() 
				local main = this:GetParent();
				main.OnOk();
				main:Hide();
				if not(main.autohide == false) then
					main:Hide();
				end
			end);
			local h = main:GetHeight();
			if h > 512 then
				getglobal(main:GetName().."BotLeft"):SetHeight(h - 256);
				getglobal(main:GetName().."BotRight"):SetHeight(h - 256);
				local yoff = floor((h-512)/3);
				main.ok:SetPoint("BOTTOM",main,"BOTTOM",-60,90+yoff);
				main.cancel:SetPoint("BOTTOM",main,"BOTTOM",60,90+yoff);
			end
		elseif theme == "StdTheme" then 
			main.ok = getglobal(main:GetName().."Ok");
			main.cancel = getglobal(main:GetName().."Cancel");
			main.ok:SetScript("OnClick",function() 
				local main = this:GetParent();
				main.OnOk();
				main:Hide();
				if not(main.autohide == false) then
					main:Hide();
				end
			end);
		end
		
		
		
		main:ClearAllPoints() 
		main:SetPoint("CENTER",UIParent,"CENTER",0,0);
		main.GHM_Initialized = true;
		
		
		return main;
	end

end

--[[ Profile structure
For wizard:
	profile[x][y][z]   =  Info table about page x, line y, object z


]]



function GHM_SetUpRoundIcon(halfSize)
	local m = 1;
	if halfSize then m = 1.8; end
	
	local res = 20
	Warning("Setting up round icon");
	local tex_x1 = 0.06;
	local tex_x2 = 0.94;
	local tex_y1 = 0.06;
	local tex_y2 = 0.94;
	local diameter = 58/m;
	local fsize = diameter/res;
	local xunit = (tex_x2-tex_x1)/res;
	local yunit = (tex_y2-tex_y1)/res;
	
	--local c = 1;
	
	this:SetHeight(diameter);
	this:SetWidth(diameter);
	this:SetFrameLevel(0);
	
	--[[	old
	local cir = {};
	local info = {};
	info.x_o = 0;
	info.x = 32;
	info.y_o = 5;
	info.y = 22;
	table.insert(cir,info);
	
	info = {};
	info.x_o = 5;
	info.x = 22;
	info.y_o = 0;
	info.y = 5;
	table.insert(cir,info);
	
	info = {};
	info.x_o = 5;
	info.x = 22;
	info.y_o = 22;
	info.y = 5;
	table.insert(cir,info);
		
	
	--]]
	--[ [ New
	local cir = {};
	local info = {};
	
	info = {};
	info.x_o = 3;
	info.x = 14;
	info.y_o = 3;
	info.y = 14;
	table.insert(cir,info);
	
	-- top
	info = {};
	info.x_o = 5;
	info.x = 10;
	info.y_o = 0;
	info.y = 1;
	table.insert(cir,info);
	
	info = {};
	info.x_o = 4;
	info.x = 12;
	info.y_o = 1;
	info.y = 1;
	table.insert(cir,info);
	
	info = {};
	info.x_o = 3;
	info.x = 14;
	info.y_o = 2;
	info.y = 1;
	table.insert(cir,info);
	
	
	
	-- left
	info = {};
	info.x_o = 2;
	info.x = 1;
	info.y_o = 3;
	info.y = 14;
	table.insert(cir,info);
	
	info = {};
	info.x_o = 1;
	info.x = 1;
	info.y_o = 4;
	info.y = 12;
	table.insert(cir,info);
	
	info = {};
	info.x_o = 0;
	info.x = 1;
	info.y_o = 5;
	info.y = 10;
	table.insert(cir,info);
	
	
	-- right
	info = {};
	info.x_o = 17;
	info.x = 1;
	info.y_o = 3;
	info.y = 14;
	table.insert(cir,info);
	
	info = {};
	info.x_o = 18;
	info.x = 1;
	info.y_o = 4;
	info.y = 12;
	table.insert(cir,info);
	
	info = {};
	info.x_o = 19;
	info.x = 1;
	info.y_o = 5;
	info.y = 10;
	table.insert(cir,info);
	
	-- buttom
	info = {};
	info.x_o = 5;
	info.x = 10;
	info.y_o = 19;
	info.y = 1;
	table.insert(cir,info);
	
	info = {};
	info.x_o = 4;
	info.x = 12;
	info.y_o = 18;
	info.y = 1;
	table.insert(cir,info);
	
	info = {};
	info.x_o = 3;
	info.x = 14;
	info.y_o = 17;
	info.y = 1;
	table.insert(cir,info);
	
	--]]
	
	for i = 1,table.getn(cir) do
		local f = CreateFrame("Frame",this:GetName()..i,this,"GHM_RoundIconPiece_Template");
		local icon = getglobal(f:GetName().."Icon");
		local x = cir[i].x;
		local y = cir[i].y;
		local x_off = cir[i].x_o;
		local y_off = cir[i].y_o;
		
		
		f:SetHeight(fsize*y);
		f:SetWidth(fsize*x);
		f:SetPoint("TOPLEFT",this,"TOPLEFT",fsize*x_off,-fsize*y_off);
		
		icon:SetHeight(fsize*y);
		icon:SetWidth(fsize*x);
		icon:SetTexCoord(tex_x1 + xunit*x_off,tex_x1 + xunit*(x_off+x),tex_y1 + yunit*y_off,tex_y1 + yunit*(y_off+y));
		Warning("Created "..f:GetName());
		Warning(tex_x1 + xunit*x_off.." , "..tex_x1 + xunit*(x_off+x).." , "..tex_y1 + yunit*y_off.." , "..tex_y1 + yunit*(y_off+y))
	end
	this.numPieces = table.getn(cir);
	
	this.SetIcon = function(icon,path)
		if not(path) then
			path = "Interface\\Icons\\INV_Misc_QuestionMark";
		end
		
		if icon then
			local n = icon:GetName();
			for i = 1,icon.numPieces do
				local f = getglobal(n..i.."Icon");
				f:SetTexture(path);				
			end	
		end
	end
	
	
end

function GHM_List_OnLoad()
	local f = this;
	f.data = {};
	
	f.SetUpList = function(lines,column)
		if not(lines) or not(column) then
			return 0;
		end
		f.offset = 0;
		f.lines = lines;
		local lineHeight = 21;
		f.lineHeight = lineHeight;
		local fname = f:GetName();
		local firstHeader = nil;
		local lastHeader = nil;
		local totalWidth = 0;
		local xoff = 0;
		local numColumns = table.getn(column);
		f.numColumns = numColumns;
		for i = 1,numColumns do
			local w = column[i].width;
			if not(w) then
				w = 30;
				column[i].width = w;
			end
			totalWidth = totalWidth + w;
		end
		
		for i = 1,numColumns do
			local w = column[i].width;
			local Type = column[i].type;
			
			local header = CreateFrame("Button",fname.."_H"..i,f,"GHM_Header_Template");
			header:SetWidth(w);
			getglobal(header:GetName().."Middle"):SetWidth(w-7);
			header:SetText(column[i].catagory);
			header.label = column[i].label;
			if lastHeader then
				header:SetPoint("TOPLEFT", lastHeader, "TOPRIGHT", 0, 0);
			else
				header:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -5);
			end
			
			header:SetScript("OnClick",function()
				PlaySound("igMainMenuOptionCheckBoxOn");
				local f = header:GetParent();
				if f.sortFilter == header.label then
					f.sortDir = mod(f.sortDir+1,2);
				else
					f.sortDir = 0;
				end
				f.sortFilter = header.label;
				f.UpdateAll();
			end);
			
			header:Show();
			if i==1 then
				firstHeader = header;
				
			end
			lastHeader = header;
			local lastObject = nil;
			for j = 1,lines do
				if i == 1 then
					local line = CreateFrame("Button",fname.."_L"..j,f);
					line:SetHeight(lineHeight);
					line:SetWidth(totalWidth);
					line.num = j;
					line:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
					line:SetPoint("TOPLEFT", header, "TOPLEFT", 0, lineHeight*(-(j-1)) - 24);
					line:Show();
					line:SetScript("OnClick",function()
						local f = line:GetParent();
						f.SetMarked(line.num + f.offset);
					end);
				end
				if Type == "Text" then
					local obj = CreateFrame("Frame",fname.."_L"..j.."_H"..i,getglobal(fname.."_L"..j),"GHM_Text_Template");
					obj:SetWidth(w)
					obj:SetHeight(lineHeight);
					obj:SetPoint("LEFT", obj:GetParent(), "LEFT", xoff, 0);
					getglobal(obj:GetName().."Label"):SetTextColor(1,1,1);	
				elseif Type == "Icon" then
					local obj = CreateFrame("Frame",fname.."_L"..j.."_H"..i,getglobal(fname.."_L"..j));
					obj:SetHeight(lineHeight);
					obj:SetWidth(lineHeight);
					obj:SetPoint("LEFT", obj:GetParent(), "LEFT", xoff, 0);
					obj.texture = obj:CreateTexture()
					obj.texture:SetAllPoints(obj)
					obj.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
					obj.Force = function(data) 
						if type(data)=="string" then
							obj.texture:SetTexture(data);
						else
							obj.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
						end
					end
					obj:Show();
				elseif Type == "CycleButton" then
					local obj = CreateFrame("Button",fname.."_L"..j.."_H"..i,getglobal(fname.."_L"..j),"GameMenuButtonTemplate");
					obj:SetHeight(lineHeight);
					obj:SetWidth(w);
					obj:SetPoint("LEFT", obj:GetParent(), "LEFT", xoff, 0);
					obj:SetText("");
					--obj:SetTextColor(1,1,1);	
					obj.cycles = column[i].cycles;
					--obj:SetFont("Fonts\\FRIZQT__.TTF",10);
					obj.label = column[i].label;
					obj.Force = function(data) 
						if type(data) == "number" then 
							obj:SetText(obj.cycles[data]);
							obj:Show();
						else
							obj:Hide();
						end
					end;
					obj:SetScript("OnClick",function()
						local id = obj.id;
						local f = obj:GetParent():GetParent();
						if type(obj.cycles) == "table" and type(id) == "number" then 
							local tuble = f.GetTuble(id);
							local num = tuble[obj.label];
							if type(num) == "number" then
								num = num + 1;
								if num > table.getn(obj.cycles) then
									num = 1;
								end
								tuble[obj.label] = num;
								f.SetTuble(id,tuble);
							end
						end
					end);
					obj:Show();
				elseif Type == "CheckButton" then
					local obj = CreateFrame("CheckButton",fname.."_L"..j.."_H"..i,getglobal(fname.."_L"..j),"OptionsCheckButtonTemplate");
					obj:SetHeight(min(w,lineHeight));
					obj:SetWidth(min(w,lineHeight));
					obj:SetPoint("LEFT", obj:GetParent(), "LEFT", xoff, 0);
					obj:SetChecked(nil);
					
					obj:SetHitRectInsets(0,0,0,0)
					
					obj.label = column[i].label;
					obj.Force = function(data) 
						obj:SetChecked(data);
					end;
					
					obj:SetScript("OnClick",function()
						local id = obj.id;
						local f = obj:GetParent():GetParent();
						if type(id) == "number" then 
							local tuble = f.GetTuble(id);
							
							tuble[obj.label] = obj:GetChecked() and true;
							f.SetTuble(id,tuble);
							
						end
					end);
					
				end
			end
			xoff = xoff + w;
		end
		
		f:SetHeight(lineHeight*lines + lastHeader:GetHeight() +9);
		f:SetWidth(totalWidth+27);
		if lastHeader then -- header above scroll bar
			local scroll = CreateFrame("ScrollFrame",fname.."_Scroll",f,"GHM_ListScrollBar_Template");
			f.scroll = scroll;
			scroll:SetHeight(lineHeight*lines);
			scroll:SetWidth(totalWidth);
			local header = CreateFrame("Button",fname.."_H"..numColumns+1,f,"GHM_Header_Template");
			local w = 16;
			header:SetWidth(w);
			getglobal(header:GetName().."Middle"):SetWidth(w-7);
			header:SetPoint("TOPLEFT", lastHeader, "TOPRIGHT", 0, 0);
			
			
			
			scroll:SetPoint("TOPRIGHT", header, "BOTTOMLEFT", -4, 0);
			scroll:Show();
			header:Show();
			
			scroll:SetScript("OnShow",function()
				--GHI_Message("f.lines is "..f.lines);
				local f = scroll:GetParent();
				--FauxScrollFrame_Update(scroll,f.lastSize,f.lines,f.lineHeight); --f.lines
				f.offset = FauxScrollFrame_GetOffset(scroll);
				--GHI_Message("Offset: "..f.offset);
				f.UpdateAll();
				
			end); 
			
			--[[
			scroll:SetScript("OnVerticalScroll",function()
				FauxScrollFrame_OnVerticalScroll(scroll.self,offset,f.lineHeight,function()
					local f = scroll:GetParent();
					FauxScrollFrame_Update(scroll,f.lastSize,f.lines,f.lineHeight);
					f.offset = FauxScrollFrame_GetOffset(scroll);
					f.UpdateAll();
				end)
			end); ]]--
		end
		
		
		return f:GetHeight();
	end;
	
	f.UpdateAll = function()
		--	O(n^2)
		if f.locked == true then return end;
		local Sort = f.sortFilter; -- name of the catagories or nil (if nil then sort by x)
		local dir = f.sortDir;
		local sortedData = f.data;
		--  syntax =  data[x][label]
		if Sort and type(sortedData) == "table" then
			for j = 1,table.getn(sortedData) do
				local key = sortedData[j];
				local i = j-1;
				
				
				if type(key[Sort])=="boolean" or key[Sort] == nil then
					break;
					--[[
					if dir == 1 then
						
						while i > 0 and key[Sort] == sortedData[i][Sort] do
							sortedData[i+1] = sortedData[i];
							i = i - 1;
						end
					else
						while i > 0 and (key[Sort] == sortedData[i][Sort]) do
							sortedData[i+1] = sortedData[i];
							i = i - 1;
						end
					end--]]
					-- todo: gives problems with markings because it is not concequent
				else
					if dir == 1 then
						
						while i > 0 and key[Sort] and (not(sortedData[i][Sort]) or strbyte(strlower(sortedData[i][Sort])) < strbyte(strlower(key[Sort])) or (strbyte(strlower(sortedData[i][Sort])) == strbyte(strlower(key[Sort])) and  strbyte(strlower(sortedData[i][Sort]),2) < strbyte(strlower(key[Sort]),2) ) ) do
							sortedData[i+1] = sortedData[i];
							i = i - 1;
						end
					else
						while i > 0 and key[Sort] and (not(sortedData[i][Sort]) or strbyte(strlower(sortedData[i][Sort])) > strbyte(strlower(key[Sort])) or (strbyte(strlower(sortedData[i][Sort])) == strbyte(strlower(key[Sort])) and  strbyte(strlower(sortedData[i][Sort]),2) > strbyte(strlower(key[Sort]),2) ) ) do
							sortedData[i+1] = sortedData[i];
							i = i - 1;
						end
					end
				end
				
				
				sortedData[i+1] = key;
			end
		end
		
		f.data = sortedData;
		
		local offset = f.offset;
		if not(offset) then
			offset = 0;
		end
		local lines = f.lines;
		--- Show data.
		
		
		
		--for index,value in pairs(sortedData[1]) do
		for i = 1,f.numColumns do
			
			local f1 = getglobal(f:GetName().."_H"..i);
							
			
			for j = 1,lines do
				local k = j + offset;
				local f2 = getglobal(f:GetName().."_L"..j.."_H"..i);
				if type(sortedData) == "table" and type(sortedData[k]) == "table" then
					local d = sortedData[k][f1.label];
					
					if f2 then
						f2.Force(d);								
						f2.id = k;
					end
					local line = getglobal(f:GetName().."_L"..j)
					line:Show();
					if sortedData[k].marked == true then
						line:LockHighlight()
					else
						line:UnlockHighlight()
					end
				else
					getglobal(f:GetName().."_L"..j):Hide();
				end
			end				
			
		end
		
		if type(sortedData) == "table" and not(f.lastSize == table.getn(sortedData)) then
			FauxScrollFrame_Update(f.scroll,table.getn(sortedData),f.lines,f.lineHeight);
			f.lastSize = table.getn(sortedData);
		end
		
		
		
		
	end
	
	f.Force = function(t)
		if type(t) == "table" then
			f.data = t;
			
			f.UpdateAll()
			f.main.SetLabel(f.label,f.data);
		end
	end
	
	f.Clear = function()
		
		f.data = {};
			
		f.UpdateAll()
		f.main.SetLabel(f.label,f.data);
		
	end
	
	
	f.GetTuble = function(number)
		if type(f.data[number]) == "table" then
			return f.data[number];
		else
			return {};
		end
	end
	
	f.SetTuble = function(number,tuble)
		if type(number) == "number" and type(tuble) == "table" then
		
			f.data[number] = tuble;
			f.UpdateAll()
			f.main.SetLabel(f.label,f.data);
		end
	end
	
	f.DeleteTuble = function(number)
		if f.locked == true then return end;
		table.remove(f.data,number);
		f.UpdateAll()
		f.main.SetLabel(f.label,f.data);
	end
	
	f.InsertTuble = function(tuble)
		table.insert(f.data,tuble);
		Warning("tuble inserted. Total tubles: "..table.getn(f.data));
		f.UpdateAll()
		f.main.SetLabel(f.label,f.data);
	end
	
	f.GetMarked = function()
		for i = 1,table.getn(f.data) do
			if type(f.data[i]) == "table" then
				if f.data[i].marked == true then
					return i;
				end			
			end		
		end
	end
	
	f.SetMarked = function(num) 
		for i = 1,table.getn(f.data) do
			if type(f.data[i]) == "table" then
				if i == num then
					f.data[i].marked = true; 
				else
					f.data[i].marked = false;
				end			
			end		
		end
		f.UpdateAll()
		if type(f.onclick) == "function" then
			f.onclick(f,num)
		end
	end
	
end



--[[

RC_List = {}
RC_List[1] = {}
RC_List[2] = {}
RC_List[3] = {}
RC_List[4] = {}
RC_List[5] = {}
RC_List[6] = {}
RC_List[7] = {}
RC_List[8] = {}
RC_List[1]["type"]="Script";
RC_List[1]["details"]="A script that do something";
RC_List[2]["type"]="GHR";
RC_List[2]["details"]="Stormwind Militia";
RC_List[2]["req"]=3;
RC_List[3]["type"]="Bag";
RC_List[3]["details"]="4 slots";
RC_List[3]["req"]=2;
RC_List[4]["type"]="Expression";
RC_List[4]["details"]="looks around.";
RC_List[5]["type"]="Expression";
RC_List[5]["details"]="For Stormwind.";
RC_List[6]["type"]="Random expression";
RC_List[6]["details"]="Six expressions";
RC_List[7]["req"]=1;
RC_List[7]["type"]="Script";
RC_List[7]["details"]="while( (drunk == true or drunk == false) and awake == true and this:GetNearstAleSupply():GetStorageAmount() > 0) do this.Drink(beer) end";
RC_List[8]["type"]="Letter/Book";
RC_List[8]["details"]="2 pages";
local obj = {};

TestProfile = {};
TestProfile.name = "GHM_Tester";
TestProfile.title = "Create new GHI item";
TestProfile.theme = "WizardTheme";
TestProfile.height = 512;
TestProfile.OnOk = function()  end
TestProfile.icon = "Interface\\Icons\\Trade_Engineering";

TestProfile[1] = {};
TestProfile[1].name = "Generel";
TestProfile[1][1] = {};
TestProfile[1][2] = {};
TestProfile[1][3] = {};
TestProfile[1][4] = {};
TestProfile[1][5] = {};
TestProfile[1][6] = {};
TestProfile[1][7] = {};
TestProfile[1][8] = {};
TestProfile[1][9] = {};
TestProfile[1][10] = {};


TestProfile[2] = {};
TestProfile[2].name = "Right Click";
TestProfile[2][1] = {};
TestProfile[2][2] = {};
TestProfile[2][3] = {};
TestProfile[2][4] = {};
TestProfile[2][5] = {};
TestProfile[2][6] = {};
TestProfile[2][7] = {};

local obj2 = {};

obj = {};
obj.type = "List";
obj.lines = 6;
obj.align = "c";
obj.label = "RCList";
obj2 = {};
obj2[1] = {}
obj2[1].type = "Icon";
obj2[1].catagory = "";
obj2[1].width = 20;
obj2[1].label = "icon";
obj2[2] = {}
obj2[2].type = "Text";
obj2[2].catagory = "Type";
obj2[2].width = 120;
obj2[2].label = "type";
obj2[3] = {}
obj2[3].type = "Text";
obj2[3].catagory = "Details";
obj2[3].width = 200;
obj2[3].label = "details";
obj2[4] = {}
obj2[4].type = "CycleButton";
obj2[4].cycles = {"Run Always","is forfilled","is not forfilled"};
obj2[4].catagory = "Run When Req.";
obj2[4].width = 100;
obj2[4].label = "req";
obj.column = obj2;
table.insert(TestProfile[2][2],obj);



obj = {};
obj.type = "Text";
obj.fontSize = 16;
obj.text = "General Item Info";
obj.align = "c";
table.insert(TestProfile[1][1],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = "Buff";
obj.align = "l";
obj.width = 40
obj.singleLine = true;
table.insert(TestProfile[1][2],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = "A Holy Blessing";
obj.align = "l";
obj.width = 80
obj.singleLine = true;
table.insert(TestProfile[1][2],obj);

obj = {};
obj.type = "Button";
obj.text = "Run Always";
obj.align = "l";
obj.label = "button1";
obj.compact = true;
obj.onclick = function()  end
obj.width = 80;
table.insert(TestProfile[1][2],obj);

obj = {};
obj.type = "Button";
obj.text = "Clicky";
obj.align = "r";
obj.label = "button2";
obj.compact = true;
obj.onclick = function()  end
obj.width = 50;
table.insert(TestProfile[1][2],obj);


obj = {};
obj.type = "Editbox";
obj.text = "Name:";
obj.align = "l";
obj.label = "name";
table.insert(TestProfile[1][3],obj);

obj = {};
obj.type = "QualityDD";
obj.text = "Quality:";
obj.align = "c";
obj.label = "quality";
table.insert(TestProfile[1][3],obj);

obj = {};
obj.type = "Icon";
obj.text = "Icon:";
obj.align = "r";
obj.label = "icon";
obj.framealign = "r";
obj.CloseOnChoosen = true;
table.insert(TestProfile[1][3],obj);

obj = {};
obj.type = "Editbox";
obj.text = "White text 1:";
obj.align = "c";
obj.label = "white1";
table.insert(TestProfile[1][4],obj);

obj = {};
obj.type = "Editbox";
obj.text = "White text 2:";
obj.align = "c";
obj.label = "white2";
table.insert(TestProfile[1][5],obj);

obj = {};
obj.type = "Editbox";
obj.text = "Yellow quoted text:";
obj.align = "c";
obj.label = "quote";
table.insert(TestProfile[1][6],obj);

obj = {};
obj.type = "Editbox";
obj.text = "Amount:";
obj.align = "r";
obj.label = "amount";
obj.width = 50;
obj.numbersOnly = true;
table.insert(TestProfile[1][7],obj);

obj = {};
obj.type = "StackSlider";
obj.text = "Stack Size:";
obj.align = "c";
obj.label = "stackSize";
table.insert(TestProfile[1][7],obj);

obj = {};
obj.type = "CheckBox";
obj.text = "Copyable by others";
obj.align = "l";
obj.label = "copyable";
table.insert(TestProfile[1][7],obj);

obj = {};
obj.type = "TimeSlider";
obj.text = "Item duration:";
obj.align = "c";
obj.label = "duration";
obj.values = {0,1,5,10,15,30,60,90,120,60*5,60*10,60*15,60*30,60*60,60*90,60*60*2,60*60*5,60*60*10,60*60*20,60*60*24,60*60*24*2,60*60*24*7,60*60*24*14,60*60*24*30,60*60*24*30*2,60*60*24*30*3,60*60*24*30*6,60*60*24*365}
table.insert(TestProfile[1][8],obj);

obj = {};
obj.type = "CheckBox";
obj.text = "Start duration when traded";
obj.align = "l";
obj.label = "durationWhenTraded";
table.insert(TestProfile[1][9],obj);

obj = {};
obj.type = "CheckBox";
obj.text = "Use real time, instead of played time for duration.";
obj.align = "c";
obj.label = "durationWhenTraded";
table.insert(TestProfile[1][9],obj);





obj = {};
obj.type = "Text";
obj.fontSize = 16;
obj.text = "Rightclick Actions";
obj.align = "c";
table.insert(TestProfile[2][1],obj);  --]]

--[[
obj = {};
obj.type = "Text";
obj.fontSize = 18;
obj.text = "CENTER!";
obj.align = "c";
obj.label = "headline";
table.insert(TestProfile[1][1],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = "Left";
obj.align = "l";
obj.label = "string1";
table.insert(TestProfile[1][2],obj);

obj = {};
obj.type = "Editbox";
obj.text = "Name:";
obj.align = "c";
obj.label = "Name";
table.insert(TestProfile[1][3],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = "After";
obj.align = "c";
obj.label = "string2";
table.insert(TestProfile[1][4],obj);


obj = {};
obj.type = "StackSlider";
obj.text = "Time to live:";
obj.align = "r";
obj.label = "stackSize";
table.insert(TestProfile[1][5],obj);

obj = {};
obj.type = "TimeSlider";
obj.text = "Name3:";
obj.align = "l";
obj.label = "time";
table.insert(TestProfile[1][6],obj);


obj = {};
obj.type = "CheckBox";
obj.text = "Choose";
obj.align = "r";
obj.label = "chosen";
table.insert(TestProfile[1][7],obj);

obj = {};
obj.type = "QualityDD";
obj.text = "Quality:";
obj.align = "c";
obj.label = "quality";
table.insert(TestProfile[1][8],obj);

obj = {};
obj.type = "Icon";
obj.text = "Icon:";
obj.align = "r";
obj.label = "icon";
obj.framealign = "r";
obj.CloseOnChoosen = true;
table.insert(TestProfile[1][8],obj);

obj = {};
obj.type = "Icon";
obj.text = "Icon:";
obj.align = "c";
obj.label = "icon";
obj.CloseOnChoosen = true;
table.insert(TestProfile[1][9],obj);


obj = {};
obj.type = "QualityDD";
obj.text = "Quality:";
obj.align = "r";
obj.label = "quality2";
obj.initPos = 4;
table.insert(TestProfile[1][12],obj);

obj = {};
obj.type = "Button";
obj.text = "Exit.";
obj.align = "l";
obj.label = "button1";
obj.compact = false;
obj.onclick = function() GHI_Message("clicked"); end
table.insert(TestProfile[1][13],obj);

obj = {};
obj.type = "Icon";
obj.text = "Icon:";
obj.align = "c";
obj.label = "icon";
obj.CloseOnChoosen = true;
table.insert(TestProfile[1][14],obj);

]]
