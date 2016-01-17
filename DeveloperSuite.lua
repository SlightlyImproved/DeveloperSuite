-- Developer Suite 0.2.0beta (Jan 17 2016)
-- Licensed under CC BY-NC-SA 4.0

local DEVELOPER_SUITE = "DeveloperSuite"
local VERSION = "Version 0.2.0beta (Jan 17 2016)"
--
--
--

function DeveloperSuite_TopLevelControl_Restore(self)
    if not (self.sv.offsetX == 0 and self.sv.offsetY == 0) then
        self.control:ClearAnchors()
        self.control:SetAnchor(TOPLEFT, nil, TOPLEFT, self.sv.offsetX, self.sv.offsetY)
    end
    self.control:SetDimensions(self.sv.x, self.sv.y)
    self.control:SetHidden(self.sv.hidden)
end

function DeveloperSuite_TopLevelControl_Initialize(self, control, sv)
    self.control = control
    self.sv = sv

    self.control:SetHandler("OnShow", function()
        self.sv.hidden = false
    end)

    self.control:SetHandler("OnHide", function()
        self.sv.hidden = true
    end)

    self.control:SetHandler("OnMoveStop", function()
        self.sv.offsetX = self.control:GetLeft()
        self.sv.offsetY = self.control:GetTop()
    end)

    self.control:SetHandler("OnResizeStop", function()
        self.sv.x = self.control:GetWidth()
        self.sv.y = self.control:GetHeight()
    end)

    DeveloperSuite_TopLevelControl_Restore(self)
end

function DeveloperSuite_TopLevelControl_Show(control)
    control:SetHidden(false)
    control:BringWindowToTop()
    SCENE_MANAGER:SetInUIMode(true)
end

function DeveloperSuite_TopLevelControl_Hide(control)
    control:SetHidden(true)
end

function DeveloperSuite_TopLevelControl_Toggle(control, editBox)
    if control:IsHidden() then
        DeveloperSuite_TopLevelControl_Show(control)

        if editBox then
            editBox:TakeFocus()
        end
    else
        if editBox then
            if editBox:HasFocus() then
                editBox:LoseFocus()
                DeveloperSuite_TopLevelControl_Hide(control)
            else
                DeveloperSuite_TopLevelControl_Show(control)
                editBox:TakeFocus()
            end
        else
            DeveloperSuite_TopLevelControl_Hide(self.control)
        end
    end
end

--
--
--

function DeveloperSuite_StateButton_ChangeState(control, state)
    if (not control.lockedState) then
        control.state = state
        control:SetAlpha(control.state and control.defaultAlpha or 0.35)
        if control.stateChangeFunction then control.stateChangeFunction(state) end
    end
end

function DeveloperSuite_StateButton_Initialize(control, defaultState)
    control.defaultAlpha = control:GetAlpha()
    control.lockedState = false
    DeveloperSuite_StateButton_ChangeState(control, defaultState)
end

function DeveloperSuite_StateButton_Toggle(control)
    DeveloperSuite_StateButton_ChangeState(control, not control.state)
end

function DeveloperSuite_StateButton_SetStateChangeFunction(control, func)
    control.stateChangeFunction = func
end

function DeveloperSuite_StateButton_UnlockState(control)
    control.lockedState = false
end

function DeveloperSuite_StateButton_LockState(control)
    control.lockedState = true
end

--
--
--

local About = ZO_Object:Subclass()

function About:New(...)
    local about = ZO_Object.New(self)
    about:Initialize(...)
    return about
end

function About:Initialize(control, sv)
    DeveloperSuite_TopLevelControl_Initialize(self, control, sv)

    SLASH_COMMANDS["/developersuite"] = function()
        self:Toggle()
    end
end

function About:Toggle()
    if self.control:IsHidden() then
        DeveloperSuite_TopLevelControl_Show(self.control)
    else
        DeveloperSuite_TopLevelControl_Hide(self.control)
    end
end


--
--
--

local function DeveloperSuite_Console_Dump(value, indent, history)
    indent = indent or ""
    history = history or {}

    local dump = ""
    local valueType = type(value)

    if (valueType == "table") then
        if not history[value] then
            dump = dump.."(table)\n"
            history[value] = true
            for k, v in pairs(value) do
                dump = dump..string.format("%s[%s] = %s", indent, tostring(k), DeveloperSuite_Console_Dump(v, indent.." ", history))
            end
        else
            dump = dump.."(redundant)\n"
        end
    elseif (valueType == "userdata") then
        dump = dump.."(userdata)\n"
    else
        dump = dump.."("..valueType..") "..tostring(value).."\n"
    end

    return dump..""
end

local Console = ZO_Object:Subclass()

function Console:New(...)
    local console = ZO_Object.New(self)
    console:Initialize(...)
    return console
end

function Console:Initialize(control, sv)
    DeveloperSuite_TopLevelControl_Initialize(self, control, sv)

    SLASH_COMMANDS["/console"] = function()
        self:Toggle()
    end

    local outputEditBox = GetControl(self.control, "Output")
    outputEditBox:SetText(self.sv.output)
    outputEditBox:SetHandler("OnTextChanged", function()
        self.sv.output = outputEditBox:GetText()
    end)

    local historyIndex = #self.sv.history + 1

    local inputEditBox = GetControl(self.control, "Input")
    inputEditBox:SetHandler("OnEnter", function()
        local source = inputEditBox:GetText()

        table.insert(self.sv.history, source)
        historyIndex = #self.sv.history + 1

        if source == "clear" then
            outputEditBox:SetText("")
        elseif source == "exit" then
            self:Toggle()
        else
            source = string.format("DEVELOPER_SUITE_CONSOLE:Output(function() return %s end)", source)
            local script = zo_loadstring(source)

            if script then
                script()
            end
        end

        inputEditBox:SetText("")
    end)

    inputEditBox:SetHandler("OnUpArrow", function()
        if (historyIndex > 1) then
            historyIndex = historyIndex - 1
            inputEditBox:SetText(self.sv.history[historyIndex])
        end
    end)

    inputEditBox:SetHandler("OnDownArrow", function()
        if (historyIndex <= #self.sv.history) then
            historyIndex = historyIndex + 1
            inputEditBox:SetText(self.sv.history[historyIndex])
        end
    end)
end

function Console:Output(mixed)
    local outputEditBox = GetControl(self.control, "Output")
    local history = outputEditBox:GetText()

    if type(mixed) == "function" then
        outputEditBox:SetText(history..DeveloperSuite_Console_Dump(mixed()))
    else
        outputEditBox:SetText(history..DeveloperSuite_Console_Dump(mixed))
    end
end

function Console:Toggle()
    local inputEditBox = GetControl(self.control, "Input")
    DeveloperSuite_TopLevelControl_Toggle(self.control, inputEditBox)
end

--
--
--

local EXPLORER_ROW_HEIGHT = 28
local EXPLORER_ENTRY_DATA = 1

local Explorer = ZO_SortFilterList:Subclass()

function Explorer:New(...)
    return ZO_SortFilterList.New(self, ...)
end

function Explorer:Initialize(control, sv)
    ZO_SortFilterList.Initialize(self, control)

    ZO_ScrollList_AddDataType(self.list, EXPLORER_ENTRY_DATA, "DeveloperSuiteExplorerRow", EXPLORER_ROW_HEIGHT, function(...) self:SetupRow(...) end)

    self:SetAlternateRowBackgrounds(true)

    DeveloperSuite_TopLevelControl_Initialize(self, control, sv)

    local searchEditBox = GetControl(control, "SearchEditBox")

    searchEditBox:SetText(sv.search.query)
    searchEditBox:SetHandler("OnTextChanged", function()
        self:RefreshData()
        sv.search.query = searchEditBox:GetText()
    end)

    local searchOptions =
    {
        "Function",
        "Table",
        "Number",
        "String",
        "Other",
    }

    for _, type in ipairs(searchOptions) do
        local control = GetControl(control, "SearchOption"..type.."Button")

        DeveloperSuite_StateButton_ChangeState(control, sv.search.options["include"..type])
        DeveloperSuite_StateButton_SetStateChangeFunction(control, function(state)
            sv.search.options["include"..type] = state
            self:RefreshData()
        end)
    end

    SLASH_COMMANDS["/explorer"] = function()
        self:Toggle()
    end

    self:RefreshData()
end

function Explorer:BuildMasterList()
    if (not self.masterList) then
        self.masterList = {}

        for name, value in zo_insecurePairs(_G) do
            local t =
            {
                name = name,
                type = type(value),
                value = tostring(value),
            }

            t.slug = string.lower(t.name)

            table.insert(self.masterList, t)
        end
    end
end

function Explorer:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    local query = string.lower(self.sv.search.query)

    if (#query >= 1) then
        -- local time = GetGameTimeMilliseconds()

        for i = 1, #self.masterList do
            local entry = self.masterList[i]
            local isMatch = true

            if (entry.type == "function") then
                isMatch = isMatch and self.sv.search.options.includeFunction
            elseif (entry.type == "table") or (entry.type == "userdata") then
                isMatch = isMatch and self.sv.search.options.includeTable
            elseif (entry.type == "number") then
                isMatch = isMatch and self.sv.search.options.includeNumber
            elseif (entry.type == "string") then
                isMatch = isMatch and self.sv.search.options.includeString
            else
                isMatch = isMatch and self.sv.search.options.includeOther
            end

            isMatch = isMatch and string.find(entry.slug, query, 1, true)

            if isMatch then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(EXPLORER_ENTRY_DATA, entry))
            end

            if #scrollData >= 1000 then
                break
            end
        end

        -- d(string.format("Filtered %d items in %dms (%.2fMB)", #scrollData, GetGameTimeMilliseconds() - time, collectgarbage("count") / 1024))
    end
end

function Explorer:SortScrollList()
    -- Too friggin' slow
end

function Explorer:GetRowColors(data)
    if (data.type == "string") then
        return ZO_ColorDef:New("ff8800")
    elseif (data.type == "number") then
        return ZO_ColorDef:New("00aaff")
    elseif (data.type == "table") then
        return ZO_ColorDef:New("ffff00")
    elseif (data.type == "userdata") then
        return ZO_ColorDef:New("4444ff")
    elseif (data.type == "function") then
        return ZO_ColorDef:New("ff00aa")
    elseif (data.type == "boolean") then
        return ZO_ColorDef:New("ff0000")
    else
        return ZO_ColorDef:New("888888")
    end
end

function Explorer:SetupRow(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)

    GetControl(control, "Name"):SetText(data.name)
    GetControl(control, "Name"):SetColor(self:GetRowColors(data):UnpackRGB())
    GetControl(control, "Name"):SetCursorPosition(0)
    GetControl(control, "Type"):SetText(data.type)

    GetControl(control, "Value"):SetText(data.value)
    GetControl(control, "Value"):SetMouseEnabled(true)
    GetControl(control, "Value"):SetHandler("OnMouseDown", function()
        SLASH_COMMANDS["/tbug"](data.name)
    end)
end

function Explorer:Toggle()
    local searchEditBox = GetControl(self.control, "SearchEditBox")
    DeveloperSuite_TopLevelControl_Toggle(self.control, searchEditBox)
end


--
--
--

local LIBRARY_ROW_HEIGHT = 28
local LIBRARY_ENTRY_DATA = 1

local Library = ZO_SortFilterList:Subclass()

function Library:New(...)
    return ZO_SortFilterList.New(self, ...)
end

function Library:Initialize(control, sv)
    ZO_SortFilterList.Initialize(self, control)

    ZO_ScrollList_AddDataType(self.list, LIBRARY_ENTRY_DATA, "DeveloperSuiteLibraryRow", LIBRARY_ROW_HEIGHT, function(...) self:SetupRow(...) end)

    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
    ZO_ScrollList_EnableSelection(self.list, "ZO_ThinListHighlight", function(...) self:OnSelectionChanged(...) end)
    ZO_ScrollList_SetDeselectOnReselect(self.list, false)

    self:SetAlternateRowBackgrounds(true)

    DeveloperSuite_TopLevelControl_Initialize(self, control, sv)

    local searchBox = GetControl(control, "SearchEditBox")

    searchBox:SetText(sv.search.query)
    searchBox:SetHandler("OnTextChanged", function()
        self:RefreshData()
        sv.search.query = searchBox:GetText()
    end)

    local texturePreview = GetControl(control, "Preview")

    local searchTypeTextureButton = GetControl(control, "SearchOptionTextureButton")
    local searchTypeSoundButton = GetControl(control, "SearchOptionSoundButton")

    DeveloperSuite_StateButton_SetStateChangeFunction(searchTypeTextureButton, function(state)
        if state then
            DeveloperSuite_StateButton_UnlockState(searchTypeSoundButton)
            DeveloperSuite_StateButton_ChangeState(searchTypeSoundButton, false)
            DeveloperSuite_StateButton_LockState(searchTypeTextureButton)
            texturePreview:SetHidden(false)
            sv.search.query = ""
            sv.search.type = "texture"
            searchBox:TakeFocus()
            self:RefreshData()
        end
    end)

    DeveloperSuite_StateButton_SetStateChangeFunction(searchTypeSoundButton, function(state)
        if state then
            DeveloperSuite_StateButton_UnlockState(searchTypeTextureButton)
            DeveloperSuite_StateButton_ChangeState(searchTypeTextureButton, false)
            DeveloperSuite_StateButton_LockState(searchTypeSoundButton)
            texturePreview:SetHidden(true)
            sv.search.query = ""
            sv.search.type = "sound"
            searchBox:TakeFocus()
            self:RefreshData()
        end
    end)

    DeveloperSuite_StateButton_ChangeState(searchTypeTextureButton, true)

    SLASH_COMMANDS["/library"] = function()
        self:Toggle()
    end

    self:RefreshData()
end

function Library:BuildMasterList()
    if (not self.masterTextureList) then
        self.masterTextureList = {}
        for _, name in ipairs(TEXTURES) do
            local t =
            {
                name = string.gsub(name, ".+\\", "", 1),
                path = name,
                slug = string.lower(name),
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

    if (self.sv.search.type == "texture") then
        self.masterList = self.masterTextureList
    elseif (self.sv.search.type == "sound") then
        self.masterList = self.masterSoundList
    else
        self.masterList = {}
    end
end

function Library:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    local query = string.lower(self.sv.search.query)

    for i = 1, #self.masterList do
        local entry = self.masterList[i]

        if (#scrollData > 1000) then
            break
        end

        if (query == "") or string.find(entry.slug, query, 1, true) then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(LIBRARY_ENTRY_DATA, entry))
        end

    end
end

function Library:SortScrollList()
end

function Library:Row_OnMouseEnter(control)
    self:EnterRow(control)
end

function Library:Row_OnMouseExit(control)
    self:ExitRow(control)
end

function Library:Row_OnMouseUp(control)
    -- Allow reselection of the same row
    ZO_ScrollList_SelectData(self.list, nil)
    self:SelectRow(control)
end

function Library:OnSelectionChanged(previouslySelected, selected)
    ZO_SortFilterList.OnSelectionChanged(self, previouslySelected, selected)

    if selected then
        if (selected.type == "texture") then
            local preview = GetControl(self.control, "PreviewTexture")
            local pathBox = GetControl(self.control, "PreviewPath")
            preview:SetTexture(selected.path)
            pathBox:SetText(selected.path)
        elseif (selected.type == "sound") then
            PlaySound(selected.name)
        end
    end
end

function Library:GetRowColors(data)
    return ZO_ColorDef:New("FFFFFF")
end

function Library:SetupRow(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)

    GetControl(control, "Name"):SetText(data.name)
end

function Library:Toggle()
    local searchBox = GetControl(self.control, "SearchEditBox")

    if self.control:IsHidden() then
        DeveloperSuite_TopLevelControl_Show(self.control)
        searchBox:TakeFocus()
    else
        if searchBox:HasFocus() then
            DeveloperSuite_TopLevelControl_Hide(self.control)
        else
            searchBox:TakeFocus()
            self.control:BringWindowToTop()
        end
    end
end

function DeveloperSuiteLibraryRow_OnMouseEnter(control)
    DEVELOPER_SUITE_LIBRARY:Row_OnMouseEnter(control)
end

function DeveloperSuiteLibraryRow_OnMouseExit(control)
    DEVELOPER_SUITE_LIBRARY:Row_OnMouseExit(control)
end

function DeveloperSuiteLibraryRow_OnMouseUp(control)
    DEVELOPER_SUITE_LIBRARY:Row_OnMouseUp(control)
end

function DeveloperSuiteLibrarySearchBox_OnDownArrow(control)
    if DEVELOPER_SUITE_LIBRARY.list.selectedDataIndex then
        ZO_ScrollList_SelectNextData(DEVELOPER_SUITE_LIBRARY.list)
    else
        ZO_ScrollList_TrySelectFirstData(DEVELOPER_SUITE_LIBRARY.list)
    end
end

function DeveloperSuiteLibrarySearchBox_OnUpArrow(control)
    if DEVELOPER_SUITE_LIBRARY.list.selectedDataIndex then
        ZO_ScrollList_SelectPreviousData(DEVELOPER_SUITE_LIBRARY.list)
    else
        ZO_ScrollList_TrySelectLastData(DEVELOPER_SUITE_LIBRARY.list)
    end
end

--
--
--

ZO_CreateStringId("SI_DEVELOPER_SUITE_VERSION", VERSION)
ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_LIBRARY", "Open/close Library")
ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_EXPLORER", "Open/close Explorer")
ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_CONSOLE", "Open/close Console")
ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_RELOADUI", "Reload interface")
ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_INSPECT_CONTROL", "Inspect control under cursor")

function DeveloperSuite_Binding_InspectControl()
    SLASH_COMMANDS["/tbug"]("moc()")
end

function DeveloperSuite_Binding_Reload()
    SLASH_COMMANDS["/reloadui"]()
end

function DeveloperSuite_Binding_Library()
    DEVELOPER_SUITE_LIBRARY:Toggle(true)
end

function DeveloperSuite_Binding_Explorer()
    DEVELOPER_SUITE_EXPLORER:Toggle(true)
end

function DeveloperSuite_Binding_Console()
    DEVELOPER_SUITE_CONSOLE:Toggle(true)
end

--
--
--

local defaultSavedVars =
{
    ["about"] =
    {
        ["hidden"] = false,
        ["x"] = 360,
        ["y"] = 160,
        ["offsetX"] = 0,
        ["offsetY"] = 0,
    },
    ["console"] =
    {
        ["hidden"] = true,
        ["x"] = 520,
        ["y"] = 320,
        ["offsetX"] = 0,
        ["offsetY"] = 0,
        ["output"] = "",
        ["history"] = {},
    },
    ["explorer"] =
    {
        ["hidden"] = true,
        ["x"] = 640,
        ["y"] = 320,
        ["offsetX"] = 0,
        ["offsetY"] = 0,
        ["search"] =
        {
            ["query"] = "",
            ["options"] =
            {
                ["includeFunction"] = true,
                ["includeTable"] = true,
                ["includeNumber"] = true,
                ["includeString"] = true,
                ["includeOther"] = true,
            }
        }
    },
    ["library"] =
    {
        ["hidden"] = true,
        ["x"] = 400,
        ["y"] = 640,
        ["offsetX"] = 0,
        ["offsetY"] = 0,
        ["search"] =
        {
            ["query"] = "",
            ["type"] = "texture"
        }
    },
}

EVENT_MANAGER:RegisterForEvent(DEVELOPER_SUITE, EVENT_ADD_ON_LOADED, function(event, addOnName)
    if (addOnName == DEVELOPER_SUITE) then
        EVENT_MANAGER:UnregisterForEvent(DEVELOPER_SUITE, EVENT_ADD_ON_LOADED)

        local sv = ZO_SavedVars:NewAccountWide("DeveloperSuiteSavedVars", 1, nil, defaultSavedVars)

        DEVELOPER_SUITE_ABOUT = About:New(DeveloperSuiteAbout, sv.about)
        DEVELOPER_SUITE_CONSOLE = Console:New(DeveloperSuiteConsole, sv.console)
        DEVELOPER_SUITE_EXPLORER = Explorer:New(DeveloperSuiteExplorer, sv.explorer)
        DEVELOPER_SUITE_LIBRARY = Library:New(DeveloperSuiteLibrary, sv.library)

        -- Free the chat!
        CHAT_SYSTEM:SetContainerExtents(
            CHAT_SYSTEM.minContainerWidth,
            GuiRoot:GetWidth(),
            CHAT_SYSTEM.minContainerHeight,
            GuiRoot:GetHeight()
        )

        -- Shortcut for /scritp d(...)
        SLASH_COMMANDS["/d"] = function(src)
            SLASH_COMMANDS["/script"](string.format("d(%s)", src))
        end

        -- Warning for missing TorchBug
        if (SLASH_COMMANDS["/tbug"] == nil) then
            SLASH_COMMANDS["/tbug"] = function()
                d("TorchBug is required for some features to work properly. Go get it at esoui.com.")
            end
        end
    end
end)
