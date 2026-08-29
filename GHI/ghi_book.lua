
GHI_BookDefaultLayout = {};
GHI_BookDefaultLayout.font = "Fonts\\MORPHEUS.TTF";
GHI_BookDefaultLayout.N = 15;
GHI_BookDefaultLayout.H1 = 24;
GHI_BookDefaultLayout.H2 = 19;

GHI_MIN_FONT_SIZE = 7;
GHI_MAX_FONT_SIZE = 35;

GHI_Fonts = {};
local details = {}; details.path = "Fonts\\MORPHEUS.TTF"; details.name = "Morpheus"; table.insert(GHI_Fonts,details);
local details = {}; details.path = "Fonts\\FRIZQT__.TTF"; details.name = "Frizqt"; table.insert(GHI_Fonts,details);
local details = {}; details.path = "Fonts\\ARIALN.TTF"; details.name = "Arialn"; table.insert(GHI_Fonts,details);
local details = {}; details.path = "Fonts\\SKURRI.TTF"; details.name = "Skurri"; table.insert(GHI_Fonts,details);
local details = {}; details.path = "Interface\\Addons\\GHI\\Fonts\\bdrenais.TTF"; details.name = "Renaissance"; table.insert(GHI_Fonts,details);
local details = {}; details.path = "Interface\\Addons\\GHI\\Fonts\\blkchcry.TTF"; details.name = "Blkchcry"; table.insert(GHI_Fonts,details);
local details = {}; details.path = "Interface\\Addons\\GHI\\Fonts\\Killig.TTF"; details.name = "Killigrew"; table.insert(GHI_Fonts,details);
local details = {}; details.path = "Interface\\Addons\\GHI\\Fonts\\ALFABET_.TTF"; details.name = "Alfabatix"; table.insert(GHI_Fonts,details);
local details = {}; details.path = "Interface\\Addons\\GHI\\Fonts\\HOLY.TTF"; details.name = "Holy Empire"; table.insert(GHI_Fonts,details);
local details = {}; details.path = "Interface\\Addons\\GHI\\Fonts\\Alakob.TTF"; details.name = "Alako"; table.insert(GHI_Fonts,details);



--[[
/script GHI_ItemTextPageText:SetFont("Fonts\\MORPHEUS.TTF",14);
/script GHI_ItemTextPageText:SetFont("Fonts\\FRIZQT__.TTF",14);
/script GHI_ItemTextPageText:SetFont("Fonts\\ARIALN.TTF",14);
/script GHI_ItemTextPageText:SetFont("Fonts\\SKURRI.TTF",14);
]]


function GHI_BookNextPage()
	if not(GHI_CurrentBookPage) or not(GHI_CurrentBook)  or not(GHI_CurrentBook.pages) then
		this:GetParent():Hide();
		return;
	end
	if GHI_CurrentBook.pages > GHI_CurrentBookPage then
		GHI_CurrentBookPage = GHI_CurrentBookPage + 1;
		GHI_ShowBook(GHI_CurrentBook.title,GHI_CurrentBook[GHI_CurrentBookPage],GHI_CurrentBookEdit,GHI_CurrentMaterial,GHI_CurrentBook.font,GHI_CurrentBook.n,GHI_CurrentBook.h1,GHI_CurrentBook.h2);
		GHI_ItemTextFrameCurrentPage:SetText(GHI_CurrentBookPage.."/"..GHI_CurrentBook.pages);
		GHI_ItemTextFrameScrollFrame:SetVerticalScroll(0);
		
		
		GHI_ItemTextFrame:Show();
		GHI_ItemTextPageText:Show();
		GHI_ItemTextPageMarkable:Hide();
		GHI_ItemTextFrameMarkButton:SetText(GHI_MARK_TEXT);
		GHI_ItemTextFrameMarkButton.click = 0;
	end
end

function GHI_BookPrevPage()
	if not(GHI_CurrentBookPage) or not(GHI_CurrentBook)  or not(GHI_CurrentBook.pages) then
		this:GetParent():Hide();
		return;
	end
	if 1 < GHI_CurrentBookPage then
		GHI_CurrentBookPage = GHI_CurrentBookPage - 1;
		GHI_ShowBook(GHI_CurrentBook.title,GHI_CurrentBook[GHI_CurrentBookPage],GHI_CurrentBookEdit,GHI_CurrentMaterial,GHI_CurrentBook.font,GHI_CurrentBook.n,GHI_CurrentBook.h1,GHI_CurrentBook.h2);
		GHI_ItemTextFrameCurrentPage:SetText(GHI_CurrentBookPage.."/"..GHI_CurrentBook.pages);
		GHI_ItemTextFrameScrollFrame:SetVerticalScroll(0);
		
		GHI_ItemTextFrame:Show();
		GHI_ItemTextPageText:Show();
		GHI_ItemTextPageMarkable:Hide();
		GHI_ItemTextFrameMarkButton:SetText(GHI_MARK_TEXT);
		GHI_ItemTextFrameMarkButton.click = 0;
	end
end

function GHI_ShowBook(title,text,edit,material,font,N,H1,H2)
	
	
	if title then
		GHI_ItemTextFrameTitleText:SetText(title);
	else
		GHI_ItemTextFrameTitleText:SetText("");
	end

	
	
	if not N then 
		N = GHI_BookDefaultLayout.N;
	end
	if not H1 then
		H1 = GHI_BookDefaultLayout.H1;
	end
	if not H2 then
		H2 = GHI_BookDefaultLayout.H2;
	end
	if not font then
		font = GHI_BookDefaultLayout.font;
	end
	
	if ( not material ) then
		material = "Parchment";
	end
	
	GHI_ItemTextPageText:SetFont(font,N);
	GHI_ItemTextFontH1:SetFont(font,H1);
	GHI_ItemTextFontH2:SetFont(font,H2);
	
	local finalText;
	
	if type(text) == "string" then
		GHI_CheckForIcons(text,material);
		--GHI_ItemTextPageText:SetText(finalText);
	elseif type(text) == "table" then
		local PageText = "";
		if text.text1 then
			PageText = PageText..text.text1;
		end
		if text.text2 then
			PageText = PageText..text.text2;
		end
		if text.text3 then
			PageText = PageText..text.text3;
		end
		if text.text4 then
			PageText = PageText..text.text4;
		end
		if text.text5 then
			PageText = PageText..text.text5;
		end
		if text.text6 then
			PageText = PageText..text.text6;
		end
		if text.text7 then
			PageText = PageText..text.text7;
		end
		if text.text8 then
			PageText = PageText..text.text8;
		end
		if text.text9 then
			PageText = PageText..text.text9;
		end
		if text.text10 then
			PageText = PageText..text.text10;
		end
		GHI_CheckForIcons(PageText,material);
		--GHI_Message("Inserted icons");
		--GHI_ItemTextPageText:SetText(finalText);
		
	else
		--GHI_Message("Return1");
		return;
	end
	
	if edit == 1 then
		GHI_ItemTextFrameCurrentPage:SetPoint("TOP", 10, -40);
		GHI_ItemTextFrameEditButton:Show();
		GHI_ItemTextFrameMarkButton:Hide();
	else
		GHI_ItemTextFrameCurrentPage:SetPoint("TOP", 10, -40);
		GHI_ItemTextFrameEditButton:Hide();
		GHI_ItemTextFrameMarkButton:Show();
	end
	
	
	local textColor = GetMaterialTextColors(material);
	GHI_ItemTextPageText:SetTextColor(textColor[1], textColor[2], textColor[3]);
	GHI_ItemTextFontH1:SetTextColor(textColor[1], textColor[2], textColor[3]);
	GHI_ItemTextFontH2:SetTextColor(textColor[1], textColor[2], textColor[3]);
	
	if ( material == "Parchment" ) then
		GHI_ItemTextFrameMaterialTopLeft:Hide();
		GHI_ItemTextFrameMaterialTopRight:Hide();
		GHI_ItemTextFrameMaterialBotLeft:Hide();
		GHI_ItemTextFrameMaterialBotRight:Hide();
	else
		GHI_ItemTextFrameMaterialTopLeft:Show();
		GHI_ItemTextFrameMaterialTopRight:Show();
		GHI_ItemTextFrameMaterialBotLeft:Show();
		GHI_ItemTextFrameMaterialBotRight:Show();
		GHI_ItemTextFrameMaterialTopLeft:SetTexture("Interface\\ItemTextFrame\\ItemText-"..material.."-TopLeft");
		GHI_ItemTextFrameMaterialTopRight:SetTexture("Interface\\ItemTextFrame\\ItemText-"..material.."-TopRight");
		GHI_ItemTextFrameMaterialBotLeft:SetTexture("Interface\\ItemTextFrame\\ItemText-"..material.."-BotLeft");
		GHI_ItemTextFrameMaterialBotRight:SetTexture("Interface\\ItemTextFrame\\ItemText-"..material.."-BotRight");
	end
	
	
	
	GHI_ItemTextFrameScrollFrame:UpdateScrollChildRect(); 
	GHI_ItemTextFrame:Show();
	
	
	GHI_ItemTextPageText:Show();
	GHI_ItemTextPageMarkable:Hide();
	GHI_ItemTextFrameMarkButton:SetText(GHI_MARK_TEXT);
	GHI_ItemTextFrameMarkButton.click = 0;
end

GHI_AH = nil;
function GHI_BookHyperlinkClick(p)
	--GHI_BookNextPage();
	--GHI_ItemTextPageText:SetText("Hyberlink clicked");
	if not p then return end;
	
	if GHI_CurrentBook.pages >= p then
		
		
		
		GHI_CurrentBookPage = p;
		
		--GHI_Message("1: "..GHI_ItemTextPageText:GetText());
		GHI_ItemTextFrameCurrentPage:SetText(GHI_CurrentBookPage.."/"..GHI_CurrentBook.pages);
		
		
		GHI_AH =true;
		
	end
end

function GHI_AfterHyberlink()
	if GHI_AH == true then
		GHI_ShowBook(GHI_CurrentBook.title,GHI_CurrentBook[GHI_CurrentBookPage],GHI_CurrentBookEdit,GHI_CurrentMaterial,GHI_CurrentBook.font,GHI_CurrentBook.n,GHI_CurrentBook.h1,GHI_CurrentBook.h2);
		GHI_ItemTextFrameScrollFrame:SetVerticalScroll(0);
		GHI_AH = nil;
	end
end


-- 	===================	Edit functions	===================
function GHI_BookEdit(ID,page)
	GHI_ItemTextFrame:Hide();
	local rc = GHI_GetRightClickInfo(ID);
	local orig = nil;
	if (type(rc)=="table") and rc.Type == "multible" then
		orig = rc;
		rc = orig[orig.book_index];
	end
	if not rc then return end;
	
	GHI_ItemTextEditFrameTitleText:SetText(rc.title)
	GHI_ItemTextEditFrameCurrentPage:SetText(page.."/"..rc.pages);
	
	
	local PageText
	if rc[page] then
		local text = rc[page];
		PageText = "";
		if type(text) == "string" then
			PageText = text;
		elseif type(text) == "table" then
			if text.text1 then
				PageText = PageText..text.text1;
			end
			if text.text2 then
				PageText = PageText..text.text2;
			end
			if text.text3 then
				PageText = PageText..text.text3;
			end
			if text.text4 then
				PageText = PageText..text.text4;
			end
			if text.text5 then
				PageText = PageText..text.text5;
			end
			if text.text6 then
				PageText = PageText..text.text6;
			end
			if text.text7 then
				PageText = PageText..text.text7;
			end
			if text.text8 then
				PageText = PageText..text.text8;
			end
			if text.text9 then
				PageText = PageText..text.text9;
			end
			if text.text10 then
				PageText = PageText..text.text10;
			end
		end
	end
	
	local textString = GHI_HtmlToString(PageText);
	
	if not rc.material then rc.material = "Parchment"; end
	
	GHI_ItemTextPageEdit:SetText(textString);
	
	local updateRC = false;
	if not rc.n then 
		rc.n = GHI_BookDefaultLayout.N;
		updateRC = true;
	end
	if not rc.h1 then
		rc.h1 = GHI_BookDefaultLayout.H1;
		updateRC = true;
	end
	if not rc.h2 then
		rc.h2 = GHI_BookDefaultLayout.H2;
		updateRC = true;
	end
	if not rc.font then
		rc.font = GHI_BookDefaultLayout.font;
		updateRC = true;
	end
	
	if updateRC == true then
		if orig.book_index then
			orig[orig.book_index] = rc;
			GHI_SetRightClickInfo(ID,orig)
		else
			GHI_SetRightClickInfo(ID,rc)
		end
	end
	
	GHI_ItemTextEditFrameSideFrameNSize:SetText(rc.n);
	GHI_ItemTextEditFrameSideFrameH1Size:SetText(rc.h1);
	GHI_ItemTextEditFrameSideFrameH2Size:SetText(rc.h2);
	
	
	GHI_ItemTextPageEdit:SetFont(rc.font,15);
	
	GHI_MatDD_Update();
	
	GHI_BookSetEditMaterial(rc.material)
	
	GHI_MatType = 1;
	for i = 1,table.getn(GHI_MatTypes) do
		if GHI_MatTypes[i] == rc.material then
			GHI_MatType = i;
		end
	end
	
	
	
	
	GHI_ItemTextEditFrameSideFrameMatDropDownTextLabel:SetText(GHI_MatNames[GHI_MatType]);
	
	
	
	if rc.pages == 1 then 
		GHI_ItemTextEditFramePrevPageButton:Hide();
		GHI_ItemTextEditFrameNextPageButton:Hide();
	else
		GHI_ItemTextEditFramePrevPageButton:Show();
		GHI_ItemTextEditFrameNextPageButton:Show();
	end
	
	
	
	local FontType = 1;
	for i = 1,table.getn(GHI_Fonts) do
		if GHI_Fonts[i].path == rc.font then
			FontType = i;
		end
	end
	GHI_ItemTextEditFrameSideFrameFontDropDownTextLabel:SetText(GHI_Fonts[FontType].name);
	
	GHI_EditPage = page;
	GHI_EditID = ID;
	
	GHI_ItemTextEditFrameScrollFrame:SetVerticalScroll(0);
	
	
	GHI_ItemTextEditFrame:Show();
	GHI_ItemTextPageEdit:SetFocus();
	
	
end

function GHI_BookSetEditMaterial(material)
	if not(material) then
		material = "Parchment";
	end

	local textColor = GetMaterialTextColors(material);
	GHI_ItemTextPageEdit:SetTextColor(textColor[1], textColor[2], textColor[3]);
	
	if ( material == "Parchment" ) then
		GHI_ItemTextEditFrameMaterialTopLeft:Hide();
		GHI_ItemTextEditFrameMaterialTopRight:Hide();
		GHI_ItemTextEditFrameMaterialBotLeft:Hide();
		GHI_ItemTextEditFrameMaterialBotRight:Hide();
	else
		GHI_ItemTextEditFrameMaterialTopLeft:Show();
		GHI_ItemTextEditFrameMaterialTopRight:Show();
		GHI_ItemTextEditFrameMaterialBotLeft:Show();
		GHI_ItemTextEditFrameMaterialBotRight:Show();
		GHI_ItemTextEditFrameMaterialTopLeft:SetTexture("Interface\\ItemTextFrame\\ItemText-"..material.."-TopLeft");
		GHI_ItemTextEditFrameMaterialTopRight:SetTexture("Interface\\ItemTextFrame\\ItemText-"..material.."-TopRight");
		GHI_ItemTextEditFrameMaterialBotLeft:SetTexture("Interface\\ItemTextFrame\\ItemText-"..material.."-BotLeft");
		GHI_ItemTextEditFrameMaterialBotRight:SetTexture("Interface\\ItemTextFrame\\ItemText-"..material.."-BotRight");
	end

end




function GHI_BookSafePage()
	local text = GHI_ItemTextPageEdit:GetText();
	local html = GHI_StringToHtml(text);
	local ID = GHI_EditID;
	local page = GHI_EditPage;
	
	if not(page) or not(ID) or not(html) then --GHI_Message("S-e1");
		return;
	end
	
	if GHI_IsOfficialItem(ID) then --GHI_Message("S-e2");
		return;
	end
	
	local rc = GHI_GetRightClickInfo(ID);
	local orig = nil;
	if (type(rc)=="table") and rc.Type == "multible" then
		orig = rc;
		rc = orig[orig.book_index];
	end
	
	if not(type(rc)=="table") then  --GHI_Message("S-e3");
		return;
	end
	
	rc[page] = {};
	rc[page].text1 = string.sub(html,0,127) 
	rc[page].text2 = string.sub(html,128,255) 
	rc[page].text3 = string.sub(html,256,383) 
	rc[page].text4 = string.sub(html,384,511) 
	rc[page].text5 = string.sub(html,512,639) 
	rc[page].text6 = string.sub(html,640,767) 
	rc[page].text7 = string.sub(html,768,895) 
	rc[page].text8 = string.sub(html,896,1023) 
	rc[page].text9 = string.sub(html,1024,1151) 
	rc[page].text10 = string.sub(html,1152,1279) 
	
	rc.n = GHI_ItemTextEditFrameSideFrameNSize:GetNumber();
	rc.h1 = GHI_ItemTextEditFrameSideFrameH1Size:GetNumber();
	rc.h2 = GHI_ItemTextEditFrameSideFrameH2Size:GetNumber();
	
	if orig then
		orig[orig.book_index] = rc;
		rc = orig;
	end
	
	if rc.version == nil or tonumber(rc.version)==nil then
		rc.version = 1;
	else
		rc.version = rc.version + 1;
	end
	
	GHI_SetRightClickInfo(ID,rc)
	
	
	GHI_UpdateItemVersion(ID)
	
	
	--GHI_Message("S-Success");
end

function GHI_BookUndo()
	GHI_BookEdit(GHI_EditID,GHI_EditPage)


end

function GHI_BookEditNextPage()
	local rc = GHI_GetRightClickInfo(GHI_EditID);
	if (type(rc)=="table") and rc.Type == "multible" then
		orig = rc;
		rc = orig[orig.book_index];
	end
	
	if not(GHI_EditPage) or not(GHI_EditID)  or not(rc) then
		this:GetParent():Hide();
		return;
	end
	
	GHI_BookSafePage();
	

	
	if rc.pages > GHI_EditPage then
		GHI_EditPage = GHI_EditPage + 1;
		GHI_BookEdit(GHI_EditID,GHI_EditPage);
	end
end

function GHI_BookEditPrevPage()
	local name = GHI_GetItemInfo(GHI_EditID)
	if not(GHI_EditPage) or not(GHI_EditID)  or not( name) then
		this:GetParent():Hide();
		return;
	end
	
	GHI_BookSafePage();
	

	
	if GHI_EditPage > 1 then
		GHI_EditPage = GHI_EditPage - 1;
		GHI_BookEdit(GHI_EditID,GHI_EditPage);
	end
end



function GHI_BookAddPageAfter()
	local name = GHI_GetItemInfo(GHI_EditID)
	if not(GHI_EditPage) or not(GHI_EditID)  or not( name) then
		this:GetParent():Hide();
		return;
	end
	
	local rc = GHI_GetRightClickInfo(GHI_EditID);
	local orig = nil;
	if (type(rc)=="table") and rc.Type == "multible" then
		orig = rc;
		rc = orig[orig.book_index];
	end
	
	rc.pages = rc.pages + 1;
	
	local newPageNumber = GHI_EditPage + 1;
	
	local TextData = {};
	TextData.text1 = ""
	TextData.text2 = ""
	TextData.text3 = ""
	TextData.text4 = ""
	TextData.text5 = ""
	TextData.text6 = ""
	TextData.text7 = ""
	TextData.text8 = ""
	TextData.text9 = ""
	TextData.text10 = ""
	
	table.insert(rc,newPageNumber,TextData);
	
	GHI_ItemTextEditFrameCurrentPage:SetText(GHI_EditPage.."/"..rc.pages);
	GHI_ItemTextEditFramePrevPageButton:Show();
	GHI_ItemTextEditFrameNextPageButton:Show();
	
	if orig then
		orig[orig.book_index] = rc;
		rc = orig;
	end
	GHI_SetRightClickInfo(GHI_EditID,rc);
	GHI_UpdateBookLinks(GHI_EditPage+1);
end

function GHI_BookAddPageBefore()
	local name = GHI_GetItemInfo(GHI_EditID)
	if not(GHI_EditPage) or not(GHI_EditID)  or not( name) then
		this:GetParent():Hide();
		return;
	end
	
	local rc = GHI_GetRightClickInfo(GHI_EditID)
	local orig = nil;
	if (type(rc)=="table") and rc.Type == "multible" then
		orig = rc;
		rc = orig[orig.book_index];
	end
	
	rc.pages = rc.pages + 1;
	
	local newPageNumber = GHI_EditPage;
	GHI_EditPage = GHI_EditPage + 1;
	
	local TextData = {};
	TextData.text1 = ""
	TextData.text2 = ""
	TextData.text3 = ""
	TextData.text4 = ""
	TextData.text5 = ""
	TextData.text6 = ""
	TextData.text7 = ""
	TextData.text8 = ""
	TextData.text9 = ""
	TextData.text10 = ""
	
	table.insert(rc,newPageNumber,TextData);
	
	GHI_ItemTextEditFrameCurrentPage:SetText(GHI_EditPage.."/"..rc.pages);
	GHI_ItemTextEditFramePrevPageButton:Show();
	GHI_ItemTextEditFrameNextPageButton:Show();
	
	if orig then
		orig[orig.book_index] = rc;
		rc = orig;
	end
	GHI_SetRightClickInfo(GHI_EditID,rc);
	GHI_UpdateBookLinks(GHI_EditPage-1);
end

function GHI_BookDeletePage(ID,page)
	local name = GHI_GetItemInfo(GHI_EditID)
	if not(GHI_EditPage) or not(GHI_EditID)  or not( name) then
		
		return;
	end
	page = tonumber(page);
	local rc = GHI_GetRightClickInfo(ID);
	local orig = nil;
	if (type(rc)=="table") and rc.Type == "multible" then
		orig = rc;
		rc = orig[orig.book_index];
	end
	
	table.remove(rc,page);
	rc.pages = rc.pages - 1;
	
	if orig then
		orig[orig.book_index] = rc;
		GHI_SetRightClickInfo(ID,orig);
	else
		GHI_SetRightClickInfo(ID,rc);
	end
	
	
	if rc.pages == 1 then 
		GHI_ItemTextEditFramePrevPageButton:Hide();
		GHI_ItemTextEditFrameNextPageButton:Hide();
	else
		GHI_ItemTextEditFramePrevPageButton:Show();
		GHI_ItemTextEditFrameNextPageButton:Show();
	end
	
	if page > rc.pages then	
		GHI_EditPage = rc.pages;
		GHI_BookEdit(ID,rc.pages);
	else
		GHI_EditPage = page;
		GHI_BookEdit(ID,page);
	end
	GHI_UpdateBookLinks(page,true);
end

function GHI_Book_SetTitle(newTitle)
	local name = GHI_GetItemInfo(GHI_EditID)
	if not(GHI_EditPage) or not(GHI_EditID)  or not( name) then
		this:GetParent():Hide();
		return;
	end
	local rc = GHI_GetRightClickInfo(GHI_EditID);
	
	local orig = nil;
	if (type(rc)=="table") and rc.Type == "multible" then
		orig = rc;
		rc = orig[orig.book_index];
	end
	
	rc.title = newTitle;
	
	if orig then
		orig[orig.book_index] = rc;
		rc = orig;
	end
	GHI_SetRightClickInfo(GHI_EditID,rc)
end

function GHI_Book_H1OnClick()
	local ht1,ht2 = GHI_GetHighlightedText(GHI_ItemTextPageEdit);
	if ht1 and ht2 then
		local orig_text = GHI_ItemTextPageEdit:GetText();
		local t1,t2,t3;
		t1 = string.sub(orig_text,0,ht1);
		t2 = string.sub(orig_text,ht1+1,ht2);
		t3 = string.sub(orig_text,ht2+1);
		text = t1.."<H1>"..t2.."</H1>\n"..t3;
		GHI_ItemTextPageEdit:SetText(text);
		-- Vanilla/Turtle WoW EditBox does not provide SetCursorPosition.
		-- Highlighting a zero-length range safely clears the selection and
		-- leaves the edit box usable on both old and newer clients.
		if GHI_ItemTextPageEdit.SetCursorPosition then
			GHI_ItemTextPageEdit:SetCursorPosition(ht2+9);
		else
			GHI_ItemTextPageEdit:HighlightText(ht2+9,ht2+9);
		end
		this.H1 = 0;
		getglobal(this:GetName().."Text"):SetText(GHI_HEADLINE_1);
		
	else
		
		if this.H1 == nil then
			this.H1 = 0;
		end
		if this.H1 == 0 then
			local text = GHI_ItemTextPageEdit:GetText();
			GHI_ItemTextPageEdit:SetText(text.."<H1>");
			this.H1 = 1;
			getglobal(this:GetName().."Text"):SetText("*"..GHI_HEADLINE_1);
		else
			local text = GHI_ItemTextPageEdit:GetText();
			GHI_ItemTextPageEdit:SetText(text.."</H1>\n");
			this.H1 = 0;
			getglobal(this:GetName().."Text"):SetText(GHI_HEADLINE_1);
		end
	end
	
end

function GHI_Book_H2OnClick()
	local ht1,ht2 = GHI_GetHighlightedText(GHI_ItemTextPageEdit);
	if ht1 and ht2 then
		local orig_text = GHI_ItemTextPageEdit:GetText();
		local t1,t2,t3;
		t1 = string.sub(orig_text,0,ht1);
		t2 = string.sub(orig_text,ht1+1,ht2);
		t3 = string.sub(orig_text,ht2+1);
		text = t1.."<H2>"..t2.."</H2>\n"..t3;
		GHI_ItemTextPageEdit:SetText(text);
		-- Vanilla/Turtle WoW EditBox does not provide SetCursorPosition.
		-- Highlighting a zero-length range safely clears the selection and
		-- leaves the edit box usable on both old and newer clients.
		if GHI_ItemTextPageEdit.SetCursorPosition then
			GHI_ItemTextPageEdit:SetCursorPosition(ht2+9);
		else
			GHI_ItemTextPageEdit:HighlightText(ht2+9,ht2+9);
		end
		this.H2 = 0;
		getglobal(this:GetName().."Text"):SetText(GHI_HEADLINE_2);
		
	else
		
		if this.H2 == nil then
			this.H2 = 0;
		end
		if this.H2 == 0 then
			local text = GHI_ItemTextPageEdit:GetText();
			GHI_ItemTextPageEdit:SetText(text.."<H2>");
			this.H2 = 1;
			getglobal(this:GetName().."Text"):SetText("*"..GHI_HEADLINE_2);
		else
			local text = GHI_ItemTextPageEdit:GetText();
			GHI_ItemTextPageEdit:SetText(text.."</H2>\n");
			this.H2 = 0;
			getglobal(this:GetName().."Text"):SetText(GHI_HEADLINE_2);
		end
	end
	
	
end

StaticPopupDialogs["GHI_DELETE_PAGE"] = {
	text = GHI_CONFIRM_DELETE_PAGE,
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		GHI_BookDeletePage(GHI_EditID,GHI_EditPage);
	end,
	OnCancel = function ()
		
	end,
	OnUpdate = function ()
		if (Old_GHI_EditPage == nil) then
			Old_GHI_EditPage = GHI_EditPage;
		end
		if (Old_GHI_EditID == nil) then
			Old_GHI_EditID = GHI_EditID;
		end
		
		if not(Old_GHI_EditID == GHI_EditID) or not(Old_GHI_EditPage == GHI_EditPage) then
			StaticPopup_Hide("GHI_DELETE_PAGE");
		end
	
		Old_GHI_EditID = GHI_EditID;
		Old_GHI_EditPage = GHI_EditPage;
	end,
	timeout = 0,
	whileDead = 1,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["GHI_EDIT_TITLE"] = {
	text = GHI_NEW_TITLE,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 30,
	OnAccept = function()
		local editBox = getglobal(this:GetParent():GetName().."EditBox");
		GHI_Book_SetTitle(editBox:GetText());
		GHI_ItemTextEditFrameTitleText:SetText(editBox:GetText());
	end,
	OnShow = function()
		local editBox = getglobal(this:GetName().."EditBox");
		local t = GHI_ItemTextEditFrameTitleText:GetText();
		if t then
			editBox:SetText(t);
		end
		editBox:SetFocus();
	end,
	OnHide = function()
		
	end,
	EditBoxOnEnterPressed = function()
		local editBox = getglobal(this:GetParent():GetName().."EditBox");
		GHI_Book_SetTitle(editBox:GetText());
		GHI_ItemTextEditFrameTitleText:SetText(editBox:GetText());
		this:GetParent():Hide();
	end,
	EditBoxOnEscapePressed = function()
		this:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};


GHI_LinkPage = nil;

StaticPopupDialogs["GHI_INSERT_LINKPAGE"] = {
	text = GHI_ENTER_PAGE_NUMBER,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 4,
	OnAccept = function()
		local editBox = getglobal(this:GetParent():GetName().."EditBox");
		local A = editBox:GetText();
		editBox:SetText("");
		this:GetParent():Hide();
		GHI_LinkPage = A;
		StaticPopup_Show("GHI_INSERT_LINKTEXT");
	end,
	OnShow = function()
		GHI_LinkPage = nil;
		local editBox = getglobal(this:GetName().."EditBox");
		editBox:SetText(1);
		editBox:SetNumeric(true)
		--editBox:SetText(GHI_ItemTextEditFrameTitleText:GetText());
		editBox:SetFocus();
	end,
	OnUpdate = function()
		local editBox = getglobal(this:GetName().."EditBox");
		local a = tonumber(editBox:GetText());
		local rc = GHI_GetRightClickInfo(GHI_EditID);
		local orig = nil;
		if (type(rc)=="table") and rc.Type == "multible" then
			orig = rc;
			rc = orig[orig.book_index];
		end
		if a then
			if a > rc.pages then
				editBox:SetText(rc.pages);
			end
		end
	end,
	OnHide = function()
		local editBox = getglobal(this:GetName().."EditBox");
		editBox:SetNumeric(false)
	end,
	EditBoxOnEnterPressed = function()
		local editBox = getglobal(this:GetParent():GetName().."EditBox");
		local A = editBox:GetText();
		editBox:SetText("");
		this:GetParent():Hide();
		GHI_LinkPage = A;
		StaticPopup_Show("GHI_INSERT_LINKTEXT");
	end,
	EditBoxOnEscapePressed = function()
		this:GetParent():Hide();
		GHI_LinkPage = nil;
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["GHI_INSERT_LINKTEXT"] = {
	text = GHI_ENTER_LINK_TEXT,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 30,
	OnAccept = function(data)
		local editBox = getglobal(this:GetParent():GetName().."EditBox");
		local A = editBox:GetText();
		
		GHI_Book_InsertLink(GHI_LinkPage,A);
		
		this:GetParent():Hide();
	end,
	OnShow = function()
		local editBox = getglobal(this:GetName().."EditBox");

		--editBox:SetText(GHI_ItemTextEditFrameTitleText:GetText());
		editBox:SetFocus();
	end,
	OnHide = function()
		GHI_LinkPage = nil;
	end,
	EditBoxOnEnterPressed = function(data)
		local editBox = getglobal(this:GetParent():GetName().."EditBox");
		local A = editBox:GetText();
		
		
		GHI_Book_InsertLink(GHI_LinkPage,A);
		
		this:GetParent():Hide();
	end,
	EditBoxOnEscapePressed = function()
		this:GetParent():Hide();
		GHI_LinkPage = nil;
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};


function GHI_Book_InsertLink(page,linkText)
	if not(page) or not(linkText) then
		return;
	end
	
	local text = GHI_ItemTextPageEdit:GetText();
	if not text then text = ""; end
	
	local A = text.."<A href=\34"..page.."\34>"..linkText.."</A>";
	GHI_ItemTextPageEdit:SetText(A);
	
end

function GHI_GetHighlightedText(frame)
	if not(frame) then return nil end
	
	local origText = frame:GetText();
	if not(origText) then return nil end
	
	frame:Insert("\127");
	local a = string.find(frame:GetText(),"\127");
	local partA = string.sub(frame:GetText(),0,a-1)
	local partB = string.sub(frame:GetText(),a+1)
	local cut1 = gsub(origText,partA,"");
	local middle = gsub(cut1,partB,"");
	local b = strlen(middle);
	frame:SetText(origText);
	frame:HighlightText(a-1,a-1+b);
	return a-1,a-1+b;
end



function GHI_HtmlToString(text)
	if text == nil then 
		return "";
	end
	text = string.gsub(text,"<HTML>",""); 
	text = string.gsub(text,"</HTML>","");
	text = string.gsub(text,"<BODY>","");  
	text = string.gsub(text,"</BODY>","");
	
	text = string.gsub(text,"&quot;","\"");
	text = string.gsub(text,"&gt;",">");
	text = string.gsub(text,"&lt;","<");
	text = string.gsub(text,"&amp;","&");
	
	text = string.gsub(text,"</P><P align=\"center\">","<al=c>");  
	text = string.gsub(text,"</P><P align=\"right\">","<al=r>");  
	text = string.gsub(text,"</P><P align=\"left\">","<al=l>");  
	
	text = string.gsub(text,"</P><P>","</al>\n"); 
	
	text = string.gsub(text,"<H1 align=\"center\">","<H1>");
	
	text = string.gsub(text,"<P>","");  
	text = string.gsub(text,"</P>","");
	text = string.gsub(text,"<BR/>","\n");
	text = string.gsub(text,"</H1>","</H1>\n");
	text = string.gsub(text,"</H2>","</H2>\n");
	
	
	--[[  	orig
	text = string.gsub(text,"</P><P align=\"center\">","<al=c>");  
	text = string.gsub(text,"</P><P>","</al>\n"); 
	
	text = string.gsub(text,"<H1 align=\"center\">","<H1>");
	
	text = string.gsub(text,"<P>","");  
	text = string.gsub(text,"</P>","");
	text = string.gsub(text,"<BR/>","\n");
	text = string.gsub(text,"</H1>","</H1>\n");
	text = string.gsub(text,"</H2>","</H2>\n");]]
	
	
	return text;
end

function GHI_StringToHtml(text)
	if text == nil then 
		return "";
	end
	
	--- Clear
	text = string.gsub(text,"<HTML>",""); 
	text = string.gsub(text,"</HTML>","");
	text = string.gsub(text,"<BODY>","");  
	text = string.gsub(text,"</BODY>","");
	text = string.gsub(text,"<P>","");  
	text = string.gsub(text,"</P>","");
	
	text = string.gsub(text,"</H1>\n","</H1>");	
	text = string.gsub(text,"</H2>\n","</H2>");	
	text = string.gsub(text,"</al>\n","</al>"); 
	
	---  clear text for special symbols
	text = string.gsub(text,"&","&amp;");
	text = string.gsub(text,">","&gt;");
	text = string.gsub(text,"<","&lt;");
	text = string.gsub(text,"\"","&quot;");
	
	--	reformat   
	text = string.gsub(text,"&lt;H1&gt;","</P><H1 align=\"center\">");
	text = string.gsub(text,"&lt;/H1&gt;","</H1><P>");
	text = string.gsub(text,"&lt;H2&gt;","</P><H2>");  
	text = string.gsub(text,"&lt;/H2&gt;","</H2><P>");
	text = string.gsub(text,"\n","<BR/>");  
	
	text = string.gsub(text,"&lt;al=c&gt;","</P><P align=\"center\">");  
	text = string.gsub(text,"&lt;al=l&gt;","</P><P align=\"left\">");  
	text = string.gsub(text,"&lt;al=r&gt;","</P><P align=\"right\">");  
	 
	text = string.gsub(text,"&lt;/al&gt;","</P><P>");  
	
	--   links
	text = string.gsub(text,"&lt;A href=&quot;","<A href=\"");
	text = string.gsub(text,"&quot;&gt;","\">");
	text = string.gsub(text,"&lt;/A&gt;","</A>");
	
	-- icons
	text = string.gsub(text,"&lt;Icon,","<Icon,");
	text = string.gsub(text,",L&gt;",",L>");
	text = string.gsub(text,",R&gt;",",R>");
	text = string.gsub(text,",C&gt;",",C>");
	
	-- pictures
	text = string.gsub(text,"&lt;img(.-)/&gt;",function(t) t = string.gsub(t,"&quot;","\""); return ("</P><img"..t.."/><P>"); end)
	
	--[[-- 	Original reformat   
	
	text = string.gsub(text,"<H1>","</P><H1 align=\"center\">");
	text = string.gsub(text,"</H1>\n","</H1>");	
	text = string.gsub(text,"</H1>","</H1><P>");
	text = string.gsub(text,"<H2>","</P><H2>");  
	text = string.gsub(text,"</H2>\n","</H2>");	
	text = string.gsub(text,"</H2>","</H2><P>");
	
	text = string.gsub(text,"\n","<BR/>");  
	
	text = string.gsub(text,"<al=c>","</P><P align=\"center\">");  
	text = string.gsub(text,"<al=l>","</P><P align=\"left\">");  
	text = string.gsub(text,"<al=r>","</P><P align=\"right\">");  
	text = string.gsub(text,"</al>\n","</al>");  
	text = string.gsub(text,"</al>","</P><P>");  ]]
	
	
	
	
	
	text = "<HTML><BODY><P>"..text.."</P></BODY></HTML>";
	return text;
end

function GHI_ShowTextForMarking(ID,page)
	
	
	GHI_ItemTextFrame:Show();
	GHI_ItemTextPageText:Hide();
	GHI_ItemTextPageMarkable:Show();
	
	local rc = GHI_GetRightClickInfo(ID);
	local orig = nil;
	if (type(rc)=="table") and rc.Type == "multible" then
		orig = rc;
		rc = orig[orig.book_index];
	end
	if not rc then return end;
	
	--GHI_ItemTextEditFrameTitleText:SetText(rc.title)
	--GHI_ItemTextEditFrameCurrentPage:SetText(page.."/"..rc.pages);
	
	
	local PageText
	if rc[page] then
		local text = rc[page];
		PageText = "";
		if type(text) == "string" then
			PageText = text;
		elseif type(text) == "table" then
			if text.text1 then
				PageText = PageText..text.text1;
			end
			if text.text2 then
				PageText = PageText..text.text2;
			end
			if text.text3 then
				PageText = PageText..text.text3;
			end
			if text.text4 then
				PageText = PageText..text.text4;
			end
			if text.text5 then
				PageText = PageText..text.text5;
			end
			if text.text6 then
				PageText = PageText..text.text6;
			end
			if text.text7 then
				PageText = PageText..text.text7;
			end
			if text.text8 then
				PageText = PageText..text.text8;
			end
			if text.text9 then
				PageText = PageText..text.text9;
			end
			if text.text10 then
				PageText = PageText..text.text10;
			end
		end
	end
	
	local textString = GHI_HtmlToString(PageText);
	
	if not rc.material then rc.material = "Parchment"; end
	
	GHI_ItemTextPageMarkable:SetText(textString);
	GHI_ItemTextPageMarkable.text = textString;
	

end


GHI_MatType = 1;
GHI_MatTypes = {}
GHI_MatNames = {};
function GHI_MatDD_Update()

	info            = {};
	info.text       = GHI_PARCHMENT;
	info.value      = 1;
	GHI_MatTypes[info.value] = "Parchment";
	GHI_MatNames[info.value] = info.text;
	info.func       = GHI_MatDDClick;
	UIDropDownMenu_AddButton(info);	

	
	info            = {};
	info.text       = GHI_BRONZE;
	info.value      = 2;
	GHI_MatTypes[info.value] = "Bronze";
	GHI_MatNames[info.value] = info.text;
	info.func       = GHI_MatDDClick;
	UIDropDownMenu_AddButton(info);	
	
	info            = {};
	info.text       = GHI_MARBLE;
	info.value      = 3;
	GHI_MatTypes[info.value] = "Marble";
	GHI_MatNames[info.value] = info.text;
	info.func       = GHI_MatDDClick;
	UIDropDownMenu_AddButton(info);	
	
	info            = {};
	info.text       = GHI_SILVER;
	info.value      = 4;
	GHI_MatTypes[info.value] = "Silver";
	GHI_MatNames[info.value] = info.text;
	info.func       = GHI_MatDDClick;
	UIDropDownMenu_AddButton(info);	
	
	info            = {};
	info.text       = GHI_STONE;
	info.value      = 5;
	GHI_MatTypes[info.value] = "Stone";
	GHI_MatNames[info.value] = info.text;
	info.func       = GHI_MatDDClick;
	UIDropDownMenu_AddButton(info);	
	
	info            = {};
	info.text       = GHI_VALENTINE;
	info.value      = 6;
	GHI_MatTypes[info.value] = "Valentine";
	GHI_MatNames[info.value] = info.text;
	info.func       = GHI_MatDDClick;
	UIDropDownMenu_AddButton(info);	
	
	
end

function GHI_MatDDClick()
	
	GHI_MatType = this.value;
	local material = GHI_MatTypes[this.value];
	--GHI_CreateItemsFrameMatTextLabel:SetText(MatType);
	GHI_ItemTextEditFrameSideFrameMatDropDownTextLabel:SetText(GHI_MatNames[this.value]);
	
	if not GHI_EditID  then return; end
	
	local rc = GHI_GetRightClickInfo(GHI_EditID);
	local orig = nil;
	if (type(rc)=="table") and rc.Type == "multible" then
		orig = rc;
		rc = orig[orig.book_index];
	end
	
	rc.material = material;
	
	if orig then
		orig[orig.book_index] = rc;
		rc = orig;
	end
	GHI_SetRightClickInfo(GHI_EditID,rc);
	
	GHI_CurrentMaterial = material;
	
	GHI_BookSetEditMaterial(material)
end

function GHI_FontDD_Update()

	

	for i = 1,table.getn(GHI_Fonts) do
		info            = {};
		info.text       = GHI_Fonts[i].name;
		info.value      = i;
		info.func       = GHI_FontDDClick;
		UIDropDownMenu_AddButton(info);	
	end
	
	
	
	
	
end

function GHI_FontDDClick()
	
	local index = this.value;
	
	
	GHI_ItemTextEditFrameSideFrameFontDropDownTextLabel:SetText(GHI_Fonts[index].name);
	
	if not GHI_EditID  then return; end
	
	local font = GHI_Fonts[index].path;
	local rc = GHI_GetRightClickInfo(GHI_EditID);
	local orig = nil;
	if (type(rc)=="table") and rc.Type == "multible" then
		orig = rc;
		rc = orig[orig.book_index];
	end
	

	rc.font = font;
	
	if orig then
		orig[orig.book_index] = rc;
		rc = orig;
	end
	GHI_SetRightClickInfo(GHI_EditID,rc);
	
	GHI_ItemTextPageEdit:SetFont(font,15);
end


function GHI_UpdateBookLinks(page,deleted)
--GHI_CurrentBook[GHI_CurrentBookPage]
	if type(GHI_CurrentBook) == "table" then
		for i=1,table.getn(GHI_CurrentBook) do
			local text = GHI_CurrentBook[i];
			local PageText = "";
			local textType = type(text);
			if textType == "string" then
				PageText = text;
			elseif textType == "table" then
				if text.text1 then
					PageText = PageText..text.text1;
				end
				if text.text2 then
					PageText = PageText..text.text2;
				end
				if text.text3 then
					PageText = PageText..text.text3;
				end
				if text.text4 then
					PageText = PageText..text.text4;
				end
				if text.text5 then
					PageText = PageText..text.text5;
				end
				if text.text6 then
					PageText = PageText..text.text6;
				end
				if text.text7 then
					PageText = PageText..text.text7;
				end
				if text.text8 then
					PageText = PageText..text.text8;
				end
				if text.text9 then
					PageText = PageText..text.text9;
				end
				if text.text10 then
					PageText = PageText..text.text10;
				end
			end
			local t = PageText;
			local a = 0;
			local b,n;
			local changed = false;
			while a do
				a = strfind(t,"<A href=\"",a+8);
				if a then
					b = strfind(t,"\">",a);
					n = strsub(t,a+9,b-1);
					if n and tonumber(n) then
						n = tonumber(n);
						if n >= page then
							if (deleted == true) then
								t = strsub(t,0,a+8)..(n-1)..strsub(t,b);
							else
								t = strsub(t,0,a+8)..(n+1)..strsub(t,b);
							end
							changed = true;
						end						
					end
				end
			end
			if changed == true then
				if textType == "string" then
					GHI_CurrentBook[i] = t;
				elseif textType == "table" then
					text = {};
					text.text1 = string.sub(t,0,127) 
					text.text2 = string.sub(t,128,255) 
					text.text3 = string.sub(t,256,383) 
					text.text4 = string.sub(t,384,511) 
					text.text5 = string.sub(t,512,639) 
					text.text6 = string.sub(t,640,767) 
					text.text7 = string.sub(t,768,895) 
					text.text8 = string.sub(t,896,1023) 
					text.text9 = string.sub(t,1024,1151) 
					text.text10 = string.sub(t,1152,1279)
					GHI_CurrentBook[i] = text;
				end
			end			
		end
	end
end

--	======================	Icon in text		=========================
-- 	Icon Code example: 	<Icon,128,R>	number 128, aligned to the right

GHI_IconsInPage = {};
GHI_IconsInPage.state = 0;
GHI_IconsInPage.buffer = false;

function GHI_CheckForIcons(text,material)
	for i = 1,5 do
		getglobal("GHI_Logo"..i):Hide();
	end

	
	GHI_IconsInPage = {};
		
	for i = 1,5 do
		local a,b = strfind(text,"<Icon,");
		if a and b then
			local c = strfind(text,">",b);
			if c then
				local list = {};
				local data = string.sub(text,b+1,c-1);
				local num, align = strsplit(",",data);
							
				list.position = a;
				list.num = num;
				list.align = align;
				GHI_IconsInPage[i] = list;
				
				text = string.sub(text,0,a-1)..strsub(text,c+1);
			end	

		end
	end
	
	GHI_IconsInPage.text = text;
	GHI_IconsInPage.material = material;
	GHI_IconsInPage.state = 0;
	
	if GHI_IconsInPage[1] then
		GHI_SendLineCalculation(1);
	else
		GHI_IconsInPage.state = 0
		GHI_ItemTextPageText:SetText(GHI_IconsInPage.text);
		
		GHI_InsertIcons();
	end
end


function GHI_SendLineCalculation(x)
	GHI_IconsInPage.buffer = false;
	local finalText = GHI_IconsInPage.text;
	local a;
	local font,fontSize = GHI_ItemTextPageText:GetFont();
	if not(fontSize) then return end
	fontSize = tonumber(fontSize);
	if not(fontSize) then return end
	
	local lines = floor((355 / fontSize)+1)
	local rest = lines - (355 / fontSize);
	
		
	local emptyPageText = "";
	for i = 1,lines do
		emptyPageText = emptyPageText.."<BR/>"
	end
	local text = gsub(finalText,"</P></BODY></HTML>","");
	local pos = GHI_IconsInPage[x].position;
	
	if not pos then return end
	
	text = strsub(text,0,pos-1);
	
	text = text..emptyPageText.."end".."</P></BODY></HTML>";
	GHI_ItemTextPageText:SetText(text); 
	GHI_ItemTextFrameScrollFrame:UpdateScrollChildRect();
	GHI_IconsInPage.state = x;
end

function GHI_RecieveLineCalculation(x)
	GHI_IconsInPage.buffer = false;
	local a = GHI_ItemTextFrameScrollFrame:GetVerticalScrollRange();
	GHI_IconsInPage[x].ypos = a;
	
	if x < 5 and GHI_IconsInPage[x+1] then
		--GHI_SendLineCalculation(x+1);
		GHI_SendLineCalculationBuffer(x+1);
	else
		GHI_IconsInPage.state = 0
		GHI_ItemTextPageText:SetText(GHI_IconsInPage.text);
		GHI_InsertIcons();
	end
end

function GHI_SendLineCalculationBuffer(x)
	local text = "";
	for i = 1,40 do
		text = text.."<BR/>"
	end
	GHI_IconsInPage.state = x;
	GHI_ItemTextPageText:SetText("<HTML><BODY><P>"..text.."</P></BODY></HTML>");
	
	GHI_ItemTextFrameScrollFrame:UpdateScrollChildRect();
	GHI_IconsInPage.buffer = true;
	
end

function GHI_RecieveLineCalculationBuffer(x)
	GHI_IconsInPage.buffer = false;
	GHI_SendLineCalculation(x);
	
end


function GHI_InsertIcons()
	for i = 1,5 do
		local data = GHI_IconsInPage[i];
		if type(data) == "table" then
			local num = data.num;
			local align = string.lower(data.align);
			local ypos = data.ypos;
			local material = GHI_IconsInPage.material;
			
			if ( not material ) then
				material = "Parchment";
			end
			
			local TL = getglobal("GHI_Logo"..i.."TopLeft");
			local TR = getglobal("GHI_Logo"..i.."TopRight");
			local BL = getglobal("GHI_Logo"..i.."BottomLeft");
			local BR = getglobal("GHI_Logo"..i.."BottomRight");
			
			TL:SetTexture("Textures\\GuildEmblems\\Emblem_"..num.."_16_TU_U");
			TR:SetTexture("Textures\\GuildEmblems\\Emblem_"..num.."_16_TU_U");
			BL:SetTexture("Textures\\GuildEmblems\\Emblem_"..num.."_16_TL_U");
			BR:SetTexture("Textures\\GuildEmblems\\Emblem_"..num.."_16_TL_U");
			
			local logo = getglobal("GHI_Logo"..i);
			logo:ClearAllPoints();
			if	align == "r" then
				logo:SetPoint("RIGHT", GHI_ItemTextPageText, "TOPRIGHT", 25, -ypos);
			elseif align == "c" then
				logo:SetPoint("CENTER", GHI_ItemTextPageText, "TOP", 0, -ypos);
			else
				logo:SetPoint("LEFT", GHI_ItemTextPageText, "TOPLEFT", -25, -ypos);
			end
			
			
			logo:SetParent(GHI_ItemTextPageText);
			
			--local textColor = GHI_IconColor[material];
			local textColor = GetMaterialTextColors(material);
			--GHI_Message("Inserting color ("..material.."): "..textColor[1]..", "..textColor[2]..", "..textColor[3]);
			TL:SetVertexColor(textColor[1], textColor[2], textColor[3]);
			TR:SetVertexColor(textColor[1], textColor[2], textColor[3]);
			BL:SetVertexColor(textColor[1], textColor[2], textColor[3]);
			BR:SetVertexColor(textColor[1], textColor[2], textColor[3]);
			--GHI_Message("Showing "..i);
			logo:Show();
		else
			getglobal("GHI_Logo"..i):Hide();
		end
	end
end


GHI_AlignType = 1;
GHI_AlignTypes = {}
function GHI_AlignDD_Update()

	info            = {};
	info.text       = "Left";
	info.value      = 1;
	GHI_AlignTypes[info.value] = info.text;
	info.func       = GHI_AlignDDClick;
	UIDropDownMenu_AddButton(info);	

	
	info            = {};
	info.text       = "Center";
	info.value      = 2;
	GHI_AlignTypes[info.value] = info.text;
	info.func       = GHI_AlignDDClick;
	UIDropDownMenu_AddButton(info);	
	
	info            = {};
	info.text       = "Right";
	info.value      = 3;
	GHI_AlignTypes[info.value] = info.text;
	info.func       = GHI_AlignDDClick;
	UIDropDownMenu_AddButton(info);	
	
	
end

function GHI_AlignDDClick()
	
	GHI_AlignType = this.value;
	local Align = GHI_AlignTypes[this.value];
	GHI_LogoChooseFrameAlignDropDownTextLabel:SetText(Align);
	
end

function GHI_IconBoxOnOk()
	local align = string.upper(GHI_AlignTypes[GHI_AlignType]);
	if not(align) then
		align = "L";
	else
		align = string.sub(align,0,1);
	end
	
	
	local slider = getglobal(this:GetParent():GetName().."Slider")
	local num = 10;
	if slider then 
		num = tonumber(slider:GetValue());
	end
	if not(num) then num = 10 end
	
	
	GHI_ItemTextPageEdit:Insert("<Icon,"..num..","..align..">");
end
	 

	 
	 
-- transcribe
function GHI_TranscribeTextItem()
	
	local t1 = ItemTextGetText();
	local p = 0;
	for i=1,900 do
		ItemTextPrevPage();
		if (ItemTextGetText() == t1 ) then
			break;
		else
			t1 = ItemTextGetText();
			p = p - 1;
		end
	end
	
	local creator = ItemTextGetCreator();
	local title = ItemTextGetItem();
		
	if p == 0 and not(ItemTextHasNextPage()) then
		
		local text = GHI_StringToHtml(ItemTextGetText());
		local mat = ItemTextGetMaterial();
		local name,icon,quality,white1,white2,comment,amount,stackSize,copyable,rightClick,rightClicktext,editID,duration,durationWhenTrade,durationRealTime;
		name = title;
		
		if mat == "Parchment" or not(mat) then
			icon = "Interface\\Icons\\INV_Misc_Note_01";
			white1 = GHI_LETTER;
			rightClicktext = GHI_READ_LETTER;
		else
			icon = "Interface\\Icons\\INV_Misc_Note_06";
			white1 = GHI_INSCRIPTION;
			rightClicktext = GHI_READ_INCRIPTION;
		end
		
		
		quality = 1;
		
		if creator then
			white2 = GHI_FROM.." "..creator;
		else
			white2 = "";
		end
		amount = 1;
		stackSize = 1;
		duration = 0;
		
		rightClick = {};
		rightClick[1] = {};
		rightClick[1].Type = "book";
		rightClick[1].type_name = "Book";
		rightClick[1].pages = 1;
		rightClick[1].material = mat;
		rightClick[1].title = title;		
		rightClick[1].icon = "Interface\\Icons\\INV_Misc_Book_09";
		rightClick[1].req = 1;
		rightClick[1][1] = {};
		rightClick[1][1].text1 = text;
		rightClick.book_index = 1;
		rightClick.CD = 1;
		rightClick.Type = "multible";

		GHI_CreateItem(name,icon,quality,white1,white2,comment,amount,stackSize,copyable,rightClick,rightClicktext,editID,duration,durationWhenTrade,durationRealTime)
		GHI_Message(white1.." "..GHI_TRANSCRIBED..".");
	else
		local text = {};
		local c = 1;
		text[c] = GHI_StringToHtml(ItemTextGetText());
		
		while (ItemTextHasNextPage()) do
			ItemTextNextPage()
			c = c + 1;
			p = p + 1;
			text[c] = GHI_StringToHtml(ItemTextGetText());
		end
		
		while (p > 0) do
			ItemTextPrevPage();
			p = p - 1;
		end
		
		local name,icon,quality,white1,white2,comment,amount,stackSize,copyable,rightClick,rightClicktext,editID,duration,durationWhenTrade,durationRealTime;
		name = title;
		icon = "Interface\\Icons\\INV_Misc_Book_08";
		quality = 1;
		white1 = "Book"
		if GetMinimapZoneText()   then
			white2 = "Found in "..GetMinimapZoneText();
		else
			white2 = "";
		end
		amount = 1;
		stackSize = 1;
		duration = 0;
		rightClicktext = "Read the book.";
		rightClick = {};
		rightClick[1] = {};
		rightClick[1].Type = "book";
		rightClick[1].type_name = "Book";
		rightClick[1].pages = table.getn(text);
		rightClick[1].title = title;		
		rightClick[1].icon = "Interface\\Icons\\INV_Misc_Book_09";
		rightClick[1].req = 1;
		for i=1,table.getn(text) do
			rightClick[1][i] = {};
			rightClick[1][i].text1 = text[i];
		end
		rightClick.book_index = 1;
		rightClick.CD = 1;
		rightClick.Type = "multible";

		GHI_CreateItem(name,icon,quality,white1,white2,comment,amount,stackSize,copyable,rightClick,rightClicktext,editID,duration,durationWhenTrade,durationRealTime)
		GHI_Message("Book Transcribed.");
	end
	
	
end

function GHI_TranscribeMailboxLetter()
	
	local t = OpenMailBodyText:GetText();
	
	
	local creator = OpenMailSender:GetText();
	local title = OpenMailSubject:GetText();
		
	
		
	local text = GHI_StringToHtml(t);
	local mat = ItemTextGetMaterial();
	local name,icon,quality,white1,white2,comment,amount,stackSize,copyable,rightClick,rightClicktext,editID,duration,durationWhenTrade,durationRealTime;
	name = title;
	
	if mat == "Parchment" or not(mat) then
		icon = "Interface\\Icons\\INV_Misc_Note_01";
		white1 = "Letter"
		rightClicktext = "Read the letter";
	else
		icon = "Interface\\Icons\\INV_Misc_Note_06";
		white1 = "Inscription"
		rightClicktext = "Read the inscription";
	end
	
	
	quality = 1;
	
	if creator then
		white2 = "From "..creator.." "..date("%d/%m/%y");
	else
		white2 = "";
	end
	amount = 1;
	stackSize = 1;
	duration = 0;
	
	rightClick = {};
	rightClick[1] = {};
	rightClick[1].Type = "book";
	rightClick[1].type_name = "Book";
	rightClick[1].pages = 1;
	rightClick[1].material = mat;
	rightClick[1].title = title;		
	rightClick[1].icon = "Interface\\Icons\\INV_Misc_Book_09";
	rightClick[1].req = 1;
	rightClick[1][1] = {};
	rightClick[1][1].text1 = text;
	rightClick.book_index = 1;
	rightClick.CD = 1;
	rightClick.Type = "multible";

	GHI_CreateItem(name,icon,quality,white1,white2,comment,amount,stackSize,copyable,rightClick,rightClicktext,editID,duration,durationWhenTrade,durationRealTime)
	GHI_Message(white1.." Transcribed.");
	
	
	
end
 
