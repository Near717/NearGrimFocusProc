Near_GrimFocusProc = {
	name = "NearGrimFocusProc",
	title = "Near's Grim Focus Proc",
	author = "|cCC99FFnotnear|r",
	defaults = {
		offsetX = 800,
		offsetY = 700,
		width = 50,
		height = 50,
	},
}

function Near_GrimFocusProc.OnMoveStop()
	local sv = Near_GrimFocusProc.ASV

	sv.offsetX = NGFP_GUI:GetLeft()
	sv.offsetY = NGFP_GUI:GetTop()
end

local addon = Near_GrimFocusProc

local buffIds = {
	122585, -- Grim Focus
	122587, -- Relentless Focus
	122586, -- Merciless Resolve
}

local function OnProc(_, changeType, _, _, _, _, _, stackCount)
	if changeType == EFFECT_RESULT_UPDATED and (stackCount == 5 or stackCount == 10) then
		if IsUnitInCombat('player') then
			NGFP_GUI:SetHidden(false)

			EVENT_MANAGER:RegisterForUpdate(addon.name, 1000,
				function()
					NGFP_GUI:SetHidden(true)
					EVENT_MANAGER:UnregisterForUpdate(addon.name)
				end
			)
		else
			NGFP_GUI:SetHidden(true)
		end
	end
end

local function OnPlayerCombatState(_, inCombat)
	if not inCombat then
		NGFP_GUI:SetHidden(true)
	end
end

local function SetDimensions(width, height)
	NGFP_GUI:SetDimensions(width, height)
end

local function RestoreSettings()
	local sv = Near_GrimFocusProc.ASV

	local offsetX = sv.offsetX or addon.defaults.offsetX
	local offsetY = sv.offsetY or addon.defaults.offsetY

	local width = sv.width or addon.defaults.width
	local height = sv.height or addon.defaults.height

	SetDimensions(width, height)

	NGFP_GUI:ClearAnchors()
	NGFP_GUI:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, offsetX, offsetY)
end

-- Register LibAddonMenu2
local function SetupSettings()
	local LAM2 = LibAddonMenu2
	local sv = Near_GrimFocusProc.ASV

	local panelData = {
		type = 'panel',
		name = addon.title,
		displayName = addon.title,
		author = addon.author,
		registerForRefresh = true,
		registerForDefaults = true,
	}
	LAM2:RegisterAddonPanel(addon.name, panelData)

	local optionsTable = {}

	local show = false
	optionsTable[#optionsTable + 1] = {
		type = 'checkbox',
		name = 'Show icon',
		tooltip = 'For editing',
		default = false,
		getFunc = function() return show end,
		setFunc = function(v)
			show = v
			NGFP_GUI:SetHidden(not v)
		end,
	}

	optionsTable[#optionsTable + 1] = {
		type = 'slider',
		name = 'Width',
		tooltip = 'Adjust the width of the icon',
		min = 25,
		max = 100,
		step = 1,
		default = addon.defaults.width,
		getFunc = function() return sv.width end,
		setFunc = function(v)
			sv.width = v
			SetDimensions(v, sv.height)
		end,
	}

	optionsTable[#optionsTable + 1] = {
		type = 'slider',
		name = 'Height',
		tooltip = 'Adjust the height of the icon',
		min = 25,
		max = 100,
		step = 1,
		default = addon.defaults.height,
		getFunc = function() return sv.height end,
		setFunc = function(v)
			sv.height = v
			SetDimensions(sv.width, v)
		end,
	}

	LAM2:RegisterOptionControls(addon.name, optionsTable)
end

local function Init()
	EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_PLAYER_COMBAT_STATE, OnPlayerCombatState)

	for _, id in pairs(buffIds) do
		EVENT_MANAGER:RegisterForEvent(addon.name .. id, EVENT_EFFECT_CHANGED, OnProc)
		EVENT_MANAGER:AddFilterForEvent(addon.name .. id, EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID, id)
		EVENT_MANAGER:AddFilterForEvent(addon.name .. id, EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, 'player')
	end

	RestoreSettings()
end

local function OnAddOnLoaded(_, addonName)
	if addonName ~= addon.name then return end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon.ASV = ZO_SavedVars:NewAccountWide(addon.name .. '_Data', 1, GetWorldName(), addon.defaults)

	SetupSettings()
	Init()
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
