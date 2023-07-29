local free_tables = setmetatable({}, {__mode="k"})
local free_textures = {}
local next, pairs = next, pairs

local used = 0

_G.ChessInitData.newTable = function()
  used = used + 1
  local tbl = next(free_tables)
  if tbl then
    for key in pairs(tbl) do tbl[key] = nil end
    free_tables[tbl] = nil
    return tbl
  else
    return {}
  end
end

_G.ChessInitData.deleteTable = function(tbl)
  
  free_tables[tbl] = true
  
  used = used-1
end

_G.ChessInitData.usedTables = function () return used end

local function texName(name)
  return "Interface\\AddOns\\Chess\\Textures\\"..name
end

_G.ChessInitData.texName = texName

_G.ChessInitData.newTexture = function(parent, texture, layer)
  local tex = next(free_textures)
  if tex then
    free_textures[tex] = nil
    tex:SetParent(parent)
    tex:SetDrawLayer(layer)
    tex:SetVertexColor(1,1,1)
    tex:SetAlpha(1)
    tex:Show()
  else
    tex = parent:CreateTexture(nil, layer)
  end
  
  if texture:find("[\\/]") then
    tex:SetTexture(texture)
  else
    tex:SetTexture(texName(texture))
  end
  
  return tex
end

_G.ChessInitData.deleteTexture = function(tex)
  tex:SetTexture(1,1,1)
  tex:Hide()
  tex:ClearAllPoints()
  tex:SetParent(UIParent)
  
  free_textures[tex] = true
end
