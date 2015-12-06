-- Developer Suite 0.1.2alpha (Dec 6 2015)
-- Licensed under CC-BY-NC-SA-4.0

local DEVELOPER_SUITE = "DeveloperSuite"

--
--
--

function DeveloperSuite_Restore(control, sv)
    if not (sv.offsetX == 0 and sv.offsetY == 0) then
        control:ClearAnchors()
        control:SetAnchor(TOPLEFT, nil, TOPLEFT, sv.offsetX, sv.offsetY)
    end
    control:SetDimensions(sv.x, sv.y)
    control:SetHidden(sv.hidden)
end

function DeveloperSuite_Initialize(control, sv)
    control:SetHandler("OnShow", function()
        sv.hidden = false
    end)

    control:SetHandler("OnHide", function()
        sv.hidden = true
    end)

    control:SetHandler("OnMoveStop", function()
        sv.offsetX = control:GetLeft()
        sv.offsetY = control:GetTop()
    end)

    control:SetHandler("OnResizeStop", function()
        sv.x = control:GetWidth()
        sv.y = control:GetHeight()
    end)
end

function DeveloperSuite_Show(control)
    control:SetHidden(false)
    control:BringWindowToTop()
    SCENE_MANAGER:SetInUIMode(true)
end

function DeveloperSuite_SmartToggle(tlc, editBox)
    if tlc:IsHidden() then
        DeveloperSuite_Show(tlc)
        editBox:TakeFocus()
    else
        if editBox:HasFocus() then
            editBox:LoseFocus()
            DeveloperSuite_Hide(tlc)
        else
            DeveloperSuite_Show(tlc)
            editBox:TakeFocus()
        end
    end
end

function DeveloperSuite_Hide(control)
    control:SetHidden(true)
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
    self.control = control
    self.sv = sv

    DeveloperSuite_Initialize(self.control, self.sv)
    DeveloperSuite_Restore(self.control, self.sv)

    SLASH_COMMANDS["/developersuite"] = function()
        self:Toggle()
    end
end

function About:Toggle()
    if self.control:IsHidden() then
        DeveloperSuite_Show(self.control)
    else
        DeveloperSuite_Hide(self.control)
    end
end


--
--
--

local Editor = ZO_Object:Subclass()

function Editor:New(...)
    local editor = ZO_Object.New(self)
    editor:Initialize(...)
    return editor
end

function Editor:Initialize(control, sv)
    self.control = control
    self.sv = sv

    DeveloperSuite_Initialize(self.control, self.sv)
    DeveloperSuite_Restore(self.control, self.sv)

    local scriptEditBox = GetControl(self.control, "ScriptEditBox")
    scriptEditBox:SetText(self.sv.script)
    scriptEditBox:SetHandler("OnTextChanged", function()
        self.sv.script = scriptEditBox:GetText()
    end)

    local runButton = GetControl(self.control, "RunButton")
    runButton:SetHandler("OnClicked", function()
        self:Run()
    end)

    SLASH_COMMANDS["/editor"] = function()
        self:Toggle()
    end
end

function Editor:Toggle()
    local editBox = GetControl(self.control, "ScriptEditBox")
    DeveloperSuite_SmartToggle(self.control, editBox)
end

function Editor:Run()
    local editBox = GetControl(self.control, "ScriptEditBox")
    local script = zo_loadstring(editBox:GetText())

    if script then
        script()
    end
end

--
--
--

local EXPLORER_ROW_HEIGHT = 26
local EXPLORER_ENTRY_DATA = 1

local Explorer = ZO_SortFilterList:Subclass()

function Explorer:New(...)
    return ZO_SortFilterList.New(self, ...)
end

function Explorer:Initialize(control, sv)
    ZO_SortFilterList.Initialize(self, control)

    ZO_ScrollList_AddDataType(self.list, EXPLORER_ENTRY_DATA, "DeveloperSuiteExplorerRow", EXPLORER_ROW_HEIGHT, function(...) self:SetupRow(...) end)

    self:SetAlternateRowBackgrounds(true)

    self.sv = sv

    DeveloperSuite_Initialize(control, sv)
    DeveloperSuite_Restore(control, sv)

    local searchBox = GetControl(control, "SearchBox")

    searchBox:SetText(sv.search.query)
    searchBox:SetHandler("OnTextChanged", function()
        self:RefreshData()
        sv.search.query = searchBox:GetText()
    end)

    for _, type in ipairs({"Function", "Table", "Number", "String", "Other"}) do
        local control = GetControl(control, "SearchTypes"..type)

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
        SLASH_COMMANDS["/zgoo"](data.name)
    end)
end

function Explorer:Toggle()
    local searchBox = GetControl(self.control, "SearchBox")

    if self.control:IsHidden() then
        DeveloperSuite_Show(self.control)
        searchBox:TakeFocus()
    else
        if searchBox:HasFocus() then
            DeveloperSuite_Hide(self.control)
        else
            searchBox:TakeFocus()
            self.control:BringWindowToTop()
        end
    end
end


--
--
--

local LIBRARY_ROW_HEIGHT = 26
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

    self.sv = sv

    DeveloperSuite_Initialize(control, sv)
    DeveloperSuite_Restore(control, sv)

    local searchBox = GetControl(control, "SearchBox")

    searchBox:SetText(sv.search.query)
    searchBox:SetHandler("OnTextChanged", function()
        self:RefreshData()
        sv.search.query = searchBox:GetText()
    end)

    local texturePreview = GetControl(control, "Preview")

    local searchTypeTextureButton = GetControl(control, "SearchTypeTextureButton")
    local searchTypeSoundButton = GetControl(control, "SearchTypeSoundButton")

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
    local searchBox = GetControl(self.control, "SearchBox")

    if self.control:IsHidden() then
        DeveloperSuite_Show(self.control)
        searchBox:TakeFocus()
    else
        if searchBox:HasFocus() then
            DeveloperSuite_Hide(self.control)
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

ZO_CreateStringId("SI_DEVELOPER_SUITE_HELP", table.concat({
    "   About /developersuite",
    "  Editor /editor",
    "Explorer /explorer",
    " Library /library",
}, "\n"))

ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_LIBRARY", "Open/close Media Library")
ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_EXPLORER", "Open/close Explorer")
ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_EDITOR", "Open/close Editor")
ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_RUN", "Run script")
ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_RELOADUI", "Reload interface")
ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_ZGOO_MOC", "Inspect control under cursor")

function DeveloperSuite_Binding_ZgooMoc()
    SLASH_COMMANDS["/zgoo"]("moc()")
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

function DeveloperSuite_Binding_Editor()
    DEVELOPER_SUITE_EDITOR:Toggle(true)
end

function DeveloperSuite_Binding_Run()
    DEVELOPER_SUITE_EDITOR:Run()
end

--
--
--

local sv =
{
    ["about"] =
    {
        ["hidden"] = false,
        ["x"] = 320,
        ["y"] = 140,
        ["offsetX"] = 0,
        ["offsetY"] = 0,
    },
    ["editor"] =
    {
        ["hidden"] = true,
        ["x"] = 480,
        ["y"] = 320,
        ["offsetX"] = 0,
        ["offsetY"] = 0,
        ["script"] = "d(\"Edit me and click run!\")",
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
        ["x"] = 320,
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

        sv = ZO_SavedVars:NewAccountWide("DeveloperSuiteSavedVars", 1, nil, sv)

        DEVELOPER_SUITE_ABOUT = About:New(DeveloperSuiteAbout, sv.about)
        DEVELOPER_SUITE_EDITOR = Editor:New(DeveloperSuiteEditor, sv.editor)
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

        -- Warn for missing Zgoo
        if (SLASH_COMMANDS["/zgoo"] == nil) then
            SLASH_COMMANDS["/zgoo"] = function()
                d("Zgoo is required for many features to work properly, go get it at esoui.com.")
            end
        end
    end
end)
