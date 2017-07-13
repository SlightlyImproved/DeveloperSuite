-- Developer Suite
-- The MIT License © Arthur Corenzan

local NAMESPACE = "DeveloperSuite"

--
--
--

local DeveloperSuite_About = ZO_Object:Subclass()

function DeveloperSuite_About:New(...)
    local about = ZO_Object.New(self)
    about:Initialize(...)
    return about
end

function DeveloperSuite_About:Initialize(control, savedVars)
    DeveloperSuite_TopLevelControl_Initialize(self, control, savedVars)
end

function DeveloperSuite_About:Toggle()
    if self.control:IsHidden() then
        DeveloperSuite_TopLevelControl_Show(self.control)
    else
        DeveloperSuite_TopLevelControl_Hide(self.control)
    end
end

--
--
--

local function OnAddOnLoaded(savedVars)
    DEVELOPER_SUITE_ABOUT = DeveloperSuite_About:New(DeveloperSuite_AboutTopLevelControl, savedVars.about)
    SLASH_COMMANDS["/developersuite"] = function()
        DEVELOPER_SUITE_ABOUT:Toggle()
    end
end
CALLBACK_MANAGER:RegisterCallback(NAMESPACE.."_OnAddOnLoaded", OnAddOnLoaded)
