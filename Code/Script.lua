-- TODO -- Ask ChoGGi to add hotkey to "Close dialogs"
-- TODO -- ReloadLua() cmd, but it messes up ECM (and it's in the func blacklist)

---- LUA STUFF ----

-- GlobalVar("tmp", {"param1","param2",}) <- this line will not create object, but boolean == false :(
-- GlobalVar("tmp", {}) tmp = {[1] = "param1", [2] = "param2",} <- create empty object, add params

-- pairs() returns key-value pairs and is mostly used for associative tables. key order is unspecified.
-- ipairs() returns index-value pairs and is mostly used for numeric tables. Non numeric keys in an array are ignored, while the index order is deterministic (in numeric order).

-- Order of function definition is essential. Must define before first useage. Search "Lua Function Forward Declaration".

-- Official documentation LuaFunctionDoc_AsyncIO.md.html for all "Async*()" functions in this script.

-- Operator precedence in Lua follows the table below, from the higher to the lower priority:
	-- ^
	-- not  - (unary)
	-- *   /
	-- +   -
	-- ..
	-- <   >   <=  >=  ~=  ==
	-- and
	-- or




---- BUILD MENUS ----

-- Ingame table with root menus, which appears on hotkey [B]:
-- Enhanced Cheat Menu -> Console -> ~BuildCategories

-- Ingame table with menu subcategories (example is [Depot] in [Storages]):
-- Enhanced Cheat Menu -> Console -> ~BuildMenuSubcategories

-- Empty menu is not visible. Add building, and menu will appear.

-- Path to menu icon
local menuIcon = "UI/MenuIcon.png"
-- Disaplay name of each menu
local displayName = "Layout"
-- Add this prefix to id of original menu to create id for my menus: "Layout Infrastructure"
local idPrefix = "Layout "
-- Add suffix to id of original menu to create description for my menus: "Infrastructure Layouts"
local descrSuffix = " Layouts"
-- Table with id of original menus. Surviving Mars have 14 menus. Look in ~BuildCategories table
local origMenuId = {
	[1]  = "Infrastructure",
	[2]  = "Power",
	[3]  = "Production",
	[4]  = "Life-Support",
	[5]  = "Storages",
	[6]  = "Domes",
	[7]  = "Habitats",
	[8]  = "Dome Services",
	[9]  = "Dome Spires",
	[10] = "Decorations",
	[11] = "Outside Decorations",
	[12] = "Wonders",
	[13] = "Landscaping",
	[14] = "Terraforming",
	[15] = "Default", -- add my param on last position, we will use it to create id for my submenu in root menu
}
-- Table with id for my menus
local menuId = {}

-- Use this message to perform post-built actions on the final classes
function OnMsg.ClassesBuilt()
	-- Create id for my submenus
	for i, id in ipairs(origMenuId) do
		menuId[i] = idPrefix .. id
	end
	
	-- Create root menu
	local bc = BuildCategories
	local id = menuId[#menuId] -- #var - get size of table "var"
	if not table.find(bc, "id", id) then
		-- TODO change to proper way? ... PlaceObj('BuildMenuSubcategory', ... )
		bc[#bc + 1] = {
			id = id,
			name = displayName,
			image = CurrentModPath .. menuIcon,
			-- “on hover” effects; this should probably always be "UI/Icons/bmc_infrastructure_shine.tga" to have the default “on hover” effect
			-- TODO
			-- highlight = "UI/Icons/bmc_infrastructure_shine.tga",
			-- highlight = "UI/Icons/bmc_dome_buildings_shine.tga",
			-- highlight = "UI/Icons/Buildings/dinner_shine.tga",
			-- highlight or highlight_img param? From different sources, not shure.
		}
	end
	
	-- Create submenu in each original menu
	for i, id in ipairs(menuId) do
		local bmc = BuildMenuSubcategories
		if not table.find(bmc, "id", id) then
			bmc[id] = PlaceObj('BuildMenuSubcategory', {
				id = id,
				build_pos = 0,
				-- The main category inside which the subcategory will appear
				category = origMenuId[i],
				-- Unknown, will set equal to id
				category_name = id,
				display_name = displayName,
				description = origMenuId[i] .. descrSuffix,
				icon = CurrentModPath .. menuIcon,
				-- Unknown
				group = "Default",
				-- If the player can switch between the buildings of this subcategory
				-- using the “cycle visual variant” buttons (by default [ and ]).
				-- This is useful in cases like the “Depots” and “Storage” subcategory.
				-- It is far simpler to use the “cycle visual variant” keys, instead of
				-- going through the build menu, when placing multiple depots for different resources.
				-- By default it's true.
				-- allow_template_variants = true,
				-- action = function(self, context, button)
					-- print("You Selected Subcategory")
				-- end,
			})
		end
	end
end




---- DEBUG ----

-- DEBUG
-- Open in Notepad++, and hit [Ctrl-Q] to toggle comment
-- local DEBUG = false
local DEBUG = true

-- TODO ChoGGi will add this func to Expanded Cheat Menu, stay tuned
-- ECM/Lib must be enabled before all others mod
ChoGGi_ReloadLua = function()
    if not ModsLoaded then
        return
    end
    -- get list of enabled mods
    local enabled = table.icopy(ModsLoaded)
    -- turn off all mods
    AllModsOff()
    -- re-enable ecm/lib
    TurnModOn(ChoGGi.id)     -- Expanded Cheat Menu
    TurnModOn(ChoGGi.id_lib) -- Library
    -- reload lua code
    ModsReloadItems()
    -- enable disabled mods
    for i = 1, #enabled do
        TurnModOn(enabled[i].id)
    end
    -- reload lua code
    ModsReloadItems()
end




---- CREATE SHORCUTS

local ShortcutCapture   = "Ctrl-Insert"
local ShortcutSetParams = "Shift-Insert"

-- Function forward declaration
local LayoutCapture, LayoutSetParams

-- After this message ChoGGi's object is ready to use
function OnMsg.ModsReloaded()
	local Actions = ChoGGi.Temp.Actions
	
	-- ActionName = 'Display Name In "Key Bindings" Menu' ("Surviving Mars" -> "Options" -> "Key Bindings")
	-- OnAction = FuncName (for example "cls": clear log)
	Actions[#Actions + 1] = {
		ActionName = "Layout Capture",
		ActionId = "Layout.Capture",
		OnAction = LayoutCapture,
		ActionShortcut = ShortcutCapture,
		ActionBindable = true,
	}
	
	Actions[#Actions + 1] = {
		ActionName = "Layout Set Params",
		ActionId = "Layout.Set.Params",
		OnAction = LayoutSetParams,
		ActionShortcut = ShortcutSetParams,
		ActionBindable = true,
	}
	
	if (DEBUG) then
		Actions[#Actions + 1] = {
			ActionName = "Layout Reload Lua",
			ActionId = "Layout.Reload.Lua",
			OnAction = cls,
			ActionShortcut = "LWin-Insert",
			ActionBindable = true,
		}
	end
end




---- MAIN CODE ----

-- Function forward declaration
local BuildItemsLua, BuildMetadataLua, BuildLayoutHeadLua, BuildLayoutBodyLua, BuildLayoutTailLua, BuildLayoutLua
local WriteToFiles

local buildings, cables, pipes
local numCapturedObjects = 0

local metadataFileName, layoutFilePath, layoutFileNameNoPath, layoutFileName

local default_build_category = #origMenuId
local default_build_pos = 0
local default_radius = 10000

local layoutSettings = {
	id = "SetIdForLayoutFile",
	display_name = "Display Name",
	description = "Layout Desctiption",
	build_category = default_build_category,
	build_pos = default_build_pos,
	radius = default_radius,
}

-- Forward declaration with this func not work.
-- If make forward declaration and place function's body below "local GUIDE", "local GUIDE" will call nil "TableToString" variable
function TableToString(inputTable)
	local str = ""
	for i, v in ipairs(inputTable) do
		if (i < 10) then
			-- Shift line with one digit [1-9] to right
			str = str .. "   "
		end
		str = str .. i .. "\t== " .. v .. "\n"
	end
	return str
end

local GUIDE = '\n' .. [[
ChoGGi's Mods: https://github.com/ChoGGi/SurvivingMars_CheatMods/
[REQUIRED] ChoGGi's "Startup HelperMod" to bypass blacklist (we need acces to AsyncIO functions to create lua files).
	Install required mod, then copy "AppData\BinAssets" from Layout's mod folder to "%AppData%\Surviving Mars".
[Optional] ChoGGi's "Enhanced Cheat Menu" [F2] -> "Cheats" -> "Toggle Unlock All Buildings" -> Double click "Unlock"
[Optional] ChoGGi's "Fix Layout Construction Tech Lock" mod if you want build buildings, that is locked by tech.
BUILD:
	Place your buildings.
	Press [Alt-B] to instant building.
SET PARAMS:
	Place your mouse cursor in the center of building's layout.
	Press [Ctrl-M] and measure radius of building's layout.
	Press []] .. ShortcutSetParams .. ']\n' .. [[
	Two window will appear: "Examine" and "Edit Object". Move "Examine" to see both windows.
	Set parameters in "Edit Object" window:
		"id" (must be unique, allowed "CamelCase" or "snake_case" notation) internal script parameter, additionally will be used as part of file name of layout's lua script and as file name for layout's icon.
		"build_category" (allowed number from 1 to 15) in which menu captured layout will be placed. See hint in another window.
		"build_pos" (number from 1 to 99, can be duplicated) position in build menu.
		"radius" (nil or positive number [to infinity and beyond]) capture radius, multiply measured value in meters by 100.
		[others] - as you like.
	Close all windows.
CAPTURE:
	Press []] .. ShortcutCapture .. ']\n' .. [[
APPLY:
	To take changes in effect restart game.
	Press [Ctrl-Alt-R] then [Enter].
WHAT TO DO:
	Make some fancy icon and replace the one, located in "]] .. CurrentModPath .. 'UI/%id%.png"\n\n' .. [[
"build_category" (allowed value is number from 1 to 15):]] .. '\n' .. TableToString(origMenuId)


-- function OnMsg.ClassesPostprocess()
-- end

-- Get all objects, then filter for ones within *radius*, returned sorted by dist, or *sort* for name
-- ChoGGi.ComFuncs.OpenInExamineDlg(ReturnAllNearby(1000, "class")) from ChoGGi's Library v8.7
-- Added 4th argument "class": only get objects inherited from "class", provided by this parameter
function ReturnAllNearby(radius, sort, pt, class)
	-- local is faster then global
	local table_sort = table.sort
	-- TODO tune 'radius' value
	radius = radius or 5000
	pt = pt or GetTerrainCursor()

	-- get all objects within radius
	local list = MapGet(pt, radius, class)

	-- sort list custom
	if sort then
		table_sort(list, function(a, b)
			return a[sort] < b[sort]
		end)
	else
		-- sort nearest
		table_sort(list, function(a, b)
			return a:GetVisualDist(pt) < b:GetVisualDist(pt)
		end)
	end

	return list
end

-- Return table with objects, that match "entity" parameter
function GetObjsByEntity(inputTable, entity)
	local string_find = string.find
	local table_insert = table.insert
	local resultTable = {}
	for i, v in ipairs(inputTable) do
		if (string_find(inputTable[i]:GetEntity(), entity)) then
			table_insert(resultTable, inputTable[i])
		end
	end
	return resultTable
end

-- Custom dialog window, show only text, no action
-- TODO ChoGGi can we use simpler DialogBox?
function CancelDialogBox(text, title)
	-- function ChoGGi.ComFuncs.QuestionBox(text, func, title, ok_text, cancel_text, image, context, parent, template, thread)
	ChoGGi.ComFuncs.QuestionBox(
		text,
		nil,
		title,
		"Cancel Layout Capture",
		"Cancel Layout Capture"
	)
end

-- Trim space http://lua-users.org/wiki/StringTrim
function TrimSpace(str)
	-- "%s" - space
	-- "."  - 'greedy' any character
	-- ".-" - 'lazy' any character
	return (str:gsub("^%s*(.-)%s*$", "%1"))
end

function FileExist(fileName)
	if (AsyncGetFileAttribute(fileName, "size") == "File Not Found") then
		return false
	else
		return true
	end
end

-- Return "true" - params OK, "false" - params WRONG
function CheckInputParams()
	local build_category = tonumber(layoutSettings.build_category)
	layoutSettings.build_category = build_category
	if (build_category < 1 or build_category > #origMenuId) then
		-- Restore default value
		layoutSettings.build_category = default_build_category
		CancelDialogBox(
			'"build_category" - enter number from 1 to 15',
			'"build_category" - not allowed value: ' .. build_category
		)
		return false
	end
	
	local build_pos = tonumber(layoutSettings.build_pos)
	layoutSettings.build_pos = build_pos
	if (build_pos < 0 or build_pos > 99) then
		layoutSettings.build_pos = default_build_pos
		CancelDialogBox(
			'"build_pos" - enter number from 1 to 99',
			'"build_pos" - not allowed value: ' .. build_pos
		)
		return false
	end
	
	local id = TrimSpace(tostring(layoutSettings.id))
	layoutSettings.id = id
	if (string.find(id, " ") or string.find(id, "\t")) then
		-- Do not resotre default value, user can edit yourself
		CancelDialogBox(
			'"id" - must be unique, allowed "CamelCase" or "snake_case" notation',
			'"id" - not allowed value: ' .. id
		)
		return false
	end
	
	local radius = tonumber(layoutSettings.radius)
	layoutSettings.radius = radius
	if (radius < 1) then
	layoutSettings.radius = default_radius
		CancelDialogBox(
			'"radius" - enter positive number [to infinity and beyond]',
			'"radius" - not allowed value: ' .. radius
		)
		return false
	end
	
	return true
end

LayoutCapture = function()
	-- Capture objects
	buildings = ReturnAllNearby(layoutSettings.radius, nil, nil, "Building")
	local supply    = ReturnAllNearby(layoutSettings.radius, nil, nil, "BreakableSupplyGridElement")
	cables = GetObjsByEntity(supply, "Cable")
	pipes  = GetObjsByEntity(supply, "Tube")

	numCapturedObjects = #buildings + #cables + #pipes
	
	-- Is table empty
	-- "==" has higher priority than "and"
	if (next(buildings) == nil and next(cables) == nil and next(pipes) == nil) then
		-- TODO Show notification(Nothing captured)
		print("Nothing captured")
		return
	end
	
	-- After this all params in layoutSettings are correct
	if (not CheckInputParams()) then
		return
	end
	
	-- Files prepare
	metadataFileName = CurrentModPath .. "metadata.lua"
	local build_pos = layoutSettings.build_pos
	if (build_pos < 10) then
		-- Make "build_pos" with two digit
		build_pos = "0" .. build_pos
	end
	-- Path to file
	layoutFilePath = "" .. CurrentModPath .. "Layout/"
	-- File name without path
	layoutFileNameNoPath = "" .. origMenuId[layoutSettings.build_category] .. " - " .. build_pos .. " - " .. layoutSettings.id .. ".lua"
	-- Concatenate path and name
	layoutFileName = layoutFilePath ..layoutFileNameNoPath
		
	if (DEBUG) then
		local dbgExt = ".txt"
		layoutFileName = layoutFileName .. dbgExt
		layoutFileNameNoPath = layoutFileNameNoPath .. dbgExt
		metadataFileName = metadataFileName .. dbgExt
	end
	
	local fileExist = FileExist(layoutFileName)
	
	print("FileName: " .. layoutFileNameNoPath)
	-- Can't cocatenate boolean variable
	print("FileExist: " .. tostring(fileExist))
	
	if (fileExist) then
		-- function ChoGGi.ComFuncs.QuestionBox(text, func, title, ok_text, cancel_text, image, context, parent, template, thread)
		ChoGGi.ComFuncs.QuestionBox(
			'Path to "Layout" folder: \n\t"' .. CurrentModPath .. 'Layout"\nLayout file with this name already exist in "Layout" folder: \n\t"' .. layoutFileNameNoPath .. '"',
			function(answer)
				if answer then
					print("File overwrited")
					WriteToFiles()
				end
			end,
			"Overwrite file?",
			"Yes",
			"Cancel Layout Capture"
		)
	else
		WriteToFiles()
	end
end

WriteToFiles = function()
	-- string err AsyncStringToFile(...) - by default overwrites file
	-- "items.lua" not needed. Empty is OK. It used in-game "Mod Editor". ChoGGi says "Mod Editor" may corrupt mods on saving.
	print(AsyncStringToFile(metadataFileName, BuildMetadataLua()))
	print(AsyncStringToFile(layoutFileName, BuildLayoutLua()))
	-- TODO 
	print("Captured Objects: " .. numCapturedObjects)
	print("Layout Saved: " .. layoutFileNameNoPath)
end

LayoutSetParams = function()
	local OpenInObjectEditorDlg = ChoGGi.ComFuncs.OpenInObjectEditorDlg
	OpenExamine(GUIDE)
	OpenInObjectEditorDlg(layoutSettings)
end

BuildItemsLua = function()
end

BuildMetadataLua = function()
	local err, layoutFiles = AsyncListFiles(CurrentModPath .. "Layout", "*.lua", "relative, sorted")
	local strLayoutFiles = ""
	for i, strFile in ipairs(layoutFiles) do
		strLayoutFiles = strLayoutFiles .. '\t\t"' .. 'Layout/' .. strFile .. '",\n'
	end
	local str = [[
return PlaceObj('ModDef', {
	"dependencies", {
		PlaceObj("ModDependency", {
			"id", "ChoGGi_Library",
			"title", "ChoGGi's Library",
			"version_major", 8,
			"version_minor", 7,
		}),
		PlaceObj("ModDependency", {
			"id", "ChoGGi_CheatMenu",
			"title", "Expanded Cheat Manu",
			"version_major", 15,
			"version_minor", 7,
		}),
	},
	'title', "Layout Mod",
	'description', "Capture and save building's layout.",
	'image', "ModImage.png",
	'last_changes', "Initial release.",
	'id', "Fixer_Layout_Mod",
	'steam_id', "9876543210",
	'pops_desktop_uuid', "2985b508-0ba0-4f20-8ff3-8bf242be35e3",
	'pops_any_uuid', "bbf577bf-dee0-4346-bad5-1037f6a827e7",
	'author', "Fixer",
	'version_major', 1,
	'version', 1,
	'lua_revision', 233360,
	'saved_with_revision', 249143,
	'code', {
	-- Main Code --
		"Code/Script.lua",
	-- Captured Layout --
]] .. strLayoutFiles .. [[
	},
	'saved', 1604768099,
	-- 'screenshot1', "",
	'TagTools', true,
	'TagOther', true,
})
]]
	return str
end

BuildLayoutHeadLua = function()
	local str = [[
function OnMsg.ClassesPostprocess()
	if BuildingTemplates.]] .. layoutSettings.id .. [[ then
		return
	end

	local id = "]] .. layoutSettings.id .. [["
	local build_category = "]] .. menuId[layoutSettings.build_category] .. [["

	PlaceObj("BuildingTemplate", {
		"Id", id,
		"LayoutList", id,
		"Group", build_category,
		"build_category", build_category,
		"build_pos", ]] .. layoutSettings.build_pos .. [[,
		"display_name", "]] .. layoutSettings.display_name .. [[",
		"display_name_pl", "]] .. layoutSettings.display_name .. [[",
		"description", "]] .. layoutSettings.description .. [[",
		"display_icon", "]] .. "UI/" .. layoutSettings.id .. ".png" .. [[",
		"template_class", "LayoutConstructionBuilding",
		"entity", "InvisibleObject",
		"construction_mode", "layout",
	})

	PlaceObj("LayoutConstruction", {
		group = "Default",
		id = id,

]]

	return str
end

BuildLayoutBodyLua = function()
	-- Official documentation LuaFunctionDoc_hex.md.html
	local str = ""
	-- Base point (zero point)
	local base_q, base_r
	
	-- Buildings
	-- ~= is equivalent of !=
	if (next(buildings) ~= nil) then
		-- If base point not set before, set it now. If "buildings" is empty, get object for base point from "cables" or "pipes"
		if (not base_q or not base_r) then
			local baseObj = buildings[1]
			base_q, base_r = WorldToHex(baseObj)
			if (DEBUG) then
				OpenExamine(baseObj)
			end
		end
		for i, obj in ipairs(buildings) do
			local q, r = WorldToHex(obj)
			q = q - base_q
			r = r - base_r
			str = str .. [[
		PlaceObj("LayoutConstructionEntry", {
			"template", "]] .. obj.template_name .. [[",
			"pos", point(]] .. q .. [[, ]] .. r .. [[),
			"dir", ]] .. HexAngleToDirection(obj) .. [[,
			"entity", "]] .. obj:GetEntity() .. [[",]] .. "\n"
			if (obj.template_name == "UniversalStorageDepot") then
				str = str .. [[
			"instant", true,]] .. "\n"
			end
			str = str .. [[
		}),]] .. "\n\n"
		end
	end
	
	-- -- Cables
	-- if (next(cables) ~= nil) then
		-- if (not base_q or not base_r) then
			-- base_q, base_r = WorldToHex(cables[1])
		-- end
		-- for i, obj in ipairs(cables) do
			-- local q, r = WorldToHex(obj)
			-- q = q - base_q
			-- r = r - base_r
			-- str = str .. [[
			-- PlaceObj("LayoutConstructionEntry", {
				-- "template", "]] .. obj.template_name .. [[",
				-- "pos", point(]] .. q .. [[, ]] .. r .. [[),
				-- "dir", ]] .. HexAngleToDirection(obj) .. [[,
				-- "entity", "]] .. obj:GetEntity() .. [[",
			-- }),]] .. "\n\n"
		-- end
	-- end
	
	-- -- Pipes
	-- if (next(pipes) ~= nil) then
		-- if (not base_q or not base_r) then
			-- base_q, base_r = WorldToHex(pipes[1])
		-- end
		-- for i, obj in ipairs(pipes) do
			-- local q, r = WorldToHex(obj)
			-- q = q - base_q
			-- r = r - base_r
			-- str = str .. [[
			-- PlaceObj("LayoutConstructionEntry", {
				-- "template", "]] .. obj.template_name .. [[",
				-- "pos", point(]] .. q .. [[, ]] .. r .. [[),
				-- "dir", ]] .. HexAngleToDirection(obj) .. [[,
				-- "entity", "]] .. obj:GetEntity() .. [[",
			-- }),]] .. "\n\n"
		-- end
	-- end
	
	return str
end

BuildLayoutTailLua = function()
	local str = [[
	})
end
]]
	return str
end

BuildLayoutLua = function()
	return BuildLayoutHeadLua() .. BuildLayoutBodyLua() .. BuildLayoutTailLua()
end
