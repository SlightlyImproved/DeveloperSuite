-- Developer Suite
-- The MIT License © Arthur Corenzan

local NAMESPACE = "DeveloperSuite"
local VERSION = "Version 0.3.0 (Jul 16 2017)"

--
--
--

function DeveloperSuite_TopLevelControl_Restore(self)
    if not (self.savedVars.offsetX == 0 and self.savedVars.offsetY == 0) then
        self.control:ClearAnchors()
        self.control:SetAnchor(TOPLEFT, nil, TOPLEFT, self.savedVars.offsetX, self.savedVars.offsetY)
    end
    self.control:SetDimensions(self.savedVars.width, self.savedVars.height)
    self.control:SetHidden(self.savedVars.isHidden)
end

function DeveloperSuite_TopLevelControl_Initialize(self, control, savedVars)
    self.control = control
    self.savedVars = savedVars

    local function onShow()
        self.savedVars.isHidden = false
    end
    self.control:SetHandler("OnShow", onShow)

    local function onHide()
        self.savedVars.isHidden = true
    end
    self.control:SetHandler("OnHide", onHide)

    local function onMoveStop()
        self.savedVars.offsetX = self.control:GetLeft()
        self.savedVars.offsetY = self.control:GetTop()
    end
    self.control:SetHandler("OnMoveStop", onMoveStop)

    local function onResizeStop()
        self.savedVars.width = self.control:GetWidth()
        self.savedVars.height = self.control:GetHeight()
        if self.list then
            ZO_ScrollList_SetHeight(self.list, self.list:GetHeight())
            ZO_ScrollList_Commit(self.list)
        end
    end
    self.control:SetHandler("OnResizeStop", onResizeStop)

    DeveloperSuite_TopLevelControl_Restore(self)
end

function DeveloperSuite_TopLevelControl_Show(control)
    control:SetHidden(false)
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

function DeveloperSuite_Binding_Reload()
    SLASH_COMMANDS["/reloadui"]()
end

function DeveloperSuite_Binding_Inspector()
    DEVELOPER_SUITE_INSPECTOR:Inspect(moc())
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

ZO_CreateStringId("SI_DEVELOPER_SUITE_VERSION", VERSION)

ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_LIBRARY", "Toggle Library")
ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_EXPLORER", "Toggle Explorer")
ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_CONSOLE", "Toggle Console")
ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_RELOADUI", "Reload Interface")
ZO_CreateStringId("SI_BINDING_NAME_DEVELOPER_SUITE_INSPECTOR", "Inspect Control")

--
--
--

local defaultSavedVars =
{
    ["about"] =
    {
        ["isHidden"] = false,
        ["width"] = 360,
        ["height"] = 160,
        ["offsetX"] = 0,
        ["offsetY"] = 0,
    },
    ["console"] =
    {
        ["isHidden"] = true,
        ["width"] = 520,
        ["height"] = 320,
        ["offsetX"] = 0,
        ["offsetY"] = 0,
        ["output"] = "",
        ["history"] = {},
    },
    ["explorer"] =
    {
        ["isHidden"] = true,
        ["width"] = 640,
        ["height"] = 320,
        ["offsetX"] = 0,
        ["offsetY"] = 0,
        ["search"] =
        {
            ["query"] = "",
            ["types"] =
            {
                ["function"] = true,
                ["table"] = true,
                ["userdata"] = true,
                ["number"] = true,
                ["string"] = true,
                ["boolean"] = true,
            }
        }
    },
    ["library"] =
    {
        ["isHidden"] = true,
        ["width"] = 400,
        ["height"] = 640,
        ["offsetX"] = 0,
        ["offsetY"] = 0,
        ["search"] =
        {
            ["query"] = "",
            ["type"] = "texture"
        }
    },
    ["inspector"] =
    {
        ["isHidden"] = true,
        ["width"] = 100,
        ["height"] = 100,
        ["offsetX"] = 0,
        ["offsetY"] = 0,
    },
}

local function OnAddOnLoaded(event, addOnName)
    if (addOnName == NAMESPACE) then
        EVENT_MANAGER:UnregisterForEvent(NAMESPACE, EVENT_ADD_ON_LOADED)

        local savedVars = ZO_SavedVars:NewAccountWide("DeveloperSuite_SavedVars", 1, nil, defaultSavedVars)
        do
            local mt = getmetatable(savedVars)
            local __newindex = mt.__newindex
            function mt.__newindex(self, key, value)
                CALLBACK_MANAGER:FireCallbacks(NAMESPACE.."_OnSavedVarChanged", key, value, self[key])
                __newindex(self, key, value)
            end
        end
        CALLBACK_MANAGER:FireCallbacks(NAMESPACE.."_OnAddOnLoaded", savedVars)

        -- Free the chat!
        -- CHAT_SYSTEM:SetContainerExtents(
        --     CHAT_SYSTEM.minContainerWidth,
        --     GuiRoot:GetWidth(),
        --     CHAT_SYSTEM.minContainerHeight,
        --     GuiRoot:GetHeight()
        -- )

        -- Shortcut for /scritp d(...)
        SLASH_COMMANDS["/d"] = function(src)
            SLASH_COMMANDS["/script"](string.format("d(%s)", src))
        end

        -- Warning for missing TorchBug
        -- if (SLASH_COMMANDS["/tbug"] == nil) then
        --     SLASH_COMMANDS["/tbug"] = function()
        --         d("TorchBug is required for some features to work properly. Go get it at esoui.com.")
        --     end
        -- end
    end
end
EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
