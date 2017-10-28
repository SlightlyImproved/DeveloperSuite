-- Developer Suite
-- The MIT License © Arthur Corenzan

local NAMESPACE = "DeveloperSuite"

--
--
--

local function Dump(value, indent, history)
    indent = indent or ""
    history = history or {}

    local dump = ""
    local valueType = type(value)

    if (valueType == "table") then
        if not history[value] then
            dump = dump.."(table)\n"
            history[value] = true
            for k, v in pairs(value) do
                dump = dump..string.format("%s[%s] = %s", indent, tostring(k), Dump(v, indent.." ", history))
            end
        else
            dump = dump.."(redundant)\n"
        end
    else
        dump = dump.."("..valueType..") "..tostring(value).."\n"
    end

    return dump
end

--
--
--

local DeveloperSuite_Console = ZO_Object:Subclass()

function DeveloperSuite_Console:New(...)
    local console = ZO_Object.New(self)
    console:Initialize(...)
    return console
end

function DeveloperSuite_Console:Initialize(control, savedVars)
    DeveloperSuite_TopLevelControl_Initialize(self, control, savedVars)

    self.outputScrollContainer = self.control:GetNamedChild("OutputScrollContainer")
    self.outputLabel = self.control:GetNamedChild("OutputLabel")
    self.inputEditBox = self.control:GetNamedChild("InputEditBox")

    local function onScrollExtentsChanged(scroll)
        ZO_Scroll_OnExtentsChanged(self.outputScrollContainer)
        if self.outputScrollContainer.scrollbar then
            self.outputScrollContainer.scrollbar:SetValue(100)
        end
    end
    self.outputScrollContainer.scroll:SetHandler("OnScrollExtentsChanged", onScrollExtentsChanged)

    self:AddOutput()

    local function onEnter()
        self:Run(self.inputEditBox:GetText())
        self.inputEditBox:SetText("")
    end
    self.inputEditBox:SetHandler("OnEnter", onEnter)

    local function onUpArrow()
        self:NavigateHistoryUp()
    end
    self.inputEditBox:SetHandler("OnUpArrow", onUpArrow)

    local function onDownArrow()
        self:NavigateHistoryDown()
    end
    self.inputEditBox:SetHandler("OnDownArrow", onDownArrow)

    self:RefreshHistoryIndex()
end

function DeveloperSuite_Console:Run(text)
    if text == "" then
        return nil
    elseif text == "/clear" then
        self:ClearOutput()
    elseif (text:byte(1) == 47) then -- Byte (47) is a division slash.
        DoCommand(text)
    else
        local script = zo_loadstring(string.format("return %s", text))
        local value = script()
        if script then
            self:AddOutput("> "..Dump(value))
            self:AddToHistory(text)
        end
    end
end

function DeveloperSuite_Console:RefreshHistoryIndex()
    self.historyIndex = #self.savedVars.history + 1
end

function DeveloperSuite_Console:AddToHistory(text)
    table.insert(self.savedVars.history, text)
    self:RefreshHistoryIndex()
end

function DeveloperSuite_Console:NavigateHistoryUp()
    if (self.historyIndex > 1) then
        self.historyIndex = self.historyIndex - 1
        self.inputEditBox:SetText(self.savedVars.history[self.historyIndex])
    end
end

function DeveloperSuite_Console:NavigateHistoryDown()
    if (self.historyIndex <= #self.savedVars.history) then
        self.historyIndex = self.historyIndex + 1
        self.inputEditBox:SetText(self.savedVars.history[self.historyIndex])
    end
end

function DeveloperSuite_Console:ClearOutput()
    self.savedVars.output = ""
    self:AddOutput()
end

function DeveloperSuite_Console:AddOutput(output)
    self.savedVars.output = self.savedVars.output..tostring(output or "")
    self.outputLabel:SetText(self.savedVars.output)
end

function DeveloperSuite_Console:Toggle()
    DeveloperSuite_TopLevelControl_Toggle(self.control, self.inputEditBox)
end

--
--
--

local function OnAddOnLoaded(savedVars)
    DEVELOPER_SUITE_CONSOLE = DeveloperSuite_Console:New(DeveloperSuite_ConsoleTopLevelControl, savedVars.console)
    SLASH_COMMANDS["/console"] = function()
        DEVELOPER_SUITE_CONSOLE:Toggle()
    end
end
CALLBACK_MANAGER:RegisterCallback(NAMESPACE.."_OnAddOnLoaded", OnAddOnLoaded)
