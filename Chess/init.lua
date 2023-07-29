local addonName, addonData = ...
local volatile = {}
addonData.VARS = volatile
addonData.VARS.CHESS_PREFIX = "SChs"

local special_names = {P=UnitName("player"), C="Computer"}

_G.ChessInitData =
 {
  piece_enum = {},
  special_names = special_names
 }

local lang = GetLocale():match("^..")

if lang == "de" then
  special_names.C = "Ordinateur"
elseif lang == "fr" then
  special_names.C = "Ordinateur"
elseif lang == "zh" then
  special_names.C = "计算机"
elseif lang == "ko" then
  special_names.C = "컴퓨터"
elseif lang == "es" then
  special_names.C = "Ordenador"
end
