Near_GrimFocusProc = {
	name = "NearGrimFocusProc",
	title = "Near's Grim Focus Proc",
	author = "|cCC99FFnotnear|r",
	defaults = {
		offsetX = 800,
		offsetY = 700,
		width = 50,
		height = 50,
		duration = 1000,
		['122585'] = true,
		['122587'] = true,
		['122586'] = true,
		stacks = 9,
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
	local sv = Near_GrimFocusProc.ASV

	if changeType == EFFECT_RESULT_UPDATED and stackCount == sv.stacks then
		if IsUnitInCombat('player') then
			NGFP_GUI:SetHidden(false)

			EVENT_MANAGER:RegisterForUpdate(addon.name, sv.duration,
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

local function RegisterProcs()
	local sv = Near_GrimFocusProc.ASV
	for _, id in ipairs(buffIds) do
		if sv[tostring(id)] then
			EVENT_MANAGER:RegisterForEvent(addon.name .. id, EVENT_EFFECT_CHANGED, OnProc)
			EVENT_MANAGER:AddFilterForEvent(addon.name .. id, EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID, id)
			EVENT_MANAGER:AddFilterForEvent(addon.name .. id, EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, 'player')
		else
			EVENT_MANAGER:UnregisterForEvent(addon.name .. id, EVENT_EFFECT_CHANGED)
		end
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
	local updateEvents = false

	local panelData = {
		type = 'panel',
		name = addon.title,
		displayName = addon.title,
		author = addon.author,
		registerForRefresh = true,
		registerForDefaults = true,
	}
	local LAM2SettingsPanel = LAM2:RegisterAddonPanel(addon.name, panelData)

	local function OnLamPanelClosed(panel)
		if panel ~= LAM2SettingsPanel or not updateEvents then return end
		updateEvents = false
		RegisterProcs()
	end

	local optionsTable = {}

	for _, id in ipairs(buffIds) do
		optionsTable[#optionsTable + 1] = {
			type = 'checkbox',
			name = 'Show procs for ' .. GetAbilityName(id),
			default = addon.defaults[tostring(id)],
			getFunc = function() return sv[tostring(id)] end,
			setFunc = function(v)
				sv[tostring(id)] = v
				updateEvents = true
			end,
		}
	end

	optionsTable[#optionsTable + 1] = {
		type = 'divider',
	}

	optionsTable[#optionsTable + 1] = {
		type = 'slider',
		name = 'Alert at x stacks',
		tooltip = 'Adjust the amount of stacks needed to get the alert',
		min = 0,
		max = 10,
		step = 1,
		default = addon.defaults.stacks,
		getFunc = function() return sv.stacks end,
		setFunc = function(v)
			sv.stacks = v
		end,
	}

	optionsTable[#optionsTable + 1] = {
		type = 'slider',
		name = 'Duration (ms)',
		tooltip = 'Adjust duration of the icon on screen',
		min = 1000,
		max = 5000,
		step = 100,
		default = addon.defaults.duration,
		getFunc = function() return sv.duration end,
		setFunc = function(v)
			sv.duration = v
		end,
	}

	optionsTable[#optionsTable + 1] = {
		type = 'divider',
	}

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

	CALLBACK_MANAGER:RegisterCallback("LAM-PanelClosed", OnLamPanelClosed)
end

local function OnAddOnLoaded(_, addonName)
	if addonName ~= addon.name then return end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon.ASV = ZO_SavedVars:NewAccountWide(addon.name .. '_Data', 1, GetWorldName(), addon.defaults)

	SetupSettings()
	RestoreSettings()

	EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_PLAYER_COMBAT_STATE, OnPlayerCombatState)
	RegisterProcs()
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
