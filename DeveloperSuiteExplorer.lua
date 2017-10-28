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
    "Function",
    "Table",
    "Userdata",
    "Number",
    "String",
    "Boolean",
}

local DeveloperSuite_Explorer = ZO_SortFilterList:Subclass()

function DeveloperSuite_Explorer:New(...)
    return ZO_SortFilterList.New(self, ...)
end

function DeveloperSuite_Explorer:Initialize(control, savedVars)
    DeveloperSuite_TopLevelControl_Initialize(self, control, savedVars)

    ZO_SortFilterList.Initialize(self, control)

    local function setupRow(...)
        self:SetupRow(...)
    end
    ZO_ScrollList_AddDataType(self.list, ENTRY_DATA, "DeveloperSuite_ExplorerRow", ROW_HEIGHT, setupRow)

    self.searchQueryEditBox = self.control:GetNamedChild("SearchQueryEditBox")
    self.searchTypesControl = self.control:GetNamedChild("SearchTypes")

    self:SetupSearchQuery()
    self:SetupSearchTypes()
    self:RefreshData()
end

function DeveloperSuite_Explorer:SetupSearchQuery()
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

function DeveloperSuite_Explorer:SetupSearchTypes()
    local previousTypeButton
    for _, typeName in ipairs(TYPES) do
        local typeButtonName = "$(parent)"..typeName.."CheckButton"
        local typeButton = CreateControlFromVirtual(typeButtonName, self.searchTypesControl, "DeveloperSuite_CheckButton")
        local typeKey = string.lower(typeName)

        ZO_CheckButton_SetLabelText(typeButton, typeName)
        ZO_CheckButton_SetCheckState(typeButton, self.savedVars.search.types[typeKey])
        local function toggleFunction(_, state)
            self.savedVars.search.types[typeKey] = state
            self:RefreshData()
        end
        ZO_CheckButton_SetToggleFunction(typeButton, toggleFunction)

        if previousTypeButton then
            typeButton:SetAnchor(LEFT, previousTypeButton.label, RIGHT, 24, 0)
        else
            typeButton:SetAnchor(LEFT, self.searchTypesControl, LEFT, 8, 0)
        end
        previousTypeButton = typeButton
    end
end

function DeveloperSuite_Explorer:BuildMasterList()
    if (not self.masterList) then
        self.masterList = {}

        for name, value in zo_insecurePairs(_G) do
            local t =
            {
                slug = string.lower(name),
                name = name,
                type = type(value),
                value = tostring(value),
            }
            table.insert(self.masterList, t)
        end
    end
end

function DeveloperSuite_Explorer:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    local query = self.savedVars.search.query
    -- local time = GetGameTimeMilliseconds()

    for i = 1, #self.masterList do
        local entry = self.masterList[i]

        local matchType = self.savedVars.search.types[entry.type]
        local matchName = string.find(entry.slug, query)
        if matchType and (matchName or string.len(query) == 0) then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ENTRY_DATA, entry))
        end

        -- Limit at 1000 rows.
        if #scrollData >= 1000 then
            break
        end
    end
    -- df("Found %d results in %dms (%.2fMB)", #scrollData, GetGameTimeMilliseconds() - time, collectgarbage("count") / 1024)
end

function DeveloperSuite_Explorer:CompareRows(row1, row2)
    return row1.data.slug < row2.data.slug
end

function DeveloperSuite_Explorer:SortScrollList()
    -- local time = GetGameTimeMilliseconds()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    table.sort(scrollData, function(...) return self:CompareRows(...) end)
    -- df("Sorted %d results in %dms (%.2fMB)", #scrollData, GetGameTimeMilliseconds() - time, collectgarbage("count") / 1024)
end

function DeveloperSuite_Explorer:GetRowColors(data)
    -- if (data.type == "string") then
    --     return ZO_ColorDef:New("FFAAAA")
    -- elseif (data.type == "number") then
    --     return ZO_ColorDef:New("AAAAFF")
    -- elseif (data.type == "table") then
    --     return ZO_ColorDef:New("FFFFAA")
    -- elseif (data.type == "userdata") then
    --     return ZO_ColorDef:New("AAFFAA")
    -- elseif (data.type == "function") then
    --     return ZO_ColorDef:New("FFAAFF")
    -- elseif (data.type == "boolean") then
    --     return ZO_ColorDef:New("FFFFAA")
    -- end
    return ZO_ColorDef:New("FFFFFF")
end

function DeveloperSuite_Explorer:SetupRow(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)

    local nameLabel = control:GetNamedChild("Name")
    nameLabel:SetText(data.name)
    nameLabel:SetCursorPosition(0)

    local valueLabel = control:GetNamedChild("Value")
    valueLabel:SetText(data.value)
    valueLabel:SetMouseEnabled(true)
    local function onMouseDown()
        DEVELOPER_SUITE_CONSOLE:Show()
        DEVELOPER_SUITE_CONSOLE:Run(data.name)
    end
    valueLabel:SetHandler("OnMouseDown", onMouseDown)
    
    local background = control:GetNamedChild("BG")
    background:SetHidden((data.sortIndex % 2) > 0)
end

function DeveloperSuite_Explorer:Toggle()
    DeveloperSuite_TopLevelControl_Toggle(self.control, self.searchQueryEditBox)
end

--
--
--

local function OnAddOnLoaded(savedVars)
    DEVELOPER_SUITE_EXPLORER = DeveloperSuite_Explorer:New(DeveloperSuite_ExplorerTopLevelControl, savedVars.explorer)
    SLASH_COMMANDS["/explorer"] = function()
        DEVELOPER_SUITE_EXPLORER:Toggle()
    end
end
CALLBACK_MANAGER:RegisterCallback(NAMESPACE.."_OnAddOnLoaded", OnAddOnLoaded)
