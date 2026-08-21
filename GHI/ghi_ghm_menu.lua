
--[[ 	RC catagories:
Expression
Random expression
Script
Letter / Book
Buff
Sound
Equip item
Bag
GHR
Requirement


todo:
Create other item
key
remove buff

]]


GHI_RCIcons = {};
GHI_RCIcons["script"] = "Interface\\Icons\\Trade_Engineering";
GHI_RCIcons["expression"] = "Interface\\Icons\\Spell_Shadow_SoothingKiss";
GHI_RCIcons["random_expression"] = "Interface\\Icons\\Ability_Warrior_RallyingCry";
GHI_RCIcons["book"] = "Interface\\Icons\\INV_Misc_Book_09";
GHI_RCIcons["buff"] = "Interface\\Icons\\Spell_Holy_WordFortitude";
GHI_RCIcons["sound"] = "Interface\\Icons\\INV_Misc_Drum_01";
GHI_RCIcons["equip_item"] = "Interface\\Icons\\INV_Helmet_03";
GHI_RCIcons["bag"] = "Interface\\Icons\\INV_Misc_Bag_09_Blue";
GHI_RCIcons["requirement"] = "Interface\\Icons\\INV_Misc_QuestionMark";
GHI_RCIcons["ghr"] = "Interface\\Icons\\Achievement_Reputation_01";
GHI_RCIcons["time"] = "Interface\\Icons\\INV_Misc_PocketWatch_02";
GHI_RCIcons["produce_item"] = "Interface\\Icons\\Spell_ChargePositive";
GHI_RCIcons["consume_item"] = "Interface\\Icons\\Spell_ChargeNegative";
GHI_RCIcons["message"] = "Interface\\Icons\\INV_Misc_Note_04";
GHI_RCIcons["remove_buff"] = "Interface\\Icons\\Spell_Arcane_Arcane02";

GHI_RCRequirements = {"Name","Level","Zone","SubZone","Guild","Class","Race","Gender","Normal Item","Base Stats","Skill","Reputation","Honor Kills","Normal Buff","GHI Buff","LUA Statement"};

local obj = {};

GHI_RC_Menu = {};

if 1==1 then --	Expression			ok	localized
local c = "expression"
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_EXPRESSION;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 340;
GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local text = main.GetLabel("text");
	local Type = main.GetLabel("type");
	local delay = main.GetLabel("delay");
	local menu = main.madeBy.main; 
	if menu then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			local t = {};
			t["Type"] = "expression";
			t["type_name"] = GHI_EXPRESSION; 
			
			t["req"] = 1;
			t["icon"] = GHI_RCIcons["expression"];
			
			local Types = {"Say","Emote"};
			local LocTypes = {GHI_SAY,GHI_EMOTE};
			--GHI_Message((Type or "")..": "..type(Type));
			t["details"] = (LocTypes[Type] or "")..": "..strsub(text,0,100);
			t["text"] = text;
			
			t["expression_type"] = Types[Type];
			t["expression_type_i"] = Type;
			t["delay"] = delay;
			
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				list.InsertTuble(t);
			end

		end
	end
end;

GHI_RC_Menu[c][1] = {};

GHI_RC_Menu[c][1][1] = {};
GHI_RC_Menu[c][1][2] = {};
GHI_RC_Menu[c][1][3] = {};
GHI_RC_Menu[c][1][4] = {};

obj = {};
obj.type = "Editbox";
obj.text = GHI_TEXT;
obj.align = "c";
obj.label = "text";
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "CustomDD";
obj.text = GHI_TYPE;
obj.align = "l";
obj.label = "type";
obj.returnIndex = true;
obj.data = {GHI_SAY,GHI_EMOTE};
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_DELAY;
obj.align = "r";
obj.label = "delay";
obj.width = 50;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "Dummy";
obj.height = 10;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][3],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_EXPRESSION_TEXT;
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][4],obj);


end
if 1==1 then --	Random Expression	ok	localized
local c = "random_expression"
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_RANDOM_EXPRESSION;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 580;
GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local menu = main.madeBy.main; 
	if menu then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			local t = {};
			local Types = {"Say","Emote"};
						
			t["Type"] = "random_expression";	
			t["type_name"] = GHI_RANDOM_EXPRESSION;
			t["req"] = 1;
			t["icon"] = GHI_RCIcons["random_expression"];
			
			local c = 0;
			t["text"] = {};
			t["expression_type"] = {};
			t["expression_type_i"] = {};
			for i = 1,6 do
				table.insert(t["text"],i,main.GetLabel("text"..i));
				local et = main.GetLabel("type"..i);
				table.insert(t["expression_type_i"],i,et);
				table.insert(t["expression_type"],i,Types[et]);
				if (t["text"][i]) and not(t["text"][i] == "") then
					c = c+1;
				end
			end
			t["allow_same"] = main.GetLabel("allow_same")
			
			t["details"] = c.." "..GHI_EXPRESSIONS..".";
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				list.InsertTuble(t);
			end
		end
	end
end;

GHI_RC_Menu[c][1] = {};
for i = 1,10 do
GHI_RC_Menu[c][1][i] = {};
end

for i = 1,6 do
obj = {};
obj.type = "Editbox";
obj.text = GHI_TEXT;
obj.align = "l";
obj.label = "text"..i;
obj.width = 200;
table.insert(GHI_RC_Menu[c][1][i],obj);

obj = {};
obj.type = "CustomDD";
obj.text = GHI_TYPE;
obj.align = "r";
obj.label = "type"..i;
obj.width = 90;
obj.returnIndex = true;
obj.data = {GHI_SAY,GHI_EMOTE};
table.insert(GHI_RC_Menu[c][1][i],obj);

end


obj = {};
obj.type = "Dummy";
obj.height = 10;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][7],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_RANDOM_EXPRESSION_TEXT;
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][8],obj);

obj = {};
obj.type = "Dummy";
obj.height = 10;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][9],obj);

obj = {};
obj.type = "CheckBox";
obj.text = GHI_RANDOM_EXPRESSION_ALLOW_SAME;
obj.align = "l";
obj.label = "allow_same";
table.insert(GHI_RC_Menu[c][1][10],obj);

end
if 1==1 then --	Script			ok	localized
local c = "script"
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_SCRIPT;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 560;
GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local code = main.GetLabel("code");
	local menu = main.madeBy.main; 
	if menu then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			local t = {};
			t["Type"] = "script";
			t["type_name"] = GHI_SCRIPT;
			t["details"] = strsub(code,0,100);
			t["req"] = 1;
			t["icon"] = GHI_RCIcons["script"];
			
			t["code"] = {};
			while not(code == nil) and not(code == "") do
				table.insert(t["code"],string.sub(code,0,127));
				code = string.sub(code,128);
			end
			t["delay"] = main.GetLabel("delay");
			
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				list.InsertTuble(t);
			end
		end
	end
end;
GHI_RC_Menu[c][1] = {};

GHI_RC_Menu[c][1][1] = {};
GHI_RC_Menu[c][1][2] = {};
GHI_RC_Menu[c][1][3] = {};
GHI_RC_Menu[c][1][4] = {};

obj = {};
obj.type = "EditField";
obj.align = "c";
obj.height = 260;
obj.width = 260;
obj.label = "code";
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_DELAY;
obj.align = "c";
obj.label = "delay";
obj.width = 50;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "Dummy";
obj.height = 10;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][3],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_SCRIPT_TEXT;
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][4],obj);


end
if 1==1 then --	book				ok	localized
local c = "book"
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_BOOK;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 340;
GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local menu = main.madeBy.main; 
	if menu then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			--GHI_Message("Book num: "..(main.edit or "nil"));
			local t = {};
			if main.edit then
				t = list.GetTuble(main.edit);
				--GHI_Message("Got touble "..type(t));
				if not(type(t) == "table") then
					t = {};
				end
			end
			
			local title = main.GetLabel("title")
			
			t["title"] = title;
			
			t["details"] = title;
			t["Type"] = "book";	
			t["type_name"] = GHI_BOOK;
			t["req"] = 1;
			t["icon"] = GHI_RCIcons["book"];
					
			t["pages"] = main.GetLabel("pages");
			if not(type(t["pages"]) == "number") then
				t["pages"] = 1;
			end

			for i = 1,t["pages"] do
				t[i] = main.GetLabel(i);
			end
			
			if t[1] == nil then
				t[1] = "";
			end
			
			t["h1"] = main.GetLabel("h1");
			t["h2"] = main.GetLabel("h2");
			t["font"] = main.GetLabel("font");
			t["material"] = main.GetLabel("material");
			
			
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				list.InsertTuble(t);
			end
		end
	end
end;
GHI_RC_Menu[c].OnShow = function()
	local main = this;
	local f = main.GetLabelFrame("title");
	if f then
		f:SetFocus();
	end
end;


GHI_RC_Menu[c][1] = {};
for i = 1,4 do
GHI_RC_Menu[c][1][i] = {};
end

obj = {};
obj.type = "Dummy";
obj.height = 20;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_TITLEM;
obj.align = "c";
obj.label = "title";
obj.width = 200;
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "Dummy";
obj.height = 20;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][3],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_TITLE_TEXT;
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][4],obj);


end
if 1==1 then --	buff				ok	localized
local c = "buff"
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_BUFF;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 470;
GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local menu = main.madeBy.main; 
	if menu then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			local t = {};
			
			
			t["buffName"] = main.GetLabel("buff_name");
			t["buffDetails"] = main.GetLabel("buff_details");
			t["untillCanceled"] = main.GetLabel("untill_canceled");
			t["filter"] = main.GetLabel("filter");
			t["buffType"] = main.GetLabel("buff_type");
			-- The icon selector keeps the exact path on the control.  Prefer
			-- that over the label cache so the chosen buff icon survives
			-- Turtle/Vanilla texture handling unchanged.
			local buffIconFrame = main.GetLabelFrame("buff_icon");
			local buffIcon = main.GetLabel("buff_icon");
			if buffIconFrame and type(buffIconFrame.selectedPath) == "string" and buffIconFrame.selectedPath ~= "" then
				buffIcon = buffIconFrame.selectedPath;
			end
			t["buffIcon"] = buffIcon;
			t["buffDuration"] = main.GetLabel("buff_duration");
			t["castOnSelf"] = main.GetLabel("castOnSelf");
			t["stackable"] = main.GetLabel("stackable");
			t["delay"] = main.GetLabel("delay");
			t["count"] = main.GetLabel("amount");
			t["range"] = main.GetLabel("range");
			
			
			t["type_name"] = GHI_BUFF;
			t["Type"] = "buff";
			t["details"] = strsub(main.GetLabel("buff_name"),0,100);
			t["req"] = 1;
			t["icon"] = GHI_RCIcons["buff"];			
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				list.InsertTuble(t);
			end
		end
	end
end;

GHI_RC_Menu[c][1] = {};
for i = 1,9 do
GHI_RC_Menu[c][1][i] = {};
end


obj = {};
obj.type = "Editbox";
obj.text = GHI_BUFF_NAME;
obj.align = "c";
obj.label = "buff_name";
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_BUFF_DETAILS;
obj.align = "c";
obj.label = "buff_details";
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "TimeSlider";
obj.text = GHI_BUFF_DURATION;
obj.align = "r";
obj.label = "buff_duration";
table.insert(GHI_RC_Menu[c][1][3],obj);

obj = {};
obj.type = "CheckBox";
obj.text = GHI_BUFF_UNTIL_CANCELED;
obj.align = "l";
obj.label = "untill_canceled";
table.insert(GHI_RC_Menu[c][1][3],obj);

obj = {};
obj.type = "CheckBox";
obj.text = GHI_BUFF_ON_SELF;
obj.align = "l";
obj.label = "castOnSelf";
table.insert(GHI_RC_Menu[c][1][4],obj);

obj = {};
obj.type = "Dummy";
obj.height = 10;
obj.width = 40;
obj.align = "r";
table.insert(GHI_RC_Menu[c][1][4],obj);

obj = {};
obj.type = "CheckBox";
obj.text = GHI_STACKABLE;
obj.align = "r";
obj.label = "stackable";
table.insert(GHI_RC_Menu[c][1][4],obj);

obj = {};
obj.type = "CustomDD";
obj.text = GHI_BUFF_DEBUFF;
obj.align = "l";
obj.label = "filter";
obj.returnIndex = false;
obj.width = 110;
obj.data = {};
obj.data[1] = "Helpful";
obj.data[2] = "Harmful";
table.insert(GHI_RC_Menu[c][1][5],obj);

obj = {};
obj.type = "CustomDD";
obj.text = GHI_BUFF_TYPE;
obj.align = "r";
obj.label = "buff_type";
obj.returnIndex = false;
obj.width = 110;
obj.data = {};
obj.data[1] = "Magic";
obj.data[2] = "Curse";
obj.data[3] = "Disease";
obj.data[4] = "Poison";
obj.data[5] = "Physical";
table.insert(GHI_RC_Menu[c][1][5],obj);

obj = {};
obj.type = "Icon";
obj.text = GHI_ICON;
obj.align = "c";
obj.label = "buff_icon";
obj.framealign = "r";
obj.CloseOnChoosen = true;
table.insert(GHI_RC_Menu[c][1][5],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_DELAY;
obj.align = "r";
obj.label = "delay";
obj.width = 30;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][6],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_AMOUNT;
obj.align = "c";
obj.label = "amount";
obj.width = 30;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][6],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_RANGE;
obj.align = "l";
obj.label = "range";
obj.width = 30;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][6],obj);

end
if 1==1 then --	sound				ok	localized
local c = "sound"
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_SOUND;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 340;
GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local menu = main.madeBy.main; 
	if menu then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			local t = {};
			
			
			t["sound_path"] = main.GetLabel("sound_path");
			t["delay"] = main.GetLabel("delay");
			
			t["range"] = main.GetLabel("range");
	
			t["type_name"] = GHI_SOUND;
			t["Type"] = "sound";
			t["details"] = "unpack(arg)"..strsub(t["sound_path"],strlen(t["sound_path"])-25);
			t["req"] = 1;
			t["icon"] = GHI_RCIcons["sound"];			
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				list.InsertTuble(t);
			end
		end
	end
end;

GHI_RC_Menu[c][1] = {};
for i = 1,3 do
GHI_RC_Menu[c][1][i] = {};
end


obj = {};
obj.type = "Editbox";
obj.text = GHI_SOUNDFILEPATH;
obj.align = "c";
obj.label = "sound_path";
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_DELAY;
obj.align = "l";
obj.label = "delay";
obj.width = 50;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_RANGE;
obj.align = "r";
obj.label = "range";
obj.width = 50;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][2],obj);


obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.color = "white";
obj.text = GHI_SOUND_EX;
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][3],obj);

end
if 1==1 then --	equip_item			ok	localized
local c = "equip_item"
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_EQUIP_ITEM;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 340;
GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local menu = main.madeBy.main; 
	if menu then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			local t = {};
			
			
			t["item_name"] = main.GetLabel("item_name");
			t["delay"] = main.GetLabel("delay");

	
			t["type_name"] = GHI_EQUIP_ITEM;
			t["Type"] = "equip_item";
			t["details"] = strsub(main.GetLabel("item_name"),0,100);
			t["req"] = 1;
			t["icon"] = GHI_RCIcons["equip_item"];			
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				list.InsertTuble(t);
			end
		end
	end
end;

GHI_RC_Menu[c][1] = {};
for i = 1,3 do
GHI_RC_Menu[c][1][i] = {};
end


obj = {};
obj.type = "Editbox";
obj.text = GHI_ITEM_NAME;
obj.align = "c";
obj.label = "item_name";
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_DELAY;
obj.align = "c";
obj.label = "delay";
obj.width = 50;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][2],obj);

end
if 1==1 then --	bag				ok	localized
local c = "bag"
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_BAG;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 340;
GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local menu = main.madeBy.main; 
	if menu then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			local t = {};
			t["texture_i"] = main.GetLabel("texture");
			
			local textures = {"Normal","Bank","Keyring"};
			
			t["size"] = main.GetLabel("slots");
			t["texture"] = "-"..(textures[t["texture_i"]] or "");
			
			t["type_name"] = GHI_BAG;
			t["Type"] = "bag";
			if t["size"] then		t["details"] = t["size"].." slots";  end
			t["req"] = 1;
			t["icon"] = GHI_RCIcons["bag"];			
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				list.InsertTuble(t);
			end
		end
	end
end;

GHI_RC_Menu[c][1] = {};
for i = 1,4 do
GHI_RC_Menu[c][1][i] = {};
end


obj = {};
obj.type = "SlotSlider";
obj.text = GHI_SLOTS;
obj.align = "c";
obj.width = 150;
obj.label = "slots";
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "CustomDD";
obj.text = GHI_TEXTURE;
obj.align = "c";
obj.label = "texture";
obj.returnIndex = true;
obj.width = 110;
obj.data = {};
obj.data[1] = GHI_NORMAL;
obj.data[2] = GHI_BANK;
obj.data[3] = GHI_KEYRING;
table.insert(GHI_RC_Menu[c][1][4],obj);

end
if 1==1 then --	GHR				ok	localized
local c = "ghr"
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_GHR;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 340;
GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local menu = main.madeBy.main; 
	if menu then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			local t = {};
			
			local fac = main.GetLabel("faction")+1;
			if not(fac) or not(type(GHR_FactionData) == "table") then return end;
			t["amount"] = main.GetLabel("amount");
			
			t["faction"] = GHR_FactionData[fac].ID;
			
			t["type_name"] = GHI_GHR;
			t["Type"] = "ghr";
			if GHR_FactionData[fac] then
				t["details"] = t["amount"].." "..GHI_REP_WITH.." "..GHR_FactionData[fac].name..".";
			end
			t["req"] = 1;
			t["icon"] = GHI_RCIcons["ghr"];			
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				list.InsertTuble(t);
			end
		end
	end
end;

GHI_RC_Menu[c].OnShow = function()
	local label = "faction"; -- name of the label of the dropdown
	
	local new_table = {};
	if type(GHR_FactionData) == "table" then
		for i=2,table.getn(GHR_FactionData) do
			table.insert(new_table,GHR_FactionData[i].name);
		end
	end
	
	local main = this;
	local DD = main.GetLabelFrame(label);
	DD.dataTable = new_table;
	main.ForceLabel(label,1);
end;

GHI_RC_Menu[c][1] = {};
for i = 1,4 do
GHI_RC_Menu[c][1][i] = {};
end


obj = {};
obj.type = "Editbox";
obj.text = GHI_AMOUNT;
obj.align = "c";
obj.label = "amount";
obj.width = 50;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "CustomDD";
obj.text = GHI_FACTION;
obj.align = "c";
obj.label = "faction";
obj.returnIndex = true;
obj.width = 200;
obj.data = {};
obj.data[1] = "None";
table.insert(GHI_RC_Menu[c][1][3],obj);

--[[function GHI_SetUpGHR()
	local temp = {};
	if type(GHR_FactionData) == "table" then
		for i=2,table.getn(GHR_FactionData) do
			table.insert(temp,GHR_FactionData[i].name);
		end
	end
	return temp;
end
local script = "GHI_RC_Menu[\""..c.."\"][1][3][1].data = GHI_SetUpGHR();";
GHI_DoScript(script,30);--]]
end
if 1==1 then --	requirement		ok	localized
local c = "requirement"
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_REQUIREMENT;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 600;
GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local menu = main.madeBy.main; 
	if menu then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			local t = {};
			
			local req_type_i = main.GetLabel("type");
			local req_type = GHI_RCRequirements[req_type_i];
			
			local req_detail = main.GetLabel("text");
			local req_alias = main.GetLabel("alias"); -- used in LUA req's for GHP later
			
			t["details"] =  strsub(req_type..": "..req_detail,0,100);
			
			if req_type == "LUA Statement" then -- changes spaces and comma in the code, so it will show up as one part
				req_detail=gsub(req_detail," ","\21");
				req_detail=gsub(req_detail,",","\22");
				t["AddonReqName"] = "GHI";
				t["AddonReqData"] = 0.22;
			else 
				t["AddonReqName"] = nil;
				t["AddonReqData"] = nil;
			end
			
			t["req_type_i"] = req_type_i;
			t["req_type"] = req_type;
			t["req_detail"] = req_detail;
			t["req_alias"] = req_alias;
			
			t["type_name"] = GHI_REQUIREMENT;
			t["Type"] = "requirement";
			
			t["req"] = nil;
			t["icon"] = GHI_RCIcons["requirement"];			
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				list.InsertTuble(t);
			end
		end
	end
end;


GHI_RC_Menu[c][1] = {};
for i = 1,13 do
GHI_RC_Menu[c][1][i] = {};
end




obj = {};
obj.type = "CustomDD";
obj.text = GHI_REQ_TYPE;
obj.align = "l";
obj.label = "type";
obj.returnIndex = true;
obj.data = {};
for i=1,table.getn(GHI_RCRequirements) do
	table.insert(obj.data,GHI_REQ[GHI_RCRequirements[i]]);
end

table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_REQ_FILTER;
obj.align = "c";
obj.size = 512;
obj.label = "text";
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_REQ_TOOLTIP;
obj.align = "c";
obj.size = 512;
obj.label = "alias";
table.insert(GHI_RC_Menu[c][1][3],obj);

obj = {};
obj.type = "Dummy";
obj.height = 15;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][4],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_REQ_TEXT1;
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][5],obj);

obj = {};
obj.type = "Dummy";
obj.height = 25;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][6],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_REQ_TEXT2;
obj.align = "l";
obj.color = "white";
table.insert(GHI_RC_Menu[c][1][7],obj);

obj = {};
obj.type = "Dummy";
obj.height = 25;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][8],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_REQ_TEXT3; 
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][9],obj);

obj = {};
obj.type = "Dummy";
obj.height = 25;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][10],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_REQ_TEXT4; 
obj.align = "l";
obj.color = "white";
table.insert(GHI_RC_Menu[c][1][11],obj);

obj = {};
obj.type = "Dummy";
obj.height = 25;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][12],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_REQ_TEXT5; 
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][13],obj);

end

--	Dynamic RC
GHI_DynRCList = {}

if 1==1 then --	Time				ok	localized		
local c = "time"
table.insert(GHI_DynRCList,c);
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_TIME;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 340;
GHI_RC_Menu[c].dynamic_rc = true;
GHI_RC_Menu[c].formats = {"%H:%M","%H,%M","%H %M","%m/%d/%y","%m/%d/%y %H:%M:%S","%H:%M:%S","%H O'clock"};
GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local text = main.GetLabel("text");
	local Type_i = main.GetLabel("type");
	local delay = main.GetLabel("delay");
	local Format_index = main.GetLabel("format");
	local menu = main.madeBy.main; 
	if menu then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			local t = {};
			local Format = GHI_RC_Menu[c].formats[Format_index];
			
			local types = {"emote","say","green text","blue text"};
			local Type = types[Type_i];
			
			t["Type"] = "time";
			t["type_name"] = GHI_TIME;
			t["details"] = date(Format);
			--t["req"] = 1;
			t["icon"] = GHI_RCIcons["time"];
			
			t["text"] = text;
			t["expression_type"] = Type;
			t["expression_type_i"] = Type_i;
			t["delay"] = delay;
			t["format"] = Format;
			
			t["dynamic_rc"] = true;
			t["dynamic_rc_type"] = "time";
			
			
			
			local code;
			local format2 = gsub(gsub(gsub(Format,"H","\%%H"),"M","\%%M"),"S","\%%S");
			format2 = gsub(gsub(gsub(format2,"d","\%%d"),"m","\%%m"),"y","\%%y");
			
			local suffix,prefix = "";
			if Type == "emote" then
				suffix="emote";
				prefix=");";
			elseif Type == "say" then
				suffix="say";
				prefix=");";
			elseif Type == "green text" then
				local info = GHI_EffectColors["green"];
				suffix="DEFAULT_CHAT_FRAME:AddMessage";
				prefix=","..info.r..","..info.g..","..info.b..");";
				
			elseif Type == "blue text" then
				local info = GHI_EffectColors["blue"];
				suffix="DEFAULT_CHAT_FRAME:AddMessage";
				prefix=","..info.r..","..info.g..","..info.b..");";
			end
			code = "local hour,minute = GetGameTime(); local hm_server = ((hour*60)+minute)*60; local hm_local = mod(time(),60*60*24); local doff = 0; if hm_local < hm_server and hm_server - hm_local > 12 then doff = -1; elseif hm_server < hm_local and hm_local - hm_server > 12 then doff =1; end local server_time = (time()-hm_local) + (doff*60*60) + hm_server; "..suffix.."(\""..gsub(text,"TIME","\"..date(\""..format2.."\",server_time)..\"").."\""..prefix;
			
			
			
			t["code"] = {};
			while not(code == nil) and not(code == "") do
				table.insert(t["code"],string.sub(code,0,127));
				code = string.sub(code,128);
			end
			
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				t["req"] = 1;
				list.InsertTuble(t);
			end

		end
	end
end;
GHI_RC_Menu[c].OnShow = function()
	
	
	local new_table = {};
	local formats = GHI_RC_Menu[c].formats;
	for i=1,table.getn(formats) do
		new_table[i] = date(formats[i]);
	end
	
	local main = this;
	local DD = main.GetLabelFrame("format");
	DD.dataTable = new_table;
	
	local menu = main.madeBy.main; 
	--local list = menu.GetLabelFrame("RCList");
	
	if main.edit then
		local t = this.tuble;
		
		local Format = t["format"];
		for i=1,table.getn(formats) do
			if formats[i] == Format then
				main.ForceLabel("format",i);
			end
		end
		
		main.ForceLabel("type",t["expression_type_i"]);
		main.ForceLabel("text",t["text"]);
		main.ForceLabel("delay",t["delay"]);
	else	
		main.ForceLabel("format",1);
		main.ForceLabel("text","'s watch shows TIME.");
		
	end
end;

GHI_RC_Menu[c][1] = {};

GHI_RC_Menu[c][1][1] = {};
GHI_RC_Menu[c][1][2] = {};
GHI_RC_Menu[c][1][3] = {};
GHI_RC_Menu[c][1][4] = {};

obj = {};
obj.type = "Editbox";
obj.text = GHI_TEXT;
obj.align = "l";
obj.label = "text";
obj.width = 210;
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "CustomDD";
obj.text = GHI_OUTPUT_TYPE;
obj.align = "r";
obj.label = "type";
obj.returnIndex = true;
obj.data = {GHI_EMOTE,GHI_SAY,GHI_GREEN_TEXT,GHI_BLUE_TEXT};
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "CustomDD";
obj.text = GHI_TIME_FORMAT;
obj.align = "l";
obj.label = "format";
obj.returnIndex = true;
obj.data = {};
obj.data[1] = "00.00";
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_DELAY;
obj.align = "r";
obj.label = "delay";
obj.width = 30;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "Dummy";
obj.height = 10;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][3],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_TIME_TEXT;
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][4],obj);


end
if 1==1 then --	Produce item		ok	localized	
local c = "produce_item"
table.insert(GHI_DynRCList,c);
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_PRODUCE_ITEM;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 440;
GHI_RC_Menu[c].dynamic_rc = true;

GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local id = main.id --GetLabel("choose_item_id");
	local loot_text_i = main.GetLabel("loot_text");

	local amount = main.GetLabel("amount");
	local delay = main.GetLabel("delay");
	--local delay = main.GetLabel("delay");
	--local Format_index = main.GetLabel("format");
	local menu = main.madeBy.main; 
	if menu and id then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			local t = {};
			local name = GHI_GetItemInfo(id);
			if not(name) then name = "unknown"; end
			
			if not(amount) or not(tonumber(amount)) then
				amount = 1;
			end
			
			t["Type"] = "produce_item";
			t["type_name"] = GHI_PRODUCE_ITEM;
			t["details"] = amount.." "..GHI_OF.." "..name;
			t["delay"] = delay;
			
			t["Recieve_v2"] = "GHP_Test_RecieveItem_v2 = function(ID,amount) local bag,space = GHI_GetFreeSpace(); local t = GHI_FindItem(ID,true); local _,_,_,_,_,_,stackSize = GHI_GetItemInfo(ID); if not(ID) or not(stackSize) or not(amount) then return; end; local s = 0; if type(t) == \"table\" then for i=1,table.getn(t) do local info = GHI_GetContainerInfo(t[i].bag,t[i].slot); if info.amount then if info.amount + amount <= stackSize then bag=t[i].bag; space=t[i].slot; s = info.amount; break; end end end end  local duration,Type,start_event=GetDurationInfo(ID);  while amount > 0 do if bag and space then if  duration and duration > 0 and start_event == \"created\" then if Type == \"played_time\" then SetContainerDurationInfo(bag,space,(GetTime()-GHI_StartedPlayedTime)  +duration,nil); elseif Type == \"real_time\" then SetContainerDurationInfo(bag,space,GetTime()+duration,nil); end end end if amount <= stackSize then if bag and space then GHI_ContainerData[bag][space] = {}; GHI_ContainerData[bag][space].ID = ID; GHI_ContainerData[bag][space].amount = amount+s; amount = 0; else  amount = 0; end else if bag and space then GHI_ContainerData[bag][space] = {}; GHI_ContainerData[bag][space].ID = ID; GHI_ContainerData[bag][space].amount = stackSize; amount = amount - stackSize; else  amount = 0; end bag,space = GHI_GetFreeSpace(); end   end  GHI_UpdateContainers(); end";
			
			t["id"] = id;
			t["item_data"] = GHI_ItemData[id];
			t["amount"] = amount;
			
			if loot_text_i == 0 then loot_text_i = 1; end;
			local loot_texts = {"Loot","Create","Craft","Recieve","Produce"};
			t["loot_text"]=loot_texts[loot_text_i];
			t["loot_text_i"]=loot_text_i;
			
			local recieve_text = {};
			--"Loot","Created","Crafted","Recieved","Produced"
			recieve_text["Loot"]=GHI_GET_LOOT;
			recieve_text["Create"]=GHI_GET_CREATE;
			recieve_text["Craft"]=GHI_GET_CRAFT;
			recieve_text["Produce"]=GHI_GET_PRODUCE;
			recieve_text["Recieve"]=GHI_GET_RECIEVE;
			
			--local s = ""..GHP_Test_RecieveItem_v2;
			
			-- item ID identification code.
			local c1 = "local ID = \"ITEM_ID\"; if not(ID) then GHI_Message(\"Could not identify source ID\"); return; end;"
			-- touble identification
			local c2 = "local info = GHI_GetRightClickInfo(ID); local t={}; if type(info) == \"table\" then for i=1,table.getn(info) do if info[i].id == \""..id.."\"  and info[i].dynamic_rc_type == \"produce_item\" then t=info[i]; end end end";
			-- transfer item data
			local c3 = "local v1,v2 = GHI_GetVersions(ID); if type(t[\"item_data\"]) == \"table\" then local own1; local own2 = 0; own1 = (t[\"item_data\"].version or 0); if type(t[\"item_data\"].rc) == \"table\" and not(t[\"item_data\"].rc.version == nil) then own2 = t[\"item_data\"].rc.version; end if own1 < v1 or own2 < v2 then GHI_ItemData[\""..id.."\"] = t[\"item_data\"]; end end";
			-- init GHP receive item function
			local c4 = "GHI_DoScript(t[\"Recieve_v2\"]);";
			-- recieve item
			local c5 = "GHP_Test_RecieveItem_v2(\""..id.."\","..amount..");";
			-- show recieve text
			local c6;
			if amount > 1 then
				c6 = "GHI_Message(\""..recieve_text[t["loot_text"]].." \"..(GHI_GenerateLink(\""..id.."\") or \"unknown\")..\"x"..amount..".\");";
			else
				c6 = "GHI_Message(\""..recieve_text[t["loot_text"]].." \"..(GHI_GenerateLink(\""..id.."\") or \"unknown\")..\".\");";
			end
			
			local code = c1.." "..c2.." "..c3.." "..c4.." "..c5.." "..c6;
			
			-- insert delay
			if type(delay) == "number" and delay > 0 then
				--code = "GHI_Message(\""..code.."\");"
			end 
			
			
			t["icon"] = GHI_RCIcons[t["Type"]];
			t["dynamic_rc"] = true;
			t["dynamic_rc_type"] = t["Type"];
			
			t["code"] = {};
			while not(code == nil) and not(code == "") do
				table.insert(t["code"],string.sub(code,0,127));
				code = string.sub(code,128);
			end
			
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				t["req"] = 1;
				list.InsertTuble(t);
			end

		end
	end
end;
GHI_RC_Menu[c].OnShow = function()
	
	
	local new_table = {};

	
	local main = this;
	--local DD = main.GetLabelFrame("format");
	--DD.dataTable = new_table;
	
	local menu = main.madeBy.main; 
	--local list = menu.GetLabelFrame("RCList");
	
	if main.edit then
		local t = this.tuble;
		
		--[[local Format = t["format"];
		for i=1,table.getn(formats) do
			if formats[i] == Format then
				main.ForceLabel("format",i);
			end
		end--]]
		
		main.ForceLabel("amount",t["amount"]);
		main.ForceLabel("delay",t["delay"]);
		main.ForceLabel("loot_text",t["loot_text_i"]);
		
		--main.ForceLabel("choose_item_id",t["id"]);
		
		--  insert item info in text.
		local itf = main.GetLabelFrame("choose_item");
		
		itf.cursorFeedback(t["id"]);
		
		--main.ForceLabel("text",t["text"]);
		--main.ForceLabel("delay",t["delay"]);
	else	
		main.ForceLabel("ItemInfo","No item selected");
		
	end
end;

GHI_RC_Menu[c][1] = {};

GHI_RC_Menu[c][1][1] = {};
GHI_RC_Menu[c][1][2] = {};
GHI_RC_Menu[c][1][3] = {};
GHI_RC_Menu[c][1][4] = {};
GHI_RC_Menu[c][1][5] = {};


obj = {};
obj.type = "Editbox";
obj.text = GHI_AMOUNT;
obj.align = "r";
obj.label = "amount";
obj.width = 45;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "Button";
obj.text = GHI_CHOOSE_ITEM;
obj.align = "l";
obj.label = "choose_item";
obj.compact = true;
obj.OnLoad = function()
	local th = this;
	local f = this.main;
	
	th.cursorFeedback = function(id)
		
		GHI_ResetCursor();
		local f = th.main;
		local s = "";
		local name,icon,quality,white1,white2,comment,stackSize,creater,version,rightClick,rightClicktext = GHI_GetItemInfo(id);
		if not(creater == UnitName("player")) then
			GHI_Message((name or "unknown")..GHI_NOT_BY_YOU);
			return;
		end
		--s = (GHI_GenerateLink(id) or "unknown");
		local color = ITEM_QUALITY_COLORS[quality];
		if name and not(name == "") then s = s.."\n".."|CFF"..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255)..name.."|r"; end
		if white1 and not(white1 == "") then s = s.."\n".."|CFFFFFFFF"..white1.."|r"; end
		if white2 and not(white2 == "") then s = s.."\n".."|CFFFFFFFF"..white2.."|r"; end
		if comment and not(comment == "") then s = s.."\n\""..comment.."\""; end
		local color = ITEM_QUALITY_COLORS[2];
		if rightClicktext and not(rightClicktext == "") then s = s.."\n".."|CFF"..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255).."Use: "..rightClicktext.."|r"; end
		if creater and not(creater == "") then s = s.."\n".."|CFF"..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255).."<Made by: "..creater..">|r"; end
		
		f.ForceLabel("ItemInfo",s);
		f.id = id; --f.ForceLabel("choose_item_id",id);
	end;
end
obj.onclick = function() 
	
	GHI_SetCursor("choose_item",this);
	
end
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "CustomDD";
obj.text = GHI_MESSAGE_TEXT;
obj.align = "l";
obj.label = "loot_text";
obj.returnIndex = true;
obj.data = {GHI_LOOT,GHI_CREATE,GHI_CRAFT,GHI_RECIEVE,GHI_PRODUCE}
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_DELAY;
obj.align = "r";
obj.label = "delay";
obj.width = 50;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][2],obj);


obj = {};
obj.type = "Dummy";
obj.height = 80;
obj.width = 1;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][3],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.label = "ItemInfo";
obj.text = "";
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][3],obj);

obj = {};
obj.type = "Dummy";
obj.height = 10;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][4],obj);

obj = {};
obj.type = "Dummy";
obj.height = 45;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][5],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_PRODUCE_TEXT;
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][5],obj);


end
if 1==1 then --	Consume item		ok		
local c = "consume_item";
table.insert(GHI_DynRCList,c);
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_CONSUME;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 440;
GHI_RC_Menu[c].dynamic_rc = true;

GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local id = main.id; --GetLabel("choose_item_id");
	local amount = main.GetLabel("amount");
	--local delay = main.GetLabel("delay");
	--local Format_index = main.GetLabel("format");
	local menu = main.madeBy.main; 
	if menu and id then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			local t = {};
			local name = GHI_GetItemInfo(id);
			if not(name) then name = "unknown"; end
			
			if not(amount) or not(tonumber(amount)) then
				amount = 1;
			end
			
			t["Type"] = "consume_item";
			t["type_name"] = GHI_CONSUME;
			t["details"] = amount.." "..GHI_OF.." "..name;
			--t["req"] = 1;
			
			local Consume_v1 = "GHP_Test_ConsumeItem_v1 = function(ID,amount)  local bag,space = GHI_GetFreeSpace();  local t = GHI_FindItem(ID,true);  local _,_,_,_,_,_,stackSize = GHI_GetItemInfo(ID);  if not(ID) or not(stackSize) or not(amount) then return; end;   while amount > 0  and GHI_CountItem(ID) > 0 do local smallest_amount,bag,slot; if type(t) == \"table\" then  for i=1,table.getn(t) do  local info = GHI_GetContainerInfo(t[i].bag,t[i].slot);  if info and info.amount then if not(smallest_amount) or (info.amount < smallest_amount) then   smallest_amount = info.amount; bag = t[i].bag; slot = t[i].slot; end  end  end   if bag and slot then if GHI_ContainerData[bag][slot].amount then GHI_ClearCountItemCatche(); if GHI_ContainerData[bag][slot].amount > amount then GHI_ContainerData[bag][slot].amount = GHI_ContainerData[bag][slot].amount - amount; amount = 0; else amount = amount - GHI_ContainerData[bag][slot].amount; GHI_ContainerData[bag][slot] = nil; end end end end end GHI_UpdateContainers();end ";
			
			t["id"] = id;
			t["amount"] = amount;
			
			
			
			
			--local s = ""..GHP_Test_RecieveItem_v2;
			
			-- item ID identification code.
			local c1 = "local ID; local n = this:GetName(); if strsub(n,0,12) == \"GHIContainer\" then local bag = this:GetParent():GetID(); local slot = this:GetID();  local info = GHI_GetContainerInfo(bag,slot); ID = info.ID; elseif strsub(n,0,11) == \"GHIMultiBar\" then ID = this.itemID; else GHI_Message(GHI_NOT_SOURCE_ID); return; end;"
			-- touble identification
			local c2 = "local info = GHI_GetRightClickInfo(ID); local t={}; if type(info) == \"table\" then for i=1,table.getn(info) do if info[i].id == \""..id.."\"  and info[i].dynamic_rc_type == \"produce_item\" then t=info[i]; end end end";
			-- transfer item data
			--local c3 = "local v1,v2 = GHI_GetVersions(ID); if type(t[\"item_data\"]) == \"table\" then local own1; local own2 = 0; own1 = (t[\"item_data\"].version or 0); if type(t[\"item_data\"].rc) == \"table\" and not(t[\"item_data\"].rc.version == nil) then own2 = t[\"item_data\"].rc.version; end if own1 < v1 or own2 < v2 then GHI_ItemData[\""..id.."\"] = t[\"item_data\"]; end end";
			-- init GHP receive item function
			local c4 = Consume_v1;
			-- recieve item
			local c5 = "GHP_Test_ConsumeItem_v1(\""..id.."\","..amount..");";
			-- show recieve text
			--local c6 = "GHI_Message(\""..recieve_text[loot_text].."\"..(GHI_GenerateLink(\""..id.."\") or \"unknown\")..\"x"..amount..".\");";
			
			local code = c1.." "..c2.." "..c4.." "..c5;
			
			
			
			t["icon"] = GHI_RCIcons[t["Type"]];
			t["dynamic_rc"] = true;
			t["dynamic_rc_type"] = t["Type"];
			
			t["code"] = {};
			while not(code == nil) and not(code == "") do
				table.insert(t["code"],string.sub(code,0,127));
				code = string.sub(code,128);
			end
			
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				t["req"] = 1;
				list.InsertTuble(t);
			end

		end
	end
end;
GHI_RC_Menu[c].OnShow = function()
	
	
	local new_table = {};

	
	local main = this;
	--local DD = main.GetLabelFrame("format");
	--DD.dataTable = new_table;
	
	local menu = main.madeBy.main; 
	--local list = menu.GetLabelFrame("RCList");
	
	if main.edit then
		local t = this.tuble;
		
		--[[local Format = t["format"];
		for i=1,table.getn(formats) do
			if formats[i] == Format then
				main.ForceLabel("format",i);
			end
		end--]]
		
		main.ForceLabel("amount",t["amount"]);
				
		--main.ForceLabel("choose_item_id",t["id"]);
		main.id = t["id"];
		
		--  insert item info in text.
		local itf = main.GetLabelFrame("choose_item");
		
		itf.cursorFeedback(t["id"]);
		
		--main.ForceLabel("text",t["text"]);
		--main.ForceLabel("delay",t["delay"]);
	else	
		main.ForceLabel("ItemInfo",GHI_NO_ITEM_SELECTED);
		
	end
end;

GHI_RC_Menu[c][1] = {};

GHI_RC_Menu[c][1][1] = {};
GHI_RC_Menu[c][1][2] = {};
GHI_RC_Menu[c][1][3] = {};
GHI_RC_Menu[c][1][4] = {};
GHI_RC_Menu[c][1][5] = {};


obj = {};
obj.type = "Editbox";
obj.text = GHI_AMOUNT;
obj.align = "r";
obj.label = "amount";
obj.width = 45;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "Button";
obj.text = GHI_CHOOSE_ITEM;
obj.align = "l";
obj.label = "choose_item";
obj.compact = true;
obj.OnLoad = function()
	local th = this;
	local f = this.main;
	
	th.cursorFeedback = function(id)
		
		GHI_ResetCursor();
		local f = th.main;
		local s = "";
		local name,icon,quality,white1,white2,comment,stackSize,creater,version,rightClick,rightClicktext = GHI_GetItemInfo(id);
		
		--s = (GHI_GenerateLink(id) or "unknown");
		local color = ITEM_QUALITY_COLORS[quality];
		if name and not(name == "") then s = s.."\n".."|CFF"..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255)..name.."|r"; end
		if white1 and not(white1 == "") then s = s.."\n".."|CFFFFFFFF"..white1.."|r"; end
		if white2 and not(white2 == "") then s = s.."\n".."|CFFFFFFFF"..white2.."|r"; end
		if comment and not(comment == "") then s = s.."\n\""..comment.."\""; end
		local color = ITEM_QUALITY_COLORS[2];
		if rightClicktext and not(rightClicktext == "") then s = s.."\n".."|CFF"..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255)..GHI_USE.." "..rightClicktext.."|r"; end
		if creater and not(creater == "") then s = s.."\n".."|CFF"..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255).."<"..GHI_MADE_BY.." "..creater..">|r"; end
		
		f.ForceLabel("ItemInfo",s);
		f.id = id; --ForceLabel("choose_item_id",id);
	end;
end
obj.onclick = function() 
	
	GHI_SetCursor("choose_item",this);
	
end
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "Dummy";
obj.height = 80;
obj.width = 1;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.label = "ItemInfo";
obj.text = "Item info";
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "Dummy";
obj.height = 10;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][3],obj);

obj = {};
obj.type = "Dummy";
obj.height = 45;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][4],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_CONSUME_TEXT;
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][4],obj);


end
if 1==1 then --	message			ok		
local c = "message"
table.insert(GHI_DynRCList,c);
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_MESSAGE_TEXT_U;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 340;
GHI_RC_Menu[c].dynamic_rc = true;
GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local text = main.GetLabel("text");
	local Type = main.GetLabel("type");
	local delay = main.GetLabel("delay");
	local color_index = main.GetLabel("color");
	local menu = main.madeBy.main; 
	if menu then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			local t = {};
			t["Type"] = "message";
			t["type_name"] = GHI_MESSAGE_TEXT_U;
			t["dynamic_rc"] = true;
			t["icon"] = GHI_RCIcons["message"];
			t["dynamic_rc_type"] = "message";
			
			
			
			local color = GHI_ColorList[color_index];
			
			
			local info = GHI_EffectColors[color];
			t["details"] = GHI_ColorString(text,info.r,info.g,info.b);
			--t["req"] = 1;
			
			
			t["text"] = text;
			t["output_type"] = Type;
			t["delay"] = delay;
			t["color"] = color;
			
			
			
			
			
			
			if Type == 1 then
				code = "DEFAULT_CHAT_FRAME:AddMessage(\""..text.."\","..info.r..","..info.g..","..info.b..");";
			elseif Type == 2 then
				code = "UIErrorsFrame:AddMessage(\""..text.."\","..info.r..","..info.g..","..info.b..",53,5);";
			else
				code = "";
			end
			
			
			t["code"] = {};
			while not(code == nil) and not(code == "") do
				table.insert(t["code"],string.sub(code,0,127));
				code = string.sub(code,128);
			end
			
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				t["req"] = 1;
				list.InsertTuble(t);
			end

		end
	end
end;
GHI_RC_Menu[c].OnShow = function()
	
	
	local new_table = {};
	local colors = GHI_ColorList;
	for i=1,table.getn(colors) do
		local info = GHI_EffectColors[colors[i]];
		
		new_table[i] = GHI_ColorString(GHI_COLOR_NAMES[colors[i]],info.r,info.g,info.b);
	end  
	
	local main = this;
	local DD = main.GetLabelFrame("color");
	DD.dataTable = new_table;
	
	local menu = main.madeBy.main; 
	--local list = menu.GetLabelFrame("RCList");
	
	if main.edit then
		local t = this.tuble;
		
		local color = t["color"];
		for i=1,table.getn(colors) do
			if colors[i] == color then
				main.ForceLabel("color",i);
			end
		end
		
		main.ForceLabel("type",t["output_type"]);
		main.ForceLabel("text",t["text"]);
		main.ForceLabel("delay",t["delay"]);
	else	
		main.ForceLabel("type",1);
		main.ForceLabel("color",1);
		
	end
end;

GHI_RC_Menu[c][1] = {};

GHI_RC_Menu[c][1][1] = {};
GHI_RC_Menu[c][1][2] = {};
GHI_RC_Menu[c][1][3] = {};
GHI_RC_Menu[c][1][4] = {};

obj = {};
obj.type = "Editbox";
obj.text = GHI_TEXT;
obj.align = "l";
obj.label = "text";
obj.width = 210;
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "CustomDD";
obj.text = GHI_OUTPUT_TYPE;
obj.align = "r";
obj.label = "type";
obj.returnIndex = true;
obj.data = {GHI_CHAT_FRAME,GHI_ERROR_MSG};
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "CustomDD";
obj.text = GHI_COLOR;
obj.align = "l";
obj.label = "color";
obj.returnIndex = true;
obj.data = {};
obj.data = {"Blue"};
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_DELAY;
obj.align = "r";
obj.label = "delay";
obj.width = 30;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "Dummy";
obj.height = 10;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][3],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_MSG_TEXT;
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][4],obj);


end
if 1==1 then --	remove buff		ok
local c = "remove_buff"
table.insert(GHI_DynRCList,c);
GHI_RC_Menu[c] = {};
GHI_RC_Menu[c].title = GHI_REMOVE_BUFF;
GHI_RC_Menu[c].name = "GHI_NewRC_"..c;
GHI_RC_Menu[c].theme = "SpellBookTheme";
GHI_RC_Menu[c].icon = GHI_RCIcons[c];
GHI_RC_Menu[c].height = 340;
GHI_RC_Menu[c].dynamic_rc = true;
GHI_RC_Menu[c].OnOk = function()
	local main = this:GetParent();
	local name = main.GetLabel("name");
	local filter = main.GetLabel("filter");
	local amount = main.GetLabel("amount");
	local delay = main.GetLabel("delay");
	local menu = main.madeBy.main; 
	if menu then 
		local list = menu.GetLabelFrame("RCList");
		if list then 
			local t = {};
			t["Type"] = "remove_buff";
			t["type_name"] = GHI_REMOVE_BUFF;
			t["dynamic_rc"] = true;
			t["icon"] = GHI_RCIcons["remove_buff"];
			t["dynamic_rc_type"] = "remove_buff";
			
			
			t["name"] = name;
			t["filter"] = filter;
			t["delay"] = delay;
			t["amount"] = amount;
			
			t["details"] = name..": "..(amount or 0)
			
			local fs = {"HELPFUL","HARMFUL"}; 
			
			--code = "if not(GHI_RemoveGHIBuff_v2) then GHI_RemoveGHIBuff_v2  = function(name,filter,amount) local list,changed; if filter==\"HELPFUL\" then list = GHI_BuffList; elseif filter==\"HARMFUL\" then	list = GHI_DebuffList; end if type(list)==\"table\" then for i = 1,table.getn(list) do if type(list[i])==\"table\" then if list[i].name == name then if (list[i].amount or 0) <= amount then amount = amount - list[i].amount; list[i] = nil; else list[i].amount = list[i].amount - amount; amount = 0; break; end changed = true; end end end if changed == true then list.lastUpdated = time(); if filter==\"HELPFUL\" then GHI_BuffList = list; elseif filter==\"HARMFUL\" then GHI_DebuffList = list; end GHI_RerunBuffUpdate = true; GHI_UpdateAllBuffs(); end end end end"
			--code = code.." ".."GHI_RemoveGHIBuff_v2(\""..(name or "").."\",\""..(fs[filter] or "nil").."\","..(amount or 0)..")";
			
			code = "GHI_DoScript(\"RemoveGHIBuff("..name..","..amount..")\","..(delay or 0)..");"
			
			t["code"] = {};
			while not(code == nil) and not(code == "") do
				table.insert(t["code"],string.sub(code,0,127));
				code = string.sub(code,128);
			end
			
			if type(main.edit) == "number" then
				local t1 = list.GetTuble(main.edit);
				if type(t1)=="table" then
					if t1["req"] then
						t["req"] = t1["req"] 
					end
					if t1["marked"] then
						t["marked"] = t1["marked"];
					end
				end
				list.SetTuble(main.edit,t);
			else
				t["req"] = 1;
				list.InsertTuble(t);
			end

		end
	end
end;
GHI_RC_Menu[c].OnShow = function()
	
	
	
	local main = this;
	
	
	local menu = main.madeBy.main; 
	--local list = menu.GetLabelFrame("RCList");
	
	if main.edit then
		local t = this.tuble;
		
		main.ForceLabel("name",t["name"]);
		main.ForceLabel("amount",t["amount"]);
		main.ForceLabel("filter",t["filter"]);
		main.ForceLabel("delay",t["delay"]);
	else	
		main.ForceLabel("filter",1);
		
		
	end
end;

GHI_RC_Menu[c][1] = {};

GHI_RC_Menu[c][1][1] = {};
GHI_RC_Menu[c][1][2] = {};
GHI_RC_Menu[c][1][3] = {};
GHI_RC_Menu[c][1][4] = {};

obj = {};
obj.type = "Editbox";
obj.text = GHI_BUFF_NAME;
obj.align = "l";
obj.label = "name";
obj.width = 210;
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "CustomDD";
obj.text = GHI_BUFF_DEBUFF;
obj.align = "r";
obj.label = "filter";
obj.returnIndex = true;
obj.width = 110;
obj.data = {};
obj.data[1] = GHI_HELPFUL;
obj.data[2] = GHI_HARMFUL;
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_DELAY;
obj.align = "r";
obj.label = "delay";
obj.width = 30;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][1],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_AMOUNT;
obj.align = "l";
obj.label = "amount";
obj.width = 30;
obj.numbersOnly = true;
table.insert(GHI_RC_Menu[c][1][2],obj);

obj = {};
obj.type = "Dummy";
obj.height = 10;
obj.width = 10;
obj.align = "c";
table.insert(GHI_RC_Menu[c][1][3],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_REMOVE_BUFF_TEXT;
obj.align = "l";
table.insert(GHI_RC_Menu[c][1][4],obj);


end



if 1==1 then --	Create Item		Localized

GHI_CreateItem_Menu = {}


GHI_CreateItem_Menu = {};
GHI_CreateItem_Menu.name = "GHI_NewItem";
GHI_CreateItem_Menu.title = GHI_CREATE_TITLE;
GHI_CreateItem_Menu.theme = "WizardTheme";
GHI_CreateItem_Menu.height = 512;
GHI_CreateItem_Menu.autohide = false;
GHI_CreateItem_Menu.OnOk = function() 
	local main = this:GetParent();
	local item = {};
	
	--	page 1 values
	local name = main.GetLabel("name");
	local quality = main.GetLabel("quality");
	local icon = main.GetLabel("icon");
	local white1 = main.GetLabel("white1");
	local white2 = main.GetLabel("white2");
	local comment = main.GetLabel("quote");
	local amount = main.GetLabel("amount");
	local stackSize = main.GetLabel("stackSize");
	local copyable = main.GetLabel("copyable");
	local duration = main.GetLabel("duration");
	local durationWhenTrade = main.GetLabel("durationWhenTrade");
	local durationRealTime = main.GetLabel("durationRealTime");
	local editable = main.GetLabel("editable");
	
	--	page 2 values
	local rightClick = main.GetLabel("RCList");
	local rightClicktext = main.GetLabel("use");
	local CD = main.GetLabel("CD");
	local consumed = main.GetLabel("consumed");
	
	
	if consumed == 0 then consumed = nil; end;
	
	--	control of input
	if not(name) or name == "" then
		GHI_Message("Please enter a item name.");
		return;
	end
	
	
	
	--	converting of RC data
	if type(rightClick) == "table" and table.getn(rightClick) > 0 then
		rightClick.CD = CD;
		rightClick.consumed = consumed; --GHI_Message("Edited to consumed: "..(consumed or btype(consumed)));
		rightClick.Type = "multible"
		rightClick.requireTarget = {};
		
		rightClick.bag_index = nil;
		
		--	inserting index for unique type actions
		for i = 1,table.getn(rightClick) do
			if type(rightClick[i]) == "table" then
				if strlower(rightClick[i].Type) == "bag" then 
					rightClick.bag_index = i;
				elseif strlower(rightClick[i].Type) == "book" then
					rightClick.book_index = i;
				elseif strlower(rightClick[i].Type) == "buff" then
					rightClick.requireTarget[rightClick[i].req] = true;
					
				end
			end
		end
		
		-- handle dynamic rc functions and addon requirements
		for i = 1,table.getn(rightClick) do
			if type(rightClick[i]) == "table" then
				if rightClick[i].dynamic_rc == true then
					rightClick[i].Type = "script";
				end
				if rightClick[i].AddonReqName then
					rightClick.AddonReqName = rightClick[i].AddonReqName;
					rightClick.AddonReqData = rightClick[i].AddonReqData;
					
				end
			end
		end
	else
		rightClick = nil;
		rightClicktext = nil;
	end
	
	
	local editID = main.edit;
	local changeStack = main.edit;
	
	GHI_CreateItem(name,icon,quality,white1,white2,comment,amount,stackSize,copyable,rightClick,rightClicktext,editID,duration,durationWhenTrade,durationRealTime,editable,changeStack)
	
	main:Hide();
end

GHI_CreateItem_Menu[1] = {};
GHI_CreateItem_Menu[1].name = "Generel";
for i = 1,10 do 
GHI_CreateItem_Menu[1][i] = {};
end


GHI_CreateItem_Menu[2] = {};
GHI_CreateItem_Menu[2].name = "Right Click";
for i = 1,10 do 
GHI_CreateItem_Menu[2][i] = {};
end

if 2==2 then --	Page 1

obj = {};
obj.type = "Text";
obj.fontSize = 16;
obj.text = GHI_GENERAL_ITEM_INFO;
obj.align = "c";
table.insert(GHI_CreateItem_Menu[1][1],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_NAME;
obj.align = "c";
obj.label = "name";
table.insert(GHI_CreateItem_Menu[1][2],obj);

obj = {};
obj.type = "QualityDD";
obj.text = GHI_QUALITY;
obj.align = "c";
obj.label = "quality";
table.insert(GHI_CreateItem_Menu[1][3],obj);

obj = {};
obj.type = "Icon";
obj.text = GHI_ICON;
obj.align = "r";
obj.label = "icon";
obj.framealign = "r";
obj.CloseOnChoosen = true;
table.insert(GHI_CreateItem_Menu[1][3],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_WHITE_TEXT_1;
obj.align = "c";
obj.label = "white1";
table.insert(GHI_CreateItem_Menu[1][4],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_WHITE_TEXT_2;
obj.align = "c";
obj.label = "white2";
table.insert(GHI_CreateItem_Menu[1][5],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_YELLOW_QUOTE;
obj.align = "c";
obj.label = "quote";
table.insert(GHI_CreateItem_Menu[1][6],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_AMOUNT;
obj.align = "r";
obj.label = "amount";
obj.width = 50;
obj.numbersOnly = true;
table.insert(GHI_CreateItem_Menu[1][7],obj);

obj = {};
obj.type = "StackSlider";
obj.text = GHI_STACK_SIZE;
obj.align = "c";
obj.label = "stackSize";
table.insert(GHI_CreateItem_Menu[1][7],obj);

obj = {};
obj.type = "CheckBox";
obj.text = GHI_COPYABLE;
obj.align = "l";
obj.label = "copyable";
table.insert(GHI_CreateItem_Menu[1][7],obj);

obj = {};
obj.type = "CheckBox";
obj.text = GHI_EDITABLE;
obj.align = "l";
obj.label = "editable";
table.insert(GHI_CreateItem_Menu[1][8],obj);

obj = {};
obj.type = "TimeSlider";
obj.text = GHI_ITEM_DURATION;
obj.align = "c";
obj.label = "duration";
obj.values = {0,1,5,10,15,30,60,90,120,60*5,60*10,60*15,60*30,60*60,60*90,60*60*2,60*60*5,60*60*10,60*60*20,60*60*24,60*60*24*2,60*60*24*7,60*60*24*14,60*60*24*30,60*60*24*30*2,60*60*24*30*3,60*60*24*30*6,60*60*24*365}
table.insert(GHI_CreateItem_Menu[1][8],obj);

obj = {};
obj.type = "CheckBox";
obj.text = GHI_DURATION_WHEN_TRADED;
obj.align = "l";
obj.label = "durationWhenTrade";
table.insert(GHI_CreateItem_Menu[1][9],obj);

obj = {};
obj.type = "CheckBox";
obj.text = GHI_USE_REAL_TIME;
obj.align = "c";
obj.label = "durationRealTime";
table.insert(GHI_CreateItem_Menu[1][9],obj);

end
if 2==2 then --	Page 2

obj = {};
obj.type = "Text";
obj.fontSize = 16;
obj.text = GHI_RIGHT_CLICK;
obj.align = "c";
table.insert(GHI_CreateItem_Menu[2][1],obj);

obj = {};
obj.type = "Dummy";
obj.width = 10;
obj.height = 20;
obj.alignt = "c";
table.insert(GHI_CreateItem_Menu[2][2],obj);

local obj2 = {};
obj = {};
obj.type = "List";
obj.lines = 7;
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
obj2[2].catagory = GHI_TYPE_U;
obj2[2].width = 120;
obj2[2].label = "type_name";
obj2[3] = {}
obj2[3].type = "Text";
obj2[3].catagory = GHI_DETAILS;
obj2[3].width = 200;
obj2[3].label = "details";
obj2[4] = {}
obj2[4].type = "CycleButton";
obj2[4].cycles = {GHI_RUN_ALWAYS,GHI_IS_FORFILLED,GHI_IS_NOT_FORFILLED,GHI_BEFORE_REQ};
obj2[4].catagory = GHI_RUN_REQ;
obj2[4].width = 100;
obj2[4].label = "req";
obj.column = obj2;
table.insert(GHI_CreateItem_Menu[2][3],obj);

obj = {};
obj.type = "CustomDD";
obj.text = GHI_NEW_RIGHT_CLICK;
obj.align = "l";
obj.label = "rc_type";
obj.returnIndex = true;
obj.data = {};
GHI_RCCatList = {};
for index,value in pairs(GHI_RC_Menu) do
	if type(value) == "table" and not(value.dynamic_rc) then
		table.insert(obj.data,value.title);
		table.insert(GHI_RCCatList,index);
	end
end
for index,value in pairs(GHI_DynRCList) do
	local frame = GHI_RC_Menu[value];
	if type(frame) == "table" and (frame.dynamic_rc) then
		table.insert(obj.data,frame.title);
		table.insert(GHI_RCCatList,value);
	end
end
table.insert(GHI_CreateItem_Menu[2][4],obj);

obj = {};
obj.type = "Button";
obj.text = GHI_ADD_NEW;
obj.align = "l";
obj.label = "new_rc_button";
obj.compact = true;
obj.onclick = function() 
	local f = this.main;
	local Type_i = f.GetLabel("rc_type");
	local list = f.GetLabel("RCList");
	local Type = GHI_RCCatList[Type_i];
	
	if (Type == "bag" or Type == "book") and type(list) == "table" then
		for i = 1,table.getn(list) do
			if type(list[i]) == "table" and list[i].type == Type then
				GHI_Message(GHI_ONE_TYPE_WARNING.." "..Type);
				return;
			end
		end
	end
	if Type == "ghr" and (not(GHR_OwnRank) or GHR_OwnRank > 3) then
		GHI_Message(GHI_GHR_WARNING);
		return;
	end

	local g = GHM_NewFrame(GHI_RC_Menu[Type]);
	if g then
		g.edit = nil;
		g.ClearAll();
		g:Show();	
	end
	--[[for index,value in pairs(GHI_RC_Menu) do
		if type(value) == "table" then
			if value.title == Type then
				local g = GHM_NewFrame(value);
				if g then
					g.edit = nil;
					g.ClearAll();
					g:Show();
					
					
				end
				break;
			end
		end
	end	-- ]]
end
table.insert(GHI_CreateItem_Menu[2][4],obj);

obj = {};
obj.type = "Dummy";
obj.height = 10;
obj.width = 15;
obj.align = "r";
table.insert(GHI_CreateItem_Menu[2][4],obj);

obj = {};
obj.type = "Button";
obj.text = GHI_DELETE;
obj.align = "r";
obj.label = "delete_rc_button";
obj.compact = true;
obj.onclick = function() 
	local f = this.main;
	local list = f.GetLabelFrame("RCList");
	local j = list.GetMarked(); 
	if type(j) == "number" then	
		list.DeleteTuble(j);
	end
end
table.insert(GHI_CreateItem_Menu[2][4],obj);

obj = {};
obj.type = "Dummy";
obj.height = 10;
obj.width = 10;
obj.align = "r";
table.insert(GHI_CreateItem_Menu[2][4],obj);

obj = {};
obj.type = "Button";
obj.text = GHI_EDIT;
obj.align = "r";
obj.label = "edit_rc_button";
obj.compact = true;
obj.onclick = function() 
	local f = this.main;
	local list = f.GetLabelFrame("RCList");
	local j = list.GetMarked(); 
	if type(j) == "number" then	
		local d = list.GetTuble(j);
		if d.Type then	
			local Type = d.Type;

			local g = GHM_NewFrame(GHI_RC_Menu[Type]);
			if g then					
				g.tuble = d;
				g.edit = j;
				g.ClearAll();
				g:Show();
				
				-- Static setup
				if Type == "script" then
					local code = "";
					for i = 1,table.getn(d["code"]) do
						code = code..d["code"][i];
					end
					
					g.ForceLabel("code",code);
					g.ForceLabel("delay",d["delay"]);
				elseif Type == "expression" then
					g.ForceLabel("text",d["text"]);
					--g.ForceLabel("type",d["expression_type"]);
					g.ForceLabel("type",d["expression_type_i"]);
					g.ForceLabel("delay",d["delay"]);
				elseif Type == "random_expression" then
					if type(d["text"]) == "table" then
						for i = 1,6 do
							g.ForceLabel("text"..i,d["text"][i]);
						end
					end
					if type(d["expression_type_i"]) == "table" then
						for i = 1,6 do
							g.ForceLabel("type"..i,d["expression_type_i"][i]);
						end
					end
					g.ForceLabel("allow_same",d["allow_same"]); 
				elseif Type == "book" then
					g.ForceLabel("title",d["title"]);
					g.ForceLabel("pages",d["pages"]);
					if d["pages"] then
						for i = 1,d["pages"] do
							g.ForceLabel(i,d[i]);
						end
					end
					g.ForceLabel("h1",d["h1"]);
					g.ForceLabel("h2",d["h2"]);
					g.ForceLabel("font",d["font"]);
					g.ForceLabel("material",d["material"]);
					g.ForceLabel("pages",d["pages"]);
				elseif Type == "buff" then
					g.ForceLabel("buff_name",d["buffName"]);
					g.ForceLabel("buff_details",d["buffDetails"]);
					g.ForceLabel("untill_canceled",d["untillCanceled"]);
					g.ForceLabel("buff_duration",d["buffDuration"]);
					g.ForceLabel("castOnSelf",d["castOnSelf"]);
					g.ForceLabel("filter",d["filter"]);
					g.ForceLabel("buff_type",d["buffType"]);
					g.ForceLabel("buff_icon",d["buffIcon"]);
					g.ForceLabel("stackable",d["stackable"]);
					g.ForceLabel("delay",d["delay"]);
					g.ForceLabel("amount",d["amount"]);
					g.ForceLabel("range",d["range"]);
				elseif Type == "sound" then
					g.ForceLabel("sound_path",d["sound_path"]);
					g.ForceLabel("delay",d["delay"]);
					g.ForceLabel("range",d["range"]);
				elseif Type == "equip_item" then
					g.ForceLabel("item_name",d["item_name"]);
					g.ForceLabel("delay",d["delay"]);
				elseif Type == "bag" then
					g.ForceLabel("slots",d["size"]);
					
					g.ForceLabel("texture",d["texture_i"]);
				elseif Type == "requirement" then
					local t=d["req_detail"];
					if d["req_type"] == "LUA Statement" then -- changes spaces and comma in the code, so it will show up as one part
						t=gsub(t,"\21"," ");
						t=gsub(t,"\22",",");
					end
					g.ForceLabel("type",d["req_type_i"]);
					g.ForceLabel("alias",d["req_alias"]);
					g.ForceLabel("text",t);
				elseif Type == "ghr" then
					g.ForceLabel("amount",d["amount"]);
					if type(GHR_FactionData) == "table" then
						for i=2,table.getn(GHR_FactionData) do
							if GHR_FactionData[i].ID == d["faction"] then
								g.ForceLabel("faction",i-1);
							end
						end
					end
				elseif Type == "time" then
					
				end
			end
		end
	end
end
table.insert(GHI_CreateItem_Menu[2][4],obj);

obj = {};
obj.type = "Dummy";
obj.height = 20;
obj.width = 20;
obj.align = "r";
table.insert(GHI_CreateItem_Menu[2][5],obj);


obj = {};
obj.type = "Dummy";
obj.height = 15;
obj.width = 15;
obj.align = "l";
table.insert(GHI_CreateItem_Menu[2][6],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.width = 450
obj.text = GHI_RIGHT_CLICK_HELP;
obj.align = "l";
table.insert(GHI_CreateItem_Menu[2][6],obj);

obj = {};
obj.type = "Dummy";
obj.height = 20;
obj.width = 20;
obj.align = "r";
table.insert(GHI_CreateItem_Menu[2][7],obj);

obj = {};
obj.type = "Dummy";
obj.height = 15;
obj.width = 15;
obj.align = "l";
table.insert(GHI_CreateItem_Menu[2][8],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_USE;
obj.align = "l";
obj.label = "use";
table.insert(GHI_CreateItem_Menu[2][8],obj);

obj = {};
obj.type = "Dummy";
obj.height = 20;
obj.width = 15;
obj.align = "r";
table.insert(GHI_CreateItem_Menu[2][8],obj);

obj = {};
obj.type = "TimeSlider";
obj.text = GHI_ITEM_CD;
obj.align = "r";
obj.label = "CD";
table.insert(GHI_CreateItem_Menu[2][8],obj);

obj = {};
obj.type = "CheckBox";
obj.text = GHI_CONSUMED;
obj.align = "l";
obj.label = "consumed";
table.insert(GHI_CreateItem_Menu[2][9],obj);

end
end



if 1==1 then --	Help menu		Localized
GHI_Help_Menu = {};
GHI_Help_Menu.title = GHI_HELP_TITLE;
GHI_Help_Menu.name = "GHI_Help_Menu_Frame";
GHI_Help_Menu.theme = "StdTheme";
GHI_Help_Menu.height = 360;
GHI_Help_Menu.width = 350;
GHI_Help_Menu.OnOk = function()
	local main = this:GetParent();
	

	local scale =  main.GetLabel("icon_scale");

	if type(scale) == "number" then
		GHI_MiscData["BackpackScale"] = scale;
		GHI_BPIconMove(GHI_MiscData["BackpackPos"]);
	end
	local disable_buffs = main.GetLabel("disable_buffs");
	if disable_buffs == 1 then
		if not(GHI_MiscData["DisableBuffs"] == true) then
			StaticPopup_Show("GHI_Reload_Disabled_Buffs");
		end
	elseif GHI_MiscData["DisableBuffs"] == true then
		GHI_EnableBuffHookings() 
		GHI_MiscData["DisableBuffs"] = false;
	end
	
	local show_warning = main.GetLabel("show_vehicle_warning");
	
	if show_warning == 1 then
		GHI_MiscData["show_disable_msg"] = true;
	else
		GHI_MiscData["show_disable_msg"] = false;
	end
	
	local show_warning = main.GetLabel("block_std_emote");
	
	if show_warning == 1 then
		GHI_MiscData["block_std_emote"] = true;
	else
		GHI_MiscData["block_std_emote"] = false;
	end
	
	GHI_MiscData["hide_empty_slots"] = main.GetLabel("hide_empty_slots");
	GHI_ShowSlots(false);
	
	GHI_MiscData["block_area_sound"] = main.GetLabel("block_area_sound");
	GHI_MiscData["block_area_buff"] = main.GetLabel("block_area_buff");
end;

GHI_Help_Menu[1] = {};
for i = 1,15 do
GHI_Help_Menu[1][i] = {};
end

obj = {};
obj.type = "Text";
obj.fontSize = 14;
local v = GetAddOnMetadata("GHI","Version")
if v then
obj.text = "Gryphonheart Items v."..v;
else
obj.text = "Gryphonheart Items";
end
obj.align = "c";
table.insert(GHI_Help_Menu[1][1],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_HELP_CREDITS;
obj.align = "c";
table.insert(GHI_Help_Menu[1][2],obj);

obj = {};
obj.type = "Dummy";
obj.height = 12;
obj.width = 10;
obj.align = "c";
table.insert(GHI_Help_Menu[1][3],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.color = "white";
obj.text = GHI_HELP_ADD_INFO;
obj.align = "l";
table.insert(GHI_Help_Menu[1][4],obj);

obj = {};
obj.type = "Dummy";
obj.height = 20;
obj.width =10;
obj.align = "c";
table.insert(GHI_Help_Menu[1][5],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_HELP_BACKPACK_ICON;
obj.align = "l";
table.insert(GHI_Help_Menu[1][6],obj);

obj = {};
obj.type = "CustomSlider";
obj.text = GHI_SCALE;
obj.align = "l";
obj.label = "icon_scale";
obj.values = {0.25,0.5,0.75,1.00,1.25,1.50,1.75,2.00}
table.insert(GHI_Help_Menu[1][7],obj);

obj = {};
obj.type = "Button";
obj.text = GHI_CENTER_ICON;
obj.align = "r";
obj.label = "center_icon";
obj.compact = true;
obj.onclick = function() 
	local f = this.main;
	GHI_MiscData["BackpackPos"] = { UIParent:GetWidth()/2, UIParent:GetHeight()/2}
	GHI_BPIconMove(GHI_MiscData["BackpackPos"]);
	
end
table.insert(GHI_Help_Menu[1][7],obj);

--[[
obj = {};
obj.type = "CheckBox";
obj.text = GHI_DISABLE_BUFFS;
obj.align = "l";
obj.label = "disable_buffs";
table.insert(GHI_Help_Menu[1][8],obj);

obj = {};
obj.type = "CheckBox";
obj.text = GHI_SHOW_WARNING;
obj.align = "l";
obj.label = "show_vehicle_warning";
table.insert(GHI_Help_Menu[1][9],obj); --]]

obj = {};
obj.type = "CheckBox";
obj.text = GHI_BLOCK_STD_EMOTE;
obj.align = "l";
obj.label = "block_std_emote";
table.insert(GHI_Help_Menu[1][8],obj);

obj = {};
obj.type = "Button";
obj.text = GHI_CENTER_BUFFS;
obj.align = "r";
obj.label = "center_buff";
obj.compact = true;
obj.onclick = function() 
	GHU_BuffResetAllPositions();	
end
table.insert(GHI_Help_Menu[1][8],obj);

obj = {};
obj.type = "CheckBox";
obj.text = GHI_HIDE_EMPTY_SLOTS;
obj.align = "l";
obj.label = "hide_empty_slots";
table.insert(GHI_Help_Menu[1][9],obj);

obj = {};
obj.type = "Button";
obj.text = GHI_REMOVE_BUFFS;
obj.align = "r";
obj.label = "center_icon";
obj.compact = true;
obj.onclick = function() 
	RemoveAllGHIBuffs()	
end
table.insert(GHI_Help_Menu[1][9],obj);

obj = {};
obj.type = "CheckBox";
obj.text = GHI_BLOCK_AREA_SOUND;
obj.align = "l";
obj.label = "block_area_sound";
table.insert(GHI_Help_Menu[1][10],obj);

obj = {};
obj.type = "CheckBox";
obj.text = GHI_BLOCK_AREA_BUFFS;
obj.align = "l";
obj.label = "block_area_buff";
table.insert(GHI_Help_Menu[1][11],obj);
end

StaticPopupDialogs["GHI_Reload_Disabled_Buffs"] = {
	text = GHI_DISABLE_BUFF_RELOAD,
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		GHI_DisableBuffHookings() 
	end,
	OnCancel = function ()
		
	end,
	OnUpdate = function ()
	end,
	timeout = 0,
	whileDead = 1,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1
};

if 1==1 then --	Export
GHI_ExportMenu = {};
GHI_ExportMenu.title = GHI_EXPORT;
GHI_ExportMenu.name = "Export Item";
GHI_ExportMenu.hasCloseButton = true;
GHI_ExportMenu.theme = "SpellBookTheme";
GHI_ExportMenu.icon = "Interface\\Icons\\INV_Crate_03";
GHI_ExportMenu.height = 840;
GHI_ExportMenu.OnOk = function()
	
end;
GHI_ExportMenu.OnShow = function()
	local id = this.ID;
	local name,icon,quality,white1,white2,comment,stackSize,creater,version,rightClick,rightClicktext = GHI_GetItemInfo(id);
	local s = "";
	local color = ITEM_QUALITY_COLORS[quality];
	if name and not(name == "") then s = s.."\n".."|CFF"..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255)..name.."|r"; end
	if white1 and not(white1 == "") then s = s.."\n".."|CFFFFFFFF"..white1.."|r"; end
	if white2 and not(white2 == "") then s = s.."\n".."|CFFFFFFFF"..white2.."|r"; end
	if comment and not(comment == "") then s = s.."\n\""..comment.."\""; end
	local color = ITEM_QUALITY_COLORS[2];
	if rightClicktext and not(rightClicktext == "") then s = s.."\n".."|CFF"..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255)..GHI_USE.." "..rightClicktext.."|r"; end
	if creater and not(creater == "") then s = s.."\n".."|CFF"..string.format("%.2x",color.r*255) .. string.format("%.2x",color.g*255) .. string.format("%.2x",color.b*255).."<"..GHI_MADE_BY.." "..creater..">|r"; end
	
	this.ForceLabel("ItemInfo",s);
end
GHI_ExportMenu[1] = {};
for i=1,12 do
GHI_ExportMenu[1][i] = {};
end


obj = {};
obj.type = "Dummy";
obj.height = 0;
obj.width = 1;
obj.align = "c";
table.insert(GHI_ExportMenu[1][2],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.label = "ItemInfo";
obj.text = "Item info";
obj.xOff = 20;
obj.height = 50
obj.align = "l";
table.insert(GHI_ExportMenu[1][2],obj);

obj = {};
obj.type = "Dummy";
obj.height = 35;
obj.width = 10;
obj.align = "c";
table.insert(GHI_ExportMenu[1][3],obj);

obj = {};
obj.type = "Dummy";
obj.height = 10;
obj.width = 40;
obj.align = "l";
table.insert(GHI_ExportMenu[1][4],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_AMOUNT;
obj.align = "l";
obj.label = "amount";
obj.width = 50;
obj.numbersOnly = true;
table.insert(GHI_ExportMenu[1][4],obj);

obj = {};
obj.type = "Dummy";
obj.height = 10;
obj.width = 40;
obj.align = "l";
table.insert(GHI_ExportMenu[1][4],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_TOTAL_PR_CHAR;
obj.align = "l";
obj.yOff = 5;
obj.label = "total";
obj.width = 50;
obj.numbersOnly = true;
table.insert(GHI_ExportMenu[1][4],obj);

obj = {};
obj.type = "CustomDD";
obj.text = GHI_LIMITED_TO;
obj.align = "l";
obj.label = "limitation_type";
obj.returnIndex = true;
obj.data = {GHI_NONE,GHI_CHARS,GHI_GUILDS,GHI_REALMS,GHI_REQ["LUA Statement"]};
table.insert(GHI_ExportMenu[1][5],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_NAMES;
obj.align = "r";
obj.label = "limitation_filter";
obj.width = 110;
obj.numbersOnly = false;
table.insert(GHI_ExportMenu[1][5],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.color = "white";
obj.width = 260;
obj.xOff = 20;
obj.text = GHI_EXPORT_LIMITATION_TEXT;
obj.align = "l";
table.insert(GHI_ExportMenu[1][6],obj);

obj = {};
obj.type = "Dummy";
obj.height = 30;
obj.width = 10;
obj.align = "l";
table.insert(GHI_ExportMenu[1][6],obj);

obj = {}; 
obj.type = "CheckBox";
obj.text = GHI_CHANGE_ID;
obj.align = "l";
obj.xOff = 20;
obj.label = "changeID";
table.insert(GHI_ExportMenu[1][7],obj);

obj = {};
obj.type = "CheckBox";
obj.text = GHI_CHANGE_USER;
obj.align = "l";
obj.xOff = 20;
obj.label = "changeCreator";
table.insert(GHI_ExportMenu[1][8],obj);

obj = {};
obj.type = "Button";
obj.text = GHI_EXPORT;
obj.align = "c";
obj.label = "export";
obj.compact = true;
obj.onclick = function() 
	local f = this.main;
	if f.ID and f.ExportID then
		local ID = f.ID;
		local exID = f.ExportID;
		local amount = f.GetLabel("amount") or 1;
		local prChar = f.GetLabel("total") or 0;
		local changeID = f.GetLabel("changeID");
		local changeCreator = f.GetLabel("changeCreator");
		local limitType = f.GetLabel("limitation_type");
		local limitFilter = f.GetLabel("limitation_filter");
		
		local scriptBefore = "IMPORT_REQ = true;";
		local req = "IMPORT_REQ == true";
		local scriptAfter = "";
		
		-- pr char limitation
		if prChar > 0 then
			scriptBefore = scriptBefore.." GHI_MiscData = (GHI_MiscData or {}); GHI_MiscData.Import = (GHI_MiscData.Import or {}); local n = GHI_MiscData.Import."..exID.."; if not(type(n) == \"number\") then n = 0; end  if not(n < "..prChar..") then IMPORT_REQ = false end";
			
			scriptAfter = scriptAfter.." GHI_MiscData.Import."..exID.." = (GHI_MiscData.Import."..exID.." or 0)+1;"
		end
			
		-- limitation
		if limitType == 5 then
			scriptBefore = scriptBefore.." if not("..limitFilter..") then IMPORT_REQ = false end";
		elseif limitType > 1 then
			local st = {}
			st[2] = "UnitName(\"player\")";
			st[3] = "GetGuildInfo(\"player\")";
			st[4] = "GetRealmName()"
			if st[limitType] then
				--scriptBefore = scriptBefore.." if not(strfind("..limitFilter..","..st[limitType]..") then IMPORT_REQ = false end";
				scriptBefore = scriptBefore.." local t = {strsplit(\",\",\""..limitFilter.."\")}; local found; for i=1,table.getn(t) do if strlower(strtrim(t[i] or \"\")) == strlower("..st[limitType]..") then found = true; end end if not(found == true) then IMPORT_REQ = false end"
			end
		end
		
		
		
		-- change creator
		if changeCreator == 1 then
			scriptAfter = scriptAfter.." G_Import.item.creater = UnitName(\"player\");"
			
			-- also change ID
			scriptAfter = scriptAfter.." G_Import.ID = GHI_GenerateID();"
		elseif changeID == 1 then -- change ID
			scriptAfter = scriptAfter.." G_Import.ID = GHI_GenerateID();"
		end
		
		
		local s = GHI_ExportItem(f.ID,amount,scriptBefore,req,scriptAfter)
		
		getglobal(f.GetLabelFrame("code"):GetName().."ScrollText"):SetMaxLetters(string.len(s)+5) 
		
		f.ForceLabel("code",s);
	end
end
table.insert(GHI_ExportMenu[1][9],obj);	


obj = {};
obj.type = "EditField";
obj.align = "c";
obj.height = 160;
obj.width = 260;
obj.label = "code";
table.insert(GHI_ExportMenu[1][10],obj);

obj = {};
obj.type = "Dummy";
obj.height = 20;
obj.width = 10;
obj.align = "c";
table.insert(GHI_ExportMenu[1][11],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.xOff = 20;
obj.width = 240;
obj.color = "white";
obj.text = GHI_EXPORT_TEXT;
obj.align = "l";
table.insert(GHI_ExportMenu[1][12],obj);


end

if 1==1 then --	Import
GHI_ImportMenu = {};
GHI_ImportMenu.title = GHI_IMPORT;
GHI_ImportMenu.name = "Import Item";
GHI_ImportMenu.hasCloseButton = true;
GHI_ImportMenu.theme = "SpellBookTheme";
GHI_ImportMenu.icon = "Interface\\Icons\\INV_Crate_04";
GHI_ImportMenu.height = 430;
GHI_ImportMenu.OnOk = function()
	
end;
GHI_ImportMenu[1] = {};
for i=1,10 do
GHI_ImportMenu[1][i] = {};
end

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.color = "white";
obj.width = 240;
obj.xOff = 20;
obj.yOff = -10;
obj.text = GHI_IMPORT_INSTRUCTION;
obj.align = "l";
table.insert(GHI_ImportMenu[1][1],obj);

obj = {};
obj.type = "Dummy";
obj.height = 20;
obj.width = 10;
obj.align = "c";
table.insert(GHI_ImportMenu[1][2],obj);

obj = {};
obj.type = "EditField";
obj.align = "c";
obj.height = 160;
obj.width = 260;
obj.label = "code";
table.insert(GHI_ImportMenu[1][3],obj);

obj = {};
obj.type = "Button";
obj.text = GHI_IMPORT;
obj.align = "c";
obj.label = "export";
obj.compact = true;
obj.onclick = function() 
	local code = this.main.GetLabel("code")
	if not(code == "") then
		code = gsub(code,"||",strchar(124));
		GHI_ImportItem(code);
	end 
end
table.insert(GHI_ImportMenu[1][4],obj);	


end


if 1==1 then --	New Custom Slot
GHI_NCS_Menu = {};
GHI_NCS_Menu.title = GHI_NEW_CUSTOM_SLOT;
GHI_NCS_Menu.name = "GHI_NCS";
GHI_NCS_Menu.theme = "SpellBookTheme";
GHI_NCS_Menu.icon = "Interface/Icons/Ability_Rogue_Disguise";
GHI_NCS_Menu.height = 670;
GHI_NCS_Menu.OnCancel= function()
	local main = this:GetParent();
	if main.edit then
		GHI_PlayerEDBtnClick("DisplayedSlots");
	end
end
GHI_NCS_Menu.OnOk = function()
	local main = this:GetParent();
	
	local display = {
		x = main.GetLabel("x"),
		y = main.GetLabel("y"),
		z = main.GetLabel("z"),
		name = main.GetLabel("name");
		scale = main.GetLabel("scale"),
		code = main.GetLabel("code"),
		enabled = true,
	};
	
	local id;
	if main.edit then
		id = main.edit;
	else
		id = GHI_GenerateID();
	end		
	GHI_SetCustomSlotInfo(id,display);
	if main.edit then
		GHI_PlayerEDBtnClick("DisplayedSlots");
	end
	
end;
GHI_NCS_Menu.OnShow = function()
	local main = this;
	if not(main.setUp) then
		main.setUp = true;
		main.EqD = New_GH_Display();
		main.EqD:SetUnit("player");
		main.EqD.display:SetPoint("TOPLEFT", main, "TOPLEFT", 30, -80);
		main.EqD:SetFrameStrata("DIALOG");
		main.EqD.display:SetParent(main);
		main.EqD:SetFrameLevel(10);
	end
	
	main.EqD:Show();			
	if main.edit then
		
	else
		main.ForceLabel("x",0.0);
		main.ForceLabel("y",0.0);
		main.ForceLabel("z",0.0);
		main.ForceLabel("code","SHOW = true;");
		main.ForceLabel("scale",1.0);
	end
	
end;


GHI_NCS_Menu[1] = {};
for i = 1,14 do
GHI_NCS_Menu[1][i] = {};
end

obj = {};
obj.type = "Dummy";
obj.height = 0;
obj.width = 10;
obj.align = "c";
table.insert(GHI_NCS_Menu[1][1],obj);

obj = {};
obj.type = "Editbox";
obj.text = GHI_SLOT_NAME;--loc
obj.align = "r";
obj.label = "name";
obj.width = 120;
table.insert(GHI_NCS_Menu[1][2],obj);

local start = 2;
local vals = {"x","y","z"};

for i=1,table.getn(vals) do
	local v = vals[i];
	
	obj = {};
	obj.type = "Button";
	obj.text = "++";
	obj.align = "r";
	obj.label = v.."++";
	obj.compact = true;
	obj.OnLoad = function()
		this:SetScript("OnUpdate",function() 
			if this:GetButtonState() == "PUSHED" then
				local v = this.main.GetLabel(string.sub(this.label,0,1)) or 0;
				this.main.ForceLabel(string.sub(this.label,0,1),v+ 0.10)
			end
		end);
	end
	obj.onclick = function()
		--local v = this.main.GetLabel(string.sub(this.label,0,1)) or 0;
		--this.main.ForceLabel(string.sub(this.label,0,1),v+ 0.10)
	end
	table.insert(GHI_NCS_Menu[1][start+i],obj);

	obj = {};
	obj.type = "Button";
	obj.text = "+";
	obj.align = "r";
	obj.label = v.."+";
	obj.xOff = -5;
	obj.compact = true;
	obj.OnLoad = function()
		this:SetScript("OnUpdate",function() 
			if this:GetButtonState() == "PUSHED" then
				local v = this.main.GetLabel(string.sub(this.label,0,1)) or 0;
				this.main.ForceLabel(string.sub(this.label,0,1),v+ 0.010)
			end
		end);
	end
	obj.onclick = function() 
		--local v = this.main.GetLabel(string.sub(this.label,0,1)) or 0;
		--this.main.ForceLabel(string.sub(this.label,0,1),tonumber(v)+ 0.01)
	end
	table.insert(GHI_NCS_Menu[1][start+i],obj);

	obj = {};
	obj.type = "Editbox";
	obj.text = string.upper(v)..":";
	obj.align = "r";
	obj.label = v;
	obj.width = 40;
	obj.yOff = 4;
	obj.numbersOnly = true;
	obj.onchange = function()
		local x,y,z,scale = this.main.GetLabel("x") or 0,this.main.GetLabel("y") or 0,this.main.GetLabel("z") or 0,this.main.GetLabel("scale") or 0;
		local objs = {GH_DO:Create(x,y,z,scale,"","Interface\\BUTTONS\\UI-QuickslotRed.blp",nil,nil,"R1")};	
		this.main.EqD:SetObjects(objs);
	end
	table.insert(GHI_NCS_Menu[1][start+i],obj);


	obj = {};
	obj.type = "Button";
	obj.text = "-";
	obj.align = "r";
	obj.label = v.."-";
	obj.xOff = -20;
	obj.compact = true;
	obj.OnLoad = function()
		this:SetScript("OnUpdate",function() 
			if this:GetButtonState() == "PUSHED" then
				local v = this.main.GetLabel(string.sub(this.label,0,1)) or 0;
				this.main.ForceLabel(string.sub(this.label,0,1),v- 0.010)
			end
		end);
	end
	obj.onclick = function() 
		--local v = this.main.GetLabel(string.sub(this.label,0,1)) or 0 or 0;
		--this.main.ForceLabel(string.sub(this.label,0,1),tonumber(v)- 0.01)
	end
	table.insert(GHI_NCS_Menu[1][start+i],obj);

	obj = {};
	obj.type = "Button";
	obj.text = "--";
	obj.align = "r";
	obj.label = v.."--";
	obj.xOff = -5;
	obj.compact = true;
	obj.OnLoad = function()this:SetScript("OnUpdate",function() 
			if this:GetButtonState() == "PUSHED" then
				local v = this.main.GetLabel(string.sub(this.label,0,1)) or 0;
				this.main.ForceLabel(string.sub(this.label,0,1),v- 0.10)
			end
		end);
	end
	obj.onclick = function() 
		--local v = this.main.GetLabel(string.sub(this.label,0,1)) or 0;
		--this.main.ForceLabel(string.sub(this.label,0,1),tonumber(v)- 0.10)
	end
	table.insert(GHI_NCS_Menu[1][start+i],obj);

end

obj = {};
obj.type = "Editbox";
obj.text = GHI_SCALE;
obj.align = "r";
obj.numbersOnly = true;
obj.xOff = -30;
obj.label = "scale";
obj.width = 60;
obj.onchange = function()
	local x,y,z,scale = this.main.GetLabel("x") or 0,this.main.GetLabel("y") or 0,this.main.GetLabel("z") or 0,this.main.GetLabel("scale") or 0;
	local objs = {GH_DO:Create(x,y,z,scale,"","Interface\\BUTTONS\\UI-QuickslotRed.blp",nil,nil,"R1")};	
	this.main.EqD:SetObjects(objs);
end
table.insert(GHI_NCS_Menu[1][6],obj);

obj = {};
obj.type = "Dummy";
obj.height = 30;
obj.width = 20;
obj.align = "c";
table.insert(GHI_NCS_Menu[1][7],obj);

obj = {};
obj.type = "EditField";
obj.align = "c";
obj.height = 100;
obj.width = 260;
obj.label = "code";
table.insert(GHI_NCS_Menu[1][8],obj);

--obj = {};
--obj.type = "Dummy";
--obj.height = 0;
--obj.width = 10;
--obj.align = "c";
--table.insert(GHI_NCS_Menu[1][8],obj);

obj = {};
obj.type = "Text";
obj.fontSize = 11;
obj.text = GHI_EQD_SCRIPT;
obj.xOff = 20;
obj.align = "l";
table.insert(GHI_NCS_Menu[1][9],obj);

end

if 1==1 then -- Calibration output
local c = "script"
GHI_Calb_Menu = {};
GHI_Calb_Menu.title = "Callibration Output";
GHI_Calb_Menu.name = "GHI_Calb";
GHI_Calb_Menu.theme = "SpellBookTheme";
GHI_Calb_Menu.icon = GHI_RCIcons[c];
GHI_Calb_Menu.height = 500;
GHI_Calb_Menu.OnOk = function()
end;
GHI_Calb_Menu[1] = {};

GHI_Calb_Menu[1][1] = {};
GHI_Calb_Menu[1][2] = {};
GHI_Calb_Menu[1][3] = {};
GHI_Calb_Menu[1][4] = {};

obj = {};
obj.type = "EditField";
obj.align = "c";
obj.height = 260;
obj.width = 260;
obj.label = "code";
table.insert(GHI_Calb_Menu[1][1],obj);


end

GHI_DisplayedSlotMenu = { -- menu selection of displayed slots 
	title = "Displayed Slots",
	name = "GHI_ED_DisplayedSlots",
	theme = "SpellBookTheme",
	icon = "Interface\\Icons\\Ability_Rogue_BloodyEye",
	height = 410,
	OnOk = function()
		local main = this:GetParent();
		local list = main.GetLabelFrame("list");
		t ={};
		t2 = GHI_EquipmentDisplayData.customSlots or {}
		for _,slot in pairs(list.data) do
			if slot.type== GHI_STANDARD then
				if slot.check then
					table.insert(t,slot.id_name);
				end
			else
				t2[slot.id].enabled = slot.check;
			end
		end
		GHI_EquipmentDisplayData.customSlots = t2;
		GHI_EquipmentDisplayData.stdEnabled = t;
		GHI_UpdatePlayerEquipmentDisplay();
	end, 
	{ -- page 1
	{ -- line 1 
		{ -- object 1
			type = "List",
			align = "c",
			lines = 7,
			height = 200,
			width = 280,
			label = "list",
			column = {
				{
					type = "CheckButton",
					catagory = "",
					width = 20,
					label = "check",
				},
				{
					type = "Text",
					catagory = "Slot Name",
					width = 170,
					label = "name",
				},
				{
					type = "Text",
					catagory = "Slot Type",
					width = 80,
					label = "type",
				},
			},
			onclick = function(f,n)
				local main = f.main;
				local edit = main.GetLabelFrame("edit");
				if f.data[n].isCustom then
					edit:Enable();
				else
					edit:Disable();
				end
			end,
		}
	},{
		{
			type = "Button",
			text = GHI_EDIT,
			label = "edit",
			align = "c",
			onclick = function()
				local main = this.main;
				local list = main.GetLabelFrame("list");
				local t = list.GetTuble(list.GetMarked());
				if t.id then
					main:Hide();
					GHI_ShowNewSlotMenu(t.id)
				end
			end,
			
			
		}
	}
	}
	
};


GHI_BackgroundMenu = {
	title = "Figure Background",
	name = "GHI_ED_BackgroundMenu",
	theme = "SpellBookTheme",
	icon = "Interface\\Icons\\Achievement_Zone_ArathiHighlands_01",
	height = 575,
	OnOk = function()
		local main = this:GetParent();
		GHI_EqDisplaySetBackground(main.GetLabel("img"));
	end, 
	{ -- page 1
	{ -- line 1 
		{ -- object 1
			type = "ImageList",
			align = "c",
			height = 355,
			width = 280,
			scaleX = 1.16,
			scaleY = 1.16*2,
			label = "img",
			xOff = -10,
		}
	}
	}
	
}

--  /script fff=GHM_NewFrame(GHI_BackgroundMenu); fff:Show(); GHI_ED_BackgroundMenu_P1_L1_O1.SetImages({"abc","","","","","","","","",""});
--	/dump GHI_ED_BackgroundMenu_P1_L1_O1.images
--	/script fff=GHM_NewFrame(GHI_BackgroundMenu); fff:Show(); local t = GHM_StockIcons[ "Spell" ] local l={}; for i =1,20 do table.insert(l,{p="Interface\\Icons\\"..t[random(table.getn(t))]}); end GHI_ED_BackgroundMenu_P1_L1_O1.SetImages(l)
--  /script fff=GHM_NewFrame(GHI_BackgroundMenu); fff:Show(); GHI_ED_BackgroundMenu_P1_L1_O1.SetImages({{x=64,y=128}});
--	/script GHI_ED_BackgroundMenu_P1_L1_O1.SetImages({"abc","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
--	/dump GHI_ED_BackgroundMenu_P1_L1_O1Pic1
--	/script ItemTextPageText2:SetText("Test");

--
-- /dump GHI_ED_BackgroundMenu_P1_L1_O1Img1IconTexture
-- /script GHI_ED_BackgroundMenu_P1_L1_O1.SetScale(1.3)


