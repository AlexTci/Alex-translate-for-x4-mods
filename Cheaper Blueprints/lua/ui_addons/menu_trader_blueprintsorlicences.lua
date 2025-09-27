-- Cheaper Blueprints (8.0-tolerant hook) by Tabmater
-- Requires sn_mod_support_apis (Simple Menu API Reloaded).

local C = require("ffi").C
local Lib = require("extensions.sn_mod_support_apis.lua_interface").Library

local function get_menu()
  local candidates = {
    "BlueprintOrLicenceTraderMenu",
    "BlueprintsOrLicencesTraderMenu",
    "BlueprintOrLicenseTraderMenu",
    "BlueprintsOrLicensesTraderMenu",
    "BlueprintOrLicenceMenu",
    "BlueprintsOrLicencesMenu"
  }
  for _, id in ipairs(candidates) do
    local m = Lib.Get_Egosoft_Menu(id)
    if m and type(m) == "table" then return m, id end
  end
  return nil, nil
end

local function scale_price(v, percent, min_price)
  if type(v) == "number" then
    return math.max(v * percent, min_price)
  end
  return v
end

local function apply_scaling_to_table(tbl, percent, min_price)
  if type(tbl) ~= "table" then return end
  for k, v in pairs(tbl) do
    if type(v) == "table" then
      apply_scaling_to_table(v, percent, min_price)
    else
      tbl[k] = scale_price(v, percent, min_price)
    end
  end
end

local function patch_menu(menu)
  if not menu or type(menu.initData) ~= "function" then return false end
  local orig_initData = menu.initData
  menu.initData = function (...)
    orig_initData(...)
    local bb = GetNPCBlackboard(ConvertStringTo64Bit(tostring(C.GetPlayerID())), "$fv_cbp_rb") or {}
    local price_factor = tonumber(bb.price_scaling_factor) or 10  -- percent
    local min_price = tonumber(bb.min_price) or 1000
    local percent = price_factor / 100.0
    if menu.table_wares then apply_scaling_to_table(menu.table_wares, percent, min_price) end
    if menu.offerlist   then apply_scaling_to_table(menu.offerlist,   percent, min_price) end
    if menu.datalist    then apply_scaling_to_table(menu.datalist,    percent, min_price) end
  end
  return true
end

local function Init()
  local menu, id = get_menu()
  if not menu then
    if Lib and Lib.CallAfter then Lib.CallAfter(0.5, Init) end
    return
  end
  patch_menu(menu)
end

Init()
