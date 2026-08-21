-- Turtle WoW / Vanilla 1.12 GHI action-bar overlay compatibility.
--
-- Historical GHI did not provide a separate action bar.  It overlaid GHI
-- item buttons directly on Blizzard's four MultiActionBars, allowing a slot
-- to contain either the normal Blizzard action or a GHI item reference.
-- Empty GHI overlays stay hidden during normal play and are shown only while
-- a GHI item is being dragged so the player can choose a destination slot.

GHI_ActionBarData = GHI_ActionBarData or {};

function GHI_GetActionBarData(bar, slot)
    bar = tonumber(bar);
    slot = tonumber(slot);
    if not bar or not slot or bar < 1 or bar > 11 or slot < 1 or slot > 12 then
        return nil;
    end
    if type(GHI_ActionBarData) ~= "table" then
        GHI_ActionBarData = {};
    end
    if type(GHI_ActionBarData[bar]) ~= "table" then
        GHI_ActionBarData[bar] = {};
    end
    return GHI_ActionBarData[bar][slot];
end

function GHI_SetActionBarData(bar, slot, id)
    bar = tonumber(bar);
    slot = tonumber(slot);
    if not bar or not slot or bar < 1 or bar > 11 or slot < 1 or slot > 12 then
        return nil;
    end
    if type(GHI_ActionBarData) ~= "table" then
        GHI_ActionBarData = {};
    end
    if type(GHI_ActionBarData[bar]) ~= "table" then
        GHI_ActionBarData[bar] = {};
    end
    GHI_ActionBarData[bar][slot] = id;
end

-- Original GHI bar/page mapping.
GHI_Barnames = GHI_Barnames or {};
GHI_Barnames[6] = "GHIMultiBarBottomLeft";
GHI_Barnames[5] = "GHIMultiBarBottomRight";
GHI_Barnames[3] = "GHIMultiBarRight";
GHI_Barnames[4] = "GHIMultiBarLeft";

local barDefinitions = {
    { bar = 6, nativePrefix = "MultiBarBottomLeftButton", overlayPrefix = "GHIMultiBarBottomLeftButton" },
    { bar = 5, nativePrefix = "MultiBarBottomRightButton", overlayPrefix = "GHIMultiBarBottomRightButton" },
    { bar = 3, nativePrefix = "MultiBarRightButton", overlayPrefix = "GHIMultiBarRightButton" },
    { bar = 4, nativePrefix = "MultiBarLeftButton", overlayPrefix = "GHIMultiBarLeftButton" },
};

local overlays = {};
local showingDropTargets = false;

local function GetOverlayIcon(button)
    if not button then return nil; end
    return button.icon;
end

local function SetOverlayVisual(button, id, dropTarget)
    if not button then return; end

    local icon = GetOverlayIcon(button);
    local name, texture;
    if id then
        name, texture = GHI_GetItemInfo(id);
        if not name then
            GHI_SetActionBarData(button.GHIBar, button.GHISlot, nil);
            id = nil;
            button.itemID = nil;
        end
    end

    if id then
        button.itemID = id;
        if icon then
            icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark");
            icon:Show();
        end
        if button.border then button.border:Show(); end
        button:Show();
    elseif dropTarget then
        button.itemID = nil;
        if icon then icon:Hide(); end
        if button.border then button.border:Show(); end
        button:Show();
    else
        button.itemID = nil;
        if icon then icon:Hide(); end
        if button.border then button.border:Hide(); end
        button:Hide();
    end
end

local function UpdateOverlay(button, forceDropTarget)
    if not button then return; end
    local native = button.nativeButton;
    if not native or not native:IsShown() then
        button:Hide();
        return;
    end

    local id = GHI_GetActionBarData(button.GHIBar, button.GHISlot);
    SetOverlayVisual(button, id, forceDropTarget and true or false);
end

local function RefreshAll(forceDropTargets)
    local i;
    for i = 1, table.getn(overlays) do
        UpdateOverlay(overlays[i], forceDropTargets);
    end
end

local function PlaceCursorItemOnOverlay(button)
    local cursorType, details = GHI_GetCursor();
    if cursorType ~= "item" and cursorType ~= "item/ability" then
        return false;
    end
    if type(details) ~= "table" or not details.id then
        return false;
    end

    GHI_SetActionBarData(button.GHIBar, button.GHISlot, details.id);
    button.itemID = details.id;
    GHI_ResetCursor();
    showingDropTargets = false;
    RefreshAll(false);
    return true;
end

local function PickupOverlayItem(button)
    local id = GHI_GetActionBarData(button.GHIBar, button.GHISlot);
    if not id then return; end

    local name, icon = GHI_GetItemInfo(id);
    if not name then
        GHI_SetActionBarData(button.GHIBar, button.GHISlot, nil);
        RefreshAll(false);
        return;
    end

    GHI_SetActionBarData(button.GHIBar, button.GHISlot, nil);
    local details = {};
    details.id = id;
    details.iconTexture = icon;
    GHI_SetCursor("item/ability", details);
    showingDropTargets = true;
    RefreshAll(true);
end

local function UseOverlayItem(button)
    local id = GHI_GetActionBarData(button.GHIBar, button.GHISlot);
    if not id then return; end

    local bag, slot = GHI_FindItem(id);
    if bag and slot then
        GHI_UseItem(bag, slot);
    else
        GHI_Message("The GHI item assigned to this action slot is no longer in your inventory.");
        GHI_SetActionBarData(button.GHIBar, button.GHISlot, nil);
        RefreshAll(false);
    end
end

local function Overlay_OnClick()
    local button = this;
    if not button then return; end

    if PlaceCursorItemOnOverlay(button) then
        return;
    end

    -- A populated GHI overlay replaces the Blizzard action in that slot.
    -- Left/right click both use the GHI item, matching the old action-slot
    -- behavior closely enough for Vanilla while avoiding secure-button APIs.
    if button.itemID then
        UseOverlayItem(button);
    end
end

local function Overlay_OnDragStart()
    local button = this;
    if not button or not button.itemID then return; end
    PickupOverlayItem(button);
end

local function Overlay_OnReceiveDrag()
    if this then
        PlaceCursorItemOnOverlay(this);
    end
end

local function Overlay_OnEnter()
    local button = this;
    if not button or not button.itemID then return; end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
    GHI_ItemTooltip(button, button.itemID);
    GameTooltip:Show();
end

local function Overlay_OnLeave()
    GameTooltip:Hide();
end

local function CreateOverlay(nativeButton, bar, slot, overlayName)
    if not nativeButton then return nil; end

    local button = CreateFrame("Button", overlayName, nativeButton);
    button:SetAllPoints(nativeButton);
    button:SetFrameStrata(nativeButton:GetFrameStrata());
    button:SetFrameLevel(nativeButton:GetFrameLevel() + 3);
    button:SetID(slot);
    button.GHIBar = bar;
    button.GHISlot = slot;
    button.nativeButton = nativeButton;
    button:EnableMouse(true);
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
    button:RegisterForDrag("LeftButton");

    local icon = button:CreateTexture(overlayName.."Icon", "ARTWORK");
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3);
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3);
    icon:SetTexCoord(0.06, 0.94, 0.06, 0.94);
    button.icon = icon;

    -- This is the only visible frame when a GHI item is assigned, or while
    -- dragging a GHI item.  It is anchored to the native action button rather
    -- than forming a second row above it.
    local border = button:CreateTexture(overlayName.."Border", "OVERLAY");
    border:SetAllPoints(button);
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2");
    button.border = border;

    button:SetScript("OnClick", Overlay_OnClick);
    button:SetScript("OnDragStart", Overlay_OnDragStart);
    button:SetScript("OnReceiveDrag", Overlay_OnReceiveDrag);
    button:SetScript("OnEnter", Overlay_OnEnter);
    button:SetScript("OnLeave", Overlay_OnLeave);

    button:Hide();
    table.insert(overlays, button);
    return button;
end

function GHI_ActionbarHookings()
    if table.getn(overlays) > 0 then
        RefreshAll(false);
        return;
    end

    local d, slot;
    for d = 1, table.getn(barDefinitions) do
        local def = barDefinitions[d];
        for slot = 1, 12 do
            local nativeButton = getglobal(def.nativePrefix..slot);
            if nativeButton then
                CreateOverlay(nativeButton, def.bar, slot, def.overlayPrefix..slot);
            end
        end
    end

    showingDropTargets = false;
    RefreshAll(false);
end

function GHI_ShowAllActionbars()
    showingDropTargets = true;
    RefreshAll(true);
end

function GHI_HideUnusedActionbars()
    showingDropTargets = false;
    RefreshAll(false);
end

-- Compatibility entry points retained for the rest of historical GHI.
function GHI_ActionSlotButton_OnLoad() end
function GHI_ActionSlotButton_OnUpdate()
    if this and this.GHIBar then UpdateOverlay(this, showingDropTargets); end
end
function GHI_ActionSlotButton_OnEnter()
    Overlay_OnEnter();
end
function GHI_ActionSlotButton_OnClick(drag)
    if drag then Overlay_OnDragStart(); else Overlay_OnClick(); end
end
function GHI_ActionSlotButton_UpdateCooldown() end
