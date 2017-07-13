-- Developer Suite
-- The MIT License © Arthur Corenzan

local NAMESPACE = "DeveloperSuite"

--
--
--

local ROW_HEIGHT = 28
local ENTRY_DATA = 1

local TYPES =
{
    "Texture",
    "Sound",
    "Font",
}

local DeveloperSuite_Library = ZO_SortFilterList:Subclass()

function DeveloperSuite_Library:New(...)
    return ZO_SortFilterList.New(self, ...)
end

function DeveloperSuite_Library:Initialize(control, savedVars)
    DeveloperSuite_TopLevelControl_Initialize(self, control, savedVars)

    ZO_SortFilterList.Initialize(self, control)

    -- self:SetAlternateRowBackgrounds(true)

    local function setupRow(...)
        self:SetupRow(...)
    end
    ZO_ScrollList_AddDataType(self.list, ENTRY_DATA, "DeveloperSuite_LibraryRow", ROW_HEIGHT, setupRow)

    local function onSelectionChanged(...)
        self:OnSelectionChanged(...)
    end
    ZO_ScrollList_EnableSelection(self.list, "ZO_ThinListHighlight", onSelectionChanged)
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
    ZO_ScrollList_SetDeselectOnReselect(self.list, false)

    self.searchQueryEditBox = self.control:GetNamedChild("SearchQueryEditBox")
    self.searchTypeComboBox = self.control:GetNamedChild("SearchTypeComboBox")
    self.previewControl = self.control:GetNamedChild("Preview")
    self.previewTexture = self.control:GetNamedChild("PreviewTexture")
    self.previewEditBox = self.control:GetNamedChild("PreviewEditBox")

    self:SetupSearchQuery()
    self:SetupSearchType()
    self:TogglePreview()
    self:RefreshData()
end

function DeveloperSuite_Library:SetupSearchQuery()
    self.searchQueryEditBox:SetText(self.savedVars.search.query)
    local function onTextChanged()
        local query = self.searchQueryEditBox:GetText()
        if pcall(string.find, "", query) then
            self.savedVars.search.query = query
            self:RefreshData()
        end
    end
    self.searchQueryEditBox:SetHandler("OnTextChanged", onTextChanged)
end

function DeveloperSuite_Library:SetupSearchType()
    self.searchTypeComboBox = ZO_ComboBox_ObjectFromContainer(self.searchTypeComboBox)
    self.searchTypeComboBox:SetSortsItems(false)

    local selectedIndex = 1
    local options = {}
    for i, typeName in ipairs(TYPES) do
        local typeKey = string.lower(typeName)

        local function onSelected()
            self.savedVars.search.type = typeKey
            self:TogglePreview()
            self:RefreshData()
        end
        local item = self.searchTypeComboBox:CreateItemEntry(typeName, onSelected)

        self.searchTypeComboBox:AddItem(item)

        if self.savedVars.search.type == typeKey then
            selectedIndex = i
        end
    end
    self.searchTypeComboBox:SelectItemByIndex(selectedIndex)
end

function DeveloperSuite_Library:TogglePreview()
    if self.savedVars.search.type == "texture" then
        self.previewControl:SetHidden(false)
    else
        self.previewControl:SetHidden(true)
    end
end

function DeveloperSuite_Library:BuildMasterList()
    if (not self.masterTextureList) then
        self.masterTextureList = {}
        for _, path in ipairs(TEXTURES) do
            local name = string.gsub(path, ".+/", "", 1)
            local t =
            {
                name = name,
                path = path,
                slug = string.lower(path),
                type = "texture",
            }

            table.insert(self.masterTextureList, t)
        end
    end

    if (not self.masterSoundList) then
        self.masterSoundList = {}
        for _, name in pairs(SOUNDS) do
            local t =
            {
                name = name,
                slug = string.lower(name),
                type = "sound",
            }

            table.insert(self.masterSoundList, t)
        end
    end

    if (self.savedVars.search.type == "texture") then
        self.masterList = self.masterTextureList
    elseif (self.savedVars.search.type == "sound") then
        self.masterList = self.masterSoundList
    else
        self.masterList = {}
    end
end

function DeveloperSuite_Library:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    local query = string.lower(self.savedVars.search.query)
    local time = GetGameTimeMilliseconds()

    for i = 1, #self.masterList do

        local entry = self.masterList[i]

        if (query == "") or string.find(entry.slug, query) then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ENTRY_DATA, entry))
        end

        if (#scrollData >= 2000) then
            break
        end
    end
    df("Found %d results in %dms (%.2fMB)", #scrollData, GetGameTimeMilliseconds() - time, collectgarbage("count") / 1024)
end

function DeveloperSuite_Library:CompareRows(row1, row2)
    return row1.data.slug < row2.data.slug
end

function DeveloperSuite_Library:SortScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    table.sort(scrollData, function(...) return self:CompareRows(...) end)
end

function DeveloperSuite_Library:ClickRow(control)
    -- Allow reselection of the same row.
    ZO_ScrollList_SelectData(self.list, nil)
    self:SelectRow(control)
    self.searchQueryEditBox:TakeFocus()
end

function DeveloperSuite_Library:OnSelectionChanged(previouslySelected, selected)
    ZO_SortFilterList.OnSelectionChanged(self, previouslySelected, selected)

    if selected then
        if (selected.type == "texture") then
            self.previewTexture:SetTexture(selected.path)
            self.previewEditBox:SetText(selected.path)
            self.previewEditBox:SetCursorPosition(0)
        elseif (selected.type == "sound") then
            PlaySound(selected.name)
        end
    end
end

function DeveloperSuite_Library:GetRowColors(data)
    return ZO_ColorDef:New("FFFFFF")
end

function DeveloperSuite_Library:SetupRow(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)

    local nameLabel = control:GetNamedChild("Name")
    nameLabel:SetText(data.name)

    local background = control:GetNamedChild("BG")
    background:SetHidden((data.sortIndex % 2) > 0)
end

function DeveloperSuite_Library:Toggle()
    DeveloperSuite_TopLevelControl_Toggle(self.control, self.searchQueryEditBox)
end

--
--
--

function DeveloperSuite_LibraryRow_OnMouseEnter(control)
    DEVELOPER_SUITE_LIBRARY:EnterRow(control)
end

function DeveloperSuite_LibraryRow_OnMouseExit(control)
    DEVELOPER_SUITE_LIBRARY:ExitRow(control)
end

function DeveloperSuite_LibraryRow_OnMouseUp(control)
    DEVELOPER_SUITE_LIBRARY:ClickRow(control)
end

function DeveloperSuite_LibrarySearchQueryEditBox_OnDownArrow(control)
    if DEVELOPER_SUITE_LIBRARY.list.selectedDataIndex then
        ZO_ScrollList_SelectNextData(DEVELOPER_SUITE_LIBRARY.list)
    else
        ZO_ScrollList_TrySelectFirstData(DEVELOPER_SUITE_LIBRARY.list)
    end
end

function DeveloperSuite_LibrarySearchQueryEditBox_OnUpArrow(control)
    if DEVELOPER_SUITE_LIBRARY.list.selectedDataIndex then
        ZO_ScrollList_SelectPreviousData(DEVELOPER_SUITE_LIBRARY.list)
    else
        ZO_ScrollList_TrySelectLastData(DEVELOPER_SUITE_LIBRARY.list)
    end
end

--
--
--

local function OnAddOnLoaded(savedVars)
    DEVELOPER_SUITE_LIBRARY = DeveloperSuite_Library:New(DeveloperSuite_LibraryTopLevelControl, savedVars.library)
    SLASH_COMMANDS["/library"] = function()
        DEVELOPER_SUITE_LIBRARY:Toggle()
    end
end
CALLBACK_MANAGER:RegisterCallback(NAMESPACE.."_OnAddOnLoaded", OnAddOnLoaded)
