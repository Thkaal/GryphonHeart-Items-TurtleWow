GHU_Book = {}
GHU_Book.__index = GHU_Book;
GHU_Book.hooked ={};

-- 	standard
function GHU_Book:Create(varName)
		
	setglobal(varName,GHU_Book); 
	
	local obj = {}             -- our new object
	setmetatable(obj, getglobal(varName))  -- make GHU_Book handle lookup
	
	setglobal(varName,obj);
	
	obj:InitHooks(varName);  
end
	
function GHU_Book:Hook(funcName,varName)
	
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

function GHU_Book:InitHooks(varName)
	if not(self.isHooked) then
		local obj = getglobal(varName);
		
		self:Hook("CloseItemText",varName)
		self:Hook("ItemTextGetText",varName)
		self:Hook("ItemTextGetPage",varName)
		self:Hook("ItemTextGetCreator",varName)
		self:Hook("ItemTextGetItem",varName)
		self:Hook("ItemTextHasNextPage",varName)
		self:Hook("ItemTextGetMaterial",varName)
		self:Hook("ItemTextNextPage",varName)
		self:Hook("ItemTextPrevPage",varName)
		
		self.isHooked = true;
	end
end

--	Data
GHU_Book.shownBook = {};
function GHU_Book:SetBook(book)
	assert(type(book)=="table","Incorrect book format");
	GHU_Book.shownBook = book;
end

GHU_Book.shown = false;
GHU_Book.page = 1;
function GHU_Book:ShowBook()
	self.orig.CloseItemText();
	self.shown = true;
	self.page = 1;
	ItemTextFrame_OnEvent(ItemTextFrame,"ITEM_TEXT_BEGIN");
	ItemTextFrame_OnEvent(ItemTextFrame,"ITEM_TEXT_READY");
end

function GHU_Book:HideBook()
	self.shown = false;
end

function GHU_Book:IsShown()
	return self.shown;
end

function GHU_Book:GetText(page)
	return GHU_Book.shownBook[page] or "";
end

function GHU_Book:GetPage()
	return self.page or 1;
end



--	Hooks
function GHU_Book:CloseItemText()  
	self = gself; -- give self info for hooked functions
	self:HideBook();
	return self.orig.CloseItemText();
end

function GHU_Book:ItemTextGetPage()  
	self = gself;
	if (self:IsShown() == true) then
		return self:GetPage();
	end
	return self.orig.ItemTextGetPage();
end

function GHU_Book:ItemTextGetText()   
	self = gself;
	if (self:IsShown() == true) then
		return self:GetText(self:GetPage());
	end
	return self.orig.ItemTextGetText();
end

function GHU_Book:ItemTextGetCreator()  
	self = gself;
	if (self:IsShown() == true) then
		return nil;
	end
	return self.orig.ItemTextGetCreator();
end


function GHU_Book:ItemTextGetItem()  
	self = gself;
	if (self:IsShown() == true) then
		return GHU_Book.shownBook.title or "";
	end
	return self.orig.ItemTextGetItem();
end

function GHU_Book:ItemTextGetMaterial()  
	self = gself;
	if (self:IsShown() == true) then
		return GHU_Book.shownBook.material or nil;
	end
	return self.orig.ItemTextGetMaterial();
end

function GHU_Book:ItemTextHasNextPage()  
	self = gself;
	if (self:IsShown() == true) then
		return (self:GetPage() < table.getn(self.shownBook));
	end
	return self.orig.ItemTextHasNextPage();
end

function GHU_Book:ItemTextNextPage()  
	self = gself;
	if (self:IsShown() == true) then
		if self:ItemTextHasNextPage() == true then
			self.page = self.page+1;
			ItemTextFrame_OnEvent(ItemTextFrame,"ITEM_TEXT_READY");
			return;
		end
	end
	return self.orig.ItemTextNextPage();
end

function GHU_Book:ItemTextPrevPage()  
	self = gself;
	if (self:IsShown() == true) then
		if self.page > 1 then
			self.page = self.page-1;
			ItemTextFrame_OnEvent(ItemTextFrame,"ITEM_TEXT_READY");
			return;
		end
	end
	return self.orig.ItemTextPrevPage();
end

ItemTextPageText:SetFont("h1","Fonts\\MORPHEUS.ttf",22); 
ItemTextPageText:SetTextColor("h1",0.18,0.12,0.06);

ItemTextPageText:SetFont("h2","Fonts\\MORPHEUS.ttf",18); 
ItemTextPageText:SetTextColor("h2",0.18,0.12,0.06);
