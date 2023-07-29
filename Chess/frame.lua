function _G.ChessInitData.mousePosition(self)
  local scale = self:GetEffectiveScale()
  local x, y = GetCursorPosition()
  return x/scale-self:GetLeft(), y/scale-self:GetBottom()
end

local function hideParent(self)
  self:GetParent():Hide()
end

function _G.ChessInitData.closeButton(frame, script, w, h, x, y)
  local button = CreateFrame("Button", nil, assert(frame))
  button:SetWidth(w or 23)
  button:SetHeight(h or 23)
  button:SetPoint("TOPRIGHT", x or -3, y or -3)
  button:SetScript("OnClick", script or hideParent)
  button:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Up.blp")
  button:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Down.blp")
  button:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp")
  return button
end

function _G.ChessInitData.addText(frame, msg, size, r, g, b, a)
  local text = frame:CreateFontString(nil, "OVERLAY")
  text:SetFont(STANDARD_TEXT_FONT, size or 14)
  text:SetTextColor(r or 1, g or 1, b or 1, a or 1)
  text:SetText(msg or "")
  return text
end

_G.ChessInitData.edge =
 {
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border.blp", 
  edgeSize = 16, 
  insets =
   {
    left = 4,
    right = 4,
    top = 4,
    bottom = 4
   }
 }
