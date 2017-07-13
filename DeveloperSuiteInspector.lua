-- Developer Suite
-- The MIT License © Arthur Corenzan

local NAMESPACE = "DeveloperSuite"

--
--
--

-- local outlinePool = ZO_ControlPool:New("DeveloperSuite_Outline")
-- outlinePool:SetCustomFactoryBehavior(function(outline)
--     local r, g, b = zo_random(), zo_random(), zo_random()
--     outline:GetNamedChild("Outline"):SetEdgeColor(r, g, b, 1)
--     outline:SetParent(GuiRoot)
-- end)
-- outlinePool:SetCustomResetBehavior(function(outline)
--     outline:SetParent(nil)
--     outline:ClearAnchors()
-- end)
-- local function applyOutline(control)
--     if not control then
--         return
--     end
--     local offsetX, offsetY = control:GetLeft(), control:GetTop()
--     local width, height = control:GetWidth(), control:GetHeight()
--     if offsetX and offsetY and width and height then
--         local outline = outlinePool:AcquireObject()
--         outline:SetAnchor(TOPLEFT, nil, nil, offsetX, offsetY)
--         outline:SetDimensions(width, height)
--         if control.GetNumChildren then
--             for i = 1, control:GetNumChildren() do
--                 local child = control:GetChild(i)
--                 applyOutline(child)
--             end
--         end
--     end
-- end
-- SLASH_COMMANDS["/outline"] = function()
--     outlinePool:ReleaseAllObjects()
--     local control = moc()
--     if control ~= GuiRoot then
--         applyOutline(control)
--     end
-- end

--
--
--

-- local function OnAddOnLoaded(savedVars)
--     DEVELOPER_SUITE_INSPECTOR = DeveloperSuite_Inspector:New(DeveloperSuite_InspectorTopLevelControl, savedVars.inspector)
--     SLASH_COMMANDS["/inspector"] = function()
--         DEVELOPER_SUITE_INSPECTOR:Toggle()
--     end
-- end
-- CALLBACK_MANAGER:RegisterCallback(NAMESPACE.."_OnAddOnLoaded", OnAddOnLoaded)
