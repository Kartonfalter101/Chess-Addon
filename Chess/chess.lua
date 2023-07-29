local host
local addonName, addonData = ...

local floor, pow, insert, remove = math.floor, math.pow, table.insert, table.remove

local special_names = _G.ChessInitData.special_names

local CHESS_MSG_PREFIX = addonData.VARS.CHESS_PREFIX
local COMPUTER = special_names.C
local PLAYER = special_names.P

local SOUND_BEGIN = "Sound/Interface/SheathWood.wav"
local SOUND_WIN = "Sound/Spells/PVPVictoryAlliance.wav"
local SOUND_LOSE = "Sound/Spells/PVPVictoryHorde.wav"
local SOUND_DRAW = "Sound/Spells/PolyMorphChicken.wav"
local SOUND_CHECK = "Sound/Spells/PVPWarning.wav"
local SOUND_MOVE = "Sound/Interface/iAbilitiesOpenA.wav"
local SOUND_CAPTURE = "Sound/Spells/KnockDown.wav"
local SOUND_OPPONENT_CHECK = "Sound/Spells/Disarm.wav"
local SOUND_OPPONENT_MOVE = "Sound/Interface/iAbilitiesCloseA.wav"
local SOUND_OPPONENT_CAPTURE = "Sound/Spells/Strike.wav"

Chess_Scores, Chess_Games = {}, {}

if UnitFactionGroup("player") == "Horde" then
  SOUND_WIN, SOUND_LOSE = SOUND_LOSE, SOUND_WIN
end

local nameToMove, moveToName, nameToFAN, moveToFAN =
  _G.ChessInitData.nameToMove,
  _G.ChessInitData.moveToName,
  _G.ChessInitData.nameToFAN,
  _G.ChessInitData.moveToFAN

local newTable, deleteTable, newTexture, deleteTexture =
  _G.ChessInitData.newTable,
  _G.ChessInitData.deleteTable,
  _G.ChessInitData.newTexture,
  _G.ChessInitData.deleteTexture

local texName = _G.ChessInitData.texName
local mousePosition = _G.ChessInitData.mousePosition
local closeButton = _G.ChessInitData.closeButton
local addText = _G.ChessInitData.addText
local edge = _G.ChessInitData.edge

local doMoveNoWeight = _G.ChessInitData.doMoveNoWeight
local calcScore = _G.ChessInitData.calcScore
local usedTables = _G.ChessInitData.usedTables

local wcheck, bcheck = _G.ChessInitData.white_check, _G.ChessInitData.black_check

local newState, deleteState = _G.ChessInitData.newState, _G.ChessInitData.deleteState
local stateID = _G.ChessInitData.stateID

local lfg = _G.ChessInitData.startOpponentSearch
local requestPeerGame = _G.ChessInitData.requestPeerGame
local acceptPeerGame = _G.ChessInitData.acceptPeerGame

local saved_frame = _G.ChessInitData.saved_frame

local insert, remove, concat = table.insert, table.remove, table.concat

local currentBoard = nil
local requestAccepted = false

local function nop()
  -- Do nothing.
end

_G.ChessInitData.piece_enum[0] = nop

local black_piece_enum, white_piece_enum = {}, {}

for i, f in pairs(_G.ChessInitData.piece_enum) do
  black_piece_enum[i] = i <= 0 and f or nop
  white_piece_enum[i] = i >= 0 and f or nop
end

deleteTable(_G.ChessInitData)
_G.ChessInitData = nil

function array_reverse(x)
  local n, m = #x, #x/2
  for i=1, m do
    x[i], x[n-i+1] = x[n-i+1], x[i]
  end
  return x
end

local function fixName(name)
  if name == COMPUTER then return "$C" end
  if name == PLAYER then return "$P" end
  return name
end

local function unfixName(name)
  return name:gsub("^%$(.*)", special_names)
end

local shown_games = {}

local function getRank(player)
  local data = Chess_Scores[fixName(player)]
  return data and data.score or 1500
end

local function updateTitle(board)
  local white, black = board.white, board.black
  local title = board.title
  local win = floor(100/(pow(1.005508175372867895200298542232616618601857700543802594511080305, getRank(black) - getRank(white))+1)+.5)
  
  local extra = ""
  if board.status == "finished" then
    extra = " loses - You win"
    if board.winner == "white" and white ~= PLAYER then
      extra = " wins - You lose"
    elseif board.winner == "black" and black ~= PLAYER then
      extra = " wins - You lose"
    elseif board.winner == "draw" then
      extra = " - Draw game"
    end
  end
  
  enemyName = "CONNECTION LOST"
  if black ~= nil and GetUnitName(black, false) ~= GetUnitName(PLAYER, false) then
    enemyName = black:gsub("%-.*", "")
  end

  if white ~= nil and GetUnitName(white, false) ~= GetUnitName(PLAYER, false) then
    enemyName = white:gsub("%-.*", "")
  end

  title:SetFormattedText("  " .. enemyName .. extra)
end

local function addGameResult(white, black, result)
  white, black = fixName(white), fixName(black)
  
  if white ~= black and result ~= "invalid" then
    local wdata, bdata = Chess_Scores[white], Chess_Scores[black]
    
    if not wdata then
      wdata = {score=1500, win=0, lose=0, draw=0}
      Chess_Scores[white] = wdata
    end
    
    if not bdata then
      bdata = {score=1500, win=0, lose=0, draw=0}
      Chess_Scores[black] = bdata
    end
    
    local wwin, bwin
    
    if result == "white" then
      wdata.win = wdata.win + 1
      bdata.lose = bdata.lose + 1
      wwin, bwin = 1, 0
    elseif result == "black" then
      wdata.lose = wdata.lose + 1
      bdata.win = bdata.win + 1
      wwin, bwin = 0, 1
    elseif result == "draw" then
      wdata.draw = wdata.draw + 1
      bdata.draw = bdata.draw + 1
      wwin, bwin = .5, .5
    else
      error("Unknown game result '"..(tostring(result) or "nil") .."'.")
    end
    
    local qw, qb = pow(10, wdata.score/419.1807), pow(10, bdata.score/419.1807)
    local points = wwin*32-qw*32/(qw+qb)
    wdata.score, bdata.score = wdata.score + points, bdata.score - points
    
    for board in pairs(shown_games) do
      updateTitle(board)
    end
  end
end

local free_boards, peer_games = {}, {}

local function getBoardData(board)
  local data = newTable()
  
  insert(data, fixName(board.white))
  insert(data, fixName(board.black))
  insert(data, ("%x"):format(time()))
  
  local state = board.state
  
  if state.n == 0 then
    deleteTable(data)
    return
  end
  
  for n=-1,state.n,-1 do
    assert(state[n])
    insert(data, state[n])
  end
  
  if board.status == "finished" then
    if board.winner == "white" then
      insert(data, "1-0")
    elseif board.winner == "black" then
      insert(data, "0-1")
    elseif board.winner == "draw" then
      insert(data, "½-½")
    else
      deleteTable(data)
      return
    end
  elseif board.status == "running" then
    if board == (board.white ~= PLAYER and peer_games[board.white]) or
       board == (board.black ~= PLAYER and peer_games[board.black]) then
      deleteTable(data)
      return
    else
      insert(data, "not-finished")
    end
  end
  
  local data_str = concat(data, " ")
  deleteTable(data)
  return data_str
end

local function saveBoard(board)
  local data = getBoardData(board)
  
  if data then
    insert(Chess_Games, data)
  end
end

local events = {}

local function onEvent(self, event, ...)
  return events[event](self, ...)
end

local id2tex = {"p.blp", "r.blp", "n.blp", "b.blp", "q.blp", "k.blp"}

local function pieceTexture(id)
  if id > 0 then
    return texName("w"..id2tex[id])
  elseif id < 0 then
    return texName("b"..id2tex[-id])
  end
end

local function removeHighlightTexture(id)
  offset = floor(id / 8)
  if (id + offset) / 2 % 1 == 0 then
    return texName("b.tga")
  else
    return texName("w.tga")
  end
end

local function moveHighlightTexture(id)
  offset = floor(id / 8)
  if (id + offset) / 2 % 1 == 0 then
    return texName("blackhighlight.tga")
  else
    return texName("whitehighlight.tga")
  end
end

local function redrawPieces(self)
end

local function redrawBoard(self)
  if self.changes.pos ~= self.changes.next then
    return
  end

  local fg = self.fg
  for key in pairs(fg) do
    deleteTexture(key)
    fg[key] = nil
  end

  local state = self.state
  for i = 0, 63 do
    local n
    if host ~= nil then
      n = state[i]
    else
      n = state[#state - i]
    end

    local tex
    if host ~= nil then
      tex = fg[i]
    else
      tex = fg[-i]
    end

    if n ~= 0 then
      if not tex then
        tex = newTexture(self, pieceTexture(n), "OVERLAY")
        tex:SetSize(32,32);
        if host ~= nil then
          fg[i] = tex
        else
          fg[#state - i] = tex
        end
      else
        tex:ClearAllPoints()
        tex:SetTexture(pieceTexture(n))
      end
      
      tex:SetPoint("BOTTOMLEFT", (i)%8*32+3, floor((i)/8)*32+23)
    elseif tex then
      deleteTexture(tex)
      fg[i] = nil
    end
  end
  
  local animations = self.animations
  
  if animations then
    for tex, data in pairs(animations) do
      animations[tex] = nil
      deleteTable(data)
    end
    
    deleteTable(animations)
    self.animations = nil
  end
end

local addAnimation, destroyBoard, finishGame, makePromoteMove, redrawHistory

local function getPeer(board)
  if board.white ~= PLAYER and board.white ~= COMPUTER then
    return board.white
  elseif board.black ~= PLAYER and board.black ~= COMPUTER then
    return board.black
  end
end

local function animateMove(board, origin1, dest1, type1, promote1, origin2, ...)
  local fg = board.fg
  
  if origin2 then
    animateMove(board, origin2, ...)
  end
  
  if origin1 then
    local piece = fg[origin1]
    if type1 == 0 then
      piece = newTexture(board, pieceTexture(promote1), "OVERLAY")
      piece:SetWidth(32)
      piece:SetHeight(32)
      piece:SetAlpha(1)
      piece:SetPoint("BOTTOMRIGHT", origin1%8*32+3, floor(origin1/8)*32+23)
    else
      piece = fg[origin1]
      assert(piece)
      fg[origin1] = nil
    end
    
    if promote1 ~= 0 then
      fg[dest1] = piece
    end
    
    if host == nil then
      addAnimation(board, piece, 63-origin1, 63-dest1, pieceTexture(promote1), pieceTexture(type1))
    end
    
    if host ~= nil then
      addAnimation(board, piece, origin1, dest1, pieceTexture(promote1), pieceTexture(type1))
    end
  end
end

local function makeMove(board, move)
  local state = board.state
  local name, ret = moveToName(state, move)
  local fg = board.fg
  local changes = board.changes
  local pos, next = changes.pos, changes.next
  
  local origin1, dest1, type1, promote1,
        origin2, dest2, type2, promote2 = doMoveNoWeight(state, move)
  
  changes[next  ], changes[next+1], changes[next+2], changes[next+3] = origin1, dest1, type1, promote1
  changes[next+4], changes[next+5], changes[next+6], changes[next+7] = origin2, dest2, type2, promote2
  
  next = next+8
  changes.next = next
  
  while pos ~= next do
    animateMove(board, unpack(changes, pos, pos+7))
    pos = pos + 8
  end
  
  changes.pos = pos
  board.prev:Enable()
  board.next:Disable()
  
  local n = state.n
  state[n] = name
  local prefix
  local peer
  
  if n%2 == 0 then
    prefix = (n/-2).."... "
    peer = board.white
    board.title:SetTextColor(1, 1, 1)
    board.title_bg:SetVertexColor(0, 0, 0, 1)
  else
    prefix = (n/-2+.5)..". "
    peer = board.black
    board.title:SetTextColor(1, 1, 1)
    board.title_bg:SetVertexColor(0, 0, 0, 1)
  end
  
  local my_move = (board.white == board.black) or peer ~= PLAYER
  
  if name:find("%+$") then
    PlaySoundFile(my_move and SOUND_OPPONENT_CHECK or SOUND_CHECK)
  elseif name:find("x") then
    PlaySoundFile(my_move and SOUND_CAPTURE or SOUND_OPPONENT_CAPTURE)
    board.move50 = board.state.n-50
  else
    if name:find("^[^RNBQK]") then
      board.move50 = board.state.n-50
    end
    
    PlaySoundFile(my_move and SOUND_MOVE or SOUND_OPPONENT_MOVE)
  end
  
  if peer ~= COMPUTER and peer ~= PLAYER then
    C_ChatInfo.SendAddonMessage(CHESS_MSG_PREFIX, "m:"..name, "PARTY", peer)
  end
  
  if ret then
    finishGame(board, ret)
  end
  
  board.requested_draw = nil
  
  local id = stateID(board.state)
  local rep = (board.old_states[id] or 0)+1
  board.old_states[id] = rep
  
  if board.state.n <= board.move50 or rep >= 3 then
    board.draw:SetText("Claim Draw")
  else
    board.draw:SetText("Offer Draw")
  end
  
  if board.status ~= "finished" and
     ((board.white == PLAYER and board.state.n%2 == 0) or
      (board.black == PLAYER and board.state.n%2 ~= 0)) then
    board.draw:Enable()
  else
    board.draw:Disable()
  end
  redrawHistory(board.history)
end

local function finishMove(self, i)
  local moves = self.moves
  local state = self.state
  
  if moves then
    local origin = self.origin
    self.moves = nil
    self.origin = nil
    
    local bg = self.bg
    
    for ii = 1,#moves do
      local dest = moves[ii]
      
      if dest == i then
        for ii = ii,#moves do
          bg[moves[ii]]:SetTexture(removeHighlightTexture(moves[ii]))
        end
        
        deleteTable(moves)
        
        local n = state[origin]
        
        if (n == 1 and dest > 55) or (n == -1 and dest < 8) then
          makePromoteMove(self, origin*64+dest)
        else
          makePromoteMove(self, nil)
          makeMove(self, origin*64+dest)
        end
        
        return true
      end
      
      bg[dest]:SetTexture(removeHighlightTexture(dest))
    end
    
    deleteTable(moves)
  end
end

local function mouseCell(self)
  local x, y = mousePosition(self)
  local file, rank = floor((x-3)/32), floor((y-23)/32)
  if file >= 0 and rank >= 0 and file < 8 and rank < 8 then
    if host ~= nil then
      return file+rank*8;
    else
      return 63-(file+rank*8)
    end
  end
end

local function onMouseUp(self)
  local i = mouseCell(self)

  if i ~= self.origin then
    finishMove(self, i)
  end
  
  self:SetScript("OnMouseUp", nil)
end

local top

function raise(board)
  if top ~= board then
    if top then
      local s = top:GetEffectiveScale()
      top.x, top.y = top:GetLeft()/s, top:GetBottom()/s
      
      top:SetScale(2)
      top:SetAlpha(1)
      top.history:Hide()
      
      s = top:GetEffectiveScale()
      
      if top.mx then
        top:ClearAllPoints()
        top:SetPoint("BOTTOMLEFT", UIParent, top.mx*s, top.my*s)
      end
    end

    if board then
      if board.x then
        local s = board:GetEffectiveScale()
        board.mx, board.my = board:GetLeft()/s, board:GetBottom()/s
      end
      
      board:Raise()
      board:SetScale(1)
      board:SetAlpha(1)
       
      if board.status == "finished" or board.changes.pos ~= board.changes.next then
      end
      
      local s = board:GetEffectiveScale()
      
      if board.x then
        board:ClearAllPoints()
        board:SetPoint("BOTTOMLEFT", UIParent, board.x*s, board.y*s)
      end
    end
    
    top = board
  end
end

scaled = false

local function scaleBoard()
  if scaled == false then
    scaled = true
    top:SetScale(2)
    return
  end

  if scaled == true then
    scaled = false
    top:SetScale(1)
  end
end

local function onMouseDown(self, btn)
  local i = mouseCell(self)
  
  if not i or top ~= self then
    if btn == "RightButton" then
      scaleBoard()
      return
    end
    
    self:StartMoving()
    self:SetScript("OnMouseUp", self.StopMovingOrSizing)
    return
  end
  
  raise(self)
  
  if self.status == "finished" or self.changes.pos ~= self.changes.next then
    return
  end
  
  if finishMove(self, i) then
    return
  end
  
  local state = self.state
  local moves = newTable()
  local bg = self.bg
  
  if state.n%2 == 0 and self.white == PLAYER then
    white_piece_enum[state[i]](i, state, moves, state.wk)
  elseif state.n%2 == 1 and self.black == PLAYER then
    black_piece_enum[state[i]](i, state, moves, state.bk)
  end
  
  if not moves[1] then
    deleteTable(moves)
    self:StartMoving()
    self:SetScript("OnMouseUp", self.StopMovingOrSizing)
  else
    self.origin = i
    self.moves = moves

    for ii = 1,#moves 
      do bg[moves[ii]]:SetTexture(moveHighlightTexture(moves[ii]))
    end
    
    self:SetScript("OnMouseUp", onMouseUp)
  end
end

finishGame = function(board, ending)
  requestAccepted = false
  if board.status ~= "finished" then
    if board.state.n%2 == 0 then
      board.title:SetTextColor(.2, .2, .2)
      board.title_bg:SetVertexColor(0, 0, 0, 1)
    else
      board.title:SetTextColor(.8, .8, .8)
      board.title_bg:SetVertexColor(0, 0, 0, 1)
    end
    
    makePromoteMove(board, nil)
    
    if not ending then
      local peer = getPeer(board)
      
      if (board.state.n <= board.move50 or board.old_states[stateID(board.state)] >= 3) and
         ((board.state.n%2 == 0 and board.white == PLAYER) or
          (board.state.n%2 ~= 0 and board.black == PLAYER)) then
        if peer then C_ChatInfo.SendAddonMessage(CHESS_MSG_PREFIX, "m:½-½", "PARTY", peer) end
        ending = "draw"
      elseif board.white == peer then
        if peer then C_ChatInfo.SendAddonMessage(CHESS_MSG_PREFIX, "m:1-0", "PARTY", peer) end
        ending = "white"
      else
        if peer then C_ChatInfo.SendAddonMessage(CHESS_MSG_PREFIX, "m:0-1", "PARTY", peer) end
        ending = "black"
      end
    end
    
    for peer, game_board in pairs(peer_games) do
      if game_board == board then
        peer_games[peer] = nil
      end
    end
    
    if board.state.n > -2 then
      ending = "invalid"
    end
    
    if ending == "draw" then
      PlaySoundFile(SOUND_DRAW)
      DEFAULT_CHAT_FRAME:AddMessage("|c0000ff02[Chess]:|r |c00FFFFFFDraw Game.|h")
    elseif ending ~= "invalid" then     
      if board.white == board.black or (board.white == PLAYER and ending == "white") or (board.black == PLAYER and ending == "black") then
        DEFAULT_CHAT_FRAME:AddMessage("|c0000ff02[Chess]:|r |c00FFFFFFYou win.|h")
      else
        DEFAULT_CHAT_FRAME:AddMessage("|c0000ff02[Chess]:|r |c00FFFFFFYou lose.|h")
      end
    else
      DEFAULT_CHAT_FRAME:AddMessage("|c0000ff02[Chess]:|r |c00FFFFFFNobody made a move, game closed.|h")
    end
    
    board.status = "finished"
    board.winner = ending
    board.resign:Disable()
    board.draw:Disable()
    
    updateTitle(board)
    addGameResult(board.white, board.black, ending)
    saveBoard(board)
  end
end

destroyBoard = function(board)
  finishGame(board)
  board:Hide()
  board.history:Hide()
  shown_games[board] = nil
  
  if board.bg == nil then
    return
  end
  
  for i=0, 63 do deleteTexture(board.bg[i]) end
  deleteTable(board.bg)
  board.bg = nil

  deleteTexture(board.title_bg)
  board.title_bg = nil
  
  deleteTable(board.changes)
  board.changes = nil
  
  for i, tex in pairs(board.fg) do deleteTexture(tex) end
  deleteTable(board.fg)
  board.fg = nil
  
  if board.moves then
    deleteTable(board.moves)
    board.moves = nil
  end
  
  if top == board then top = nil end
  
  free_boards[board] = true
  
  deleteState(board.state)
  board.state = nil
  
  deleteTable(board.old_states)
  board.old_states = nil
  
  local animations = board.animations
  
  if animations then
    for tex, data in pairs(animations) do
      animations[tex] = nil
      deleteTable(data)
    end
    
    deleteTable(animations)
    board.animations = nil
  end
  
  board:Hide()
  
  for key in pairs(events) do
    board:UnregisterEvent(key)
  end
  
  board:SetScript("OnEvent", nil)
  board:SetScript("OnUpdate", nil)
end

local function onUpdate(self, delta)
  local running = false
  
  if self.ai then
    running = true
    local state = self.state
    
    local make_move = true
    
    if not state.states or usedTables() < 15000 then
      make_move = false
      for i = 1,15 do if calcScore(state) then make_move = true break end end
    end
    
    if make_move then
      if state.states == 63 then
        self.ai = false
        running = false
      else
        local move = state[state.states].move
        local n, dest = state[floor(move/32)], move%32
        
        if (n == 1 and dest > 55) or (n == -1 and dest < 8) then
          move = move + 16384
        end
        
        if (state.n%2 == 0 and self.white == COMPUTER) or (state.n%2 ~= 0 and self.black == COMPUTER) then
          makeMove(self, move)
        end
      end
    end
  end
  
  local animations = self.animations
  
  if animations then
    for tex, data in pairs(animations) do
      local x, y = data[1], data[2]
      local i, n = 3,#data
      while i < n do
        local pct, x2, y2 = unpack(data, i, i+2)
        pct = pct + delta*1.8
        
        if pct >= 1 then
          data.otex = data.tex
          
          x, y = x2, y2
          if i == 3 then
            remove(data, i+2)
            remove(data, i+1)
            remove(data, i)
            n = n - 3
            data[1], data[2] = x, y
          else
            data[i] = 1
            i = i+3
          end
        else
          assert(pct >= 0 and pct <= 1)
          data[i] = pct

          if pct < 0.5 then
            pct = 2*pct*pct
          else
            pct = 4*pct - 2*pct*pct - 1
          end
          
          local ipct = 1-pct
          x = x*ipct+x2*pct
          y = y*ipct+y2*pct
          i = i+3
        end
      end
      
      tex:ClearAllPoints()
      tex:SetPoint("BOTTOMLEFT", x, y)
      
      if n == 2 then
        if data.tex then
          tex:SetTexture(data.tex)
        else
          deleteTexture(tex)
        end
        
        deleteTable(data)
        animations[tex] = nil
      else
        local alpha = 1
        
        if not data.otex then
          alpha = alpha * data[3]
        end
        
        if not data.tex then
          alpha = alpha * 1-data[n-2]
        end
        
        tex:SetAlpha(alpha)
      end
    end
    
    if not next(animations) then
      deleteTable(animations)
      self.animations = nil
    end
  elseif not running then
    self:SetScript("OnUpdate", nil)
  end
end

addAnimation = function(board, piece, origin, dest, tex, otex)
  local animations = board.animations
  if not animations then
    animations = newTable()
    board.animations = animations
  end
  
  local data = animations[piece]
  if not data then
    data = newTable()
    animations[piece] = data
    data[1], data[2] = origin%8*32+3, floor(origin/8)*32+23
  end
  
  insert(data, 0)
  insert(data, dest%8*32+3)
  insert(data, floor(dest/8)*32+23)
  
  data.tex, data.otex = tex, otex
  
  board:SetScript("OnUpdate", onUpdate)
end

local function onClick(self)
  destroyBoard(self:GetParent())
end

local function onResign(self)
  finishGame(self:GetParent())
end

local function onDraw(self)
  self:Disable()
  local board = self:GetParent()
  
  if not ((board.state.n%2 == 0 and board.white == PLAYER) or
     (board.state.n%2 ~= 0 and board.black == PLAYER)) then
    finishGame(board, "draw")
  elseif board.state.n <= board.move50 or board.old_states[stateID(board.state)] >= 3 then
    finishGame(board, "draw")
  else
    board.requested_draw = true
  end
  
  local peer = getPeer(board)
  
  if peer then
    C_ChatInfo.SendAddonMessage(CHESS_MSG_PREFIX, "m:½-½", "PARTY", peer)
  else
    if (board.white == COMPUTER or board.black == COMPUTER) and board.state.n < board.move50 + 25 then
      finishGame(board, "draw")
    elseif board.white == PLAYER and board.black == PLAYER then
      finishGame(board, "draw")
    end
  end
end

local function startChat(self)
  local peer = getPeer(self:GetParent())
  if peer then
    ChatFrame_SendTell(peer)
  end
end

local function onAdvance(self)
  local board = self:GetParent()
  local changes = board.changes
  local pos, next = changes.pos, changes.next
  if pos ~= next then
    if pos == 1 then
      board.prev:Enable()
    end
    
    animateMove(board, unpack(changes, pos, pos+7))
    pos = pos+8
    changes.pos = pos
    
    if pos == next then
      self:Disable()
    end
    
    if pos == next and board.status ~= "finished" then
      if pos%16 == 1 then
        board.title:SetTextColor(0, 0, 0)
        board.title_bg:SetVertexColor(0, 0, 0, 1)
      else
        board.title:SetTextColor(1, 1, 1)
        board.title_bg:SetVertexColor(0, 0, 0, 1)
      end
    else
      if pos%16 == 1 then
        board.title:SetTextColor(1, 1, 1)
        board.title_bg:SetVertexColor(0, 0, 0, 1)
      else
        board.title:SetTextColor(1, 1, 1)
        board.title_bg:SetVertexColor(0, 0, 0, 1)
      end
    end
    
    redrawHistory(board.history)
  end
end

local function onRegress(self)
  local board = self:GetParent()
  local changes = board.changes
  local pos = changes.pos
  if pos ~= 1 then
    if pos == changes.next then
      board.next:Enable()
    end
    
    pos = pos - 8
    changes.pos = pos
    
    local origin1, dest1, type1, promote1, origin2, dest2, type2, promote2 = unpack(changes, pos, pos+7)
    
    animateMove(board, dest2, origin2, promote2, type2, dest1, origin1, promote1, type1)
    
    if pos == 1 then
      self:Disable()
    end
    
    if pos%16 == 1 then
      board.title:SetTextColor(1, 1, 1)
      board.title_bg:SetVertexColor(0, 0, 0, 1)
    else
      board.title:SetTextColor(1, 1, 1)
      board.title_bg:SetVertexColor(0, 0, 0, 1)
    end
    
    redrawHistory(board.history)
  end
end

local free_history_buttons = {}

local function historyButtonOnClick(self)
  local history = self:GetParent()
  local board = history:GetParent()
  local index, cur_index = self.index, (board.changes.pos-1)/8
  
  if index ~= cur_index then
    history.defer_redraw = true
    
    if index < cur_index then
      for i = 1,cur_index-index do onRegress(board.prev) end
    else
      for i = 1,index-cur_index do onAdvance(board.next) end
    end
    
    history.defer_redraw = nil
    redrawHistory(history)
  end
end

redrawHistory = function(self)
  if not self:IsVisible() or self.defer_redraw then return end
  
  local board = self:GetParent()
  
  local buttons = self.buttons
  if not buttons then
    buttons = {}
    self.buttons = buttons
  end
  
  for button in pairs(buttons) do
    button:Hide()
    free_history_buttons[button] = true
    buttons[button] = nil
  end
  
  if board.changes == nil then
    return
  end
  local cur_move = (board.changes.pos-1)/8
  local last_move = -board.state.n
  
  local max_moves = math.min(floor((self:GetHeight()-32)/20), last_move+1)
  local base_index = cur_move-math.floor(max_moves/2)
  
  if base_index+max_moves > last_move then base_index = last_move - max_moves + 1 end
  if base_index < 0 then base_index = 0 end
  
  for i = 1,max_moves do
    local index = i+base_index-1
    local name
    
    if index == 0 then
      name = "0..."
    elseif index%2 == 1 then
      name = (index+1)/2 .. ". " .. nameToFAN(board.state[-index])
    else
      name = index/2 .. "..." .. nameToFAN(board.state[-index])
    end
    
    local button = next(free_history_buttons)
    
    if not button then
      button = CreateFrame("Frame", nil, self)
      button:EnableMouse(true)
      button:SetScript("OnMouseDown", historyButtonOnClick)
      button.bg = button:CreateTexture(nil, "BACKGROUND")
      button.bg:SetTexture(1, 1, 1)
      button.bg:SetAllPoints()
      button.text = addText(button, "Hello, World!", 14)
      button.text:SetFont("Fonts\\ARIALN.TTF", 14)
      button.text:SetJustifyH("LEFT")
      button.text:SetJustifyV("MIDDLE")
      button.text:SetAllPoints()
      button.text:SetVertexColor(1,1,0)
    else
      free_history_buttons[button] = nil
      button:SetParent(self)
    end
    
    buttons[button] = true
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", self, "TOPLEFT", 6, -8-i*20)
    button:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -6, -28-i*20)
    button.text:SetText(name)
    button.index = index
    
    if index == cur_move then
      button.bg:SetVertexColor(0,0.5,1,0.5)
    elseif index%2 == 1 then
      button.bg:SetVertexColor(0.5,0.5,0.5,0.2)
    else
      button.bg:SetVertexColor(0,0,0,0.2)
    end
    
    button:Show()
  end
end

local function scrollHistory(self, arg)
  if arg == -1 then
    onAdvance(self.next)
  elseif arg == 1 then
    onRegress(self.prev)
  end
end

local function createBoard(white, black)
  requestAccepted = true
  local board, data, winner = nil, nil, nil
  if black then
    board = (white ~= PLAYER and peer_games[white]) or (black ~= PLAYER and peer_games[black])
    
    if board then
      raise(board)
      return
    end
  else
    local save_data = white
    white, black, data, ending = save_data:match("^(.-) (.-) .- (.-) ([^ ]+)$")
    
    if not white then
      data = nil
      white, black, ending = save_data:match("^(.-) (.-) .- (.-)$")
    end
    
    if not white then
      return
    end
    
    white, black = unfixName(white), unfixName(black)
    
    if ending == "1-0" then
      winner = "white"
    elseif ending == "0-1" then
      winner = "black"
    elseif ending == "½-½" or ending == "1/2-1/2" then
      winner = "draw"
    elseif ending == "invalid" then
      winner = "invalid"
    else
      winner = nil
    end
  end
  
  board = next(free_boards)
  
  if board then
    free_boards[board] = nil
  else
    board = CreateFrame("Frame", nil, UIParent)
    local title = addText(board, "", 16)
    title:SetPoint("LEFT")
    title:SetPoint("TOP", board, "TOP", 0, -5)
    title:SetPoint("BOTTOM", board, "TOP", 0, -22)
    
    board.title = title
    
    closeButton(board, onClick)
    
    local history = CreateFrame("Frame", nil, board)
    board.history = history
    board:EnableMouseWheel(true)
    board:SetScript("OnShow", redrawHistory)
    board:SetScript("OnMouseWheel", scrollHistory)
    board:SetScript("OnKeyUp",function(self, key)
      board:SetPropagateKeyboardInput(false)
    end)
    board:SetScript("OnKeyDown",function(self, key)
      if key == "LEFT" then
        onRegress(self.prev)
      elseif key == "RIGHT" then
        onAdvance(self.next)
      end
      board:SetPropagateKeyboardInput(true)
    end)
    history:Hide()
    
    history:SetPoint("TOPLEFT", board, "TOPRIGHT", -6, 0)
    history:SetSize(150, 64*8+46)
    closeButton(history)
    
    title = addText(history, "Move History", 12, 0, 0, 0)
    title:SetPoint("CENTER")
    title:SetPoint("TOP", history, "TOP", 0, -5)
    title:SetPoint("BOTTOM", history, "TOP", 0, -22)
    
    local bg = newTexture(history, "title.tga", "BACKGROUND")
    bg:SetPoint("TOPLEFT", 3, -3)
    bg:SetPoint("BOTTOMRIGHT", history, "TOPRIGHT", -3, -23)
    bg:SetVertexColor(1, 1, 1)
    bg = history:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", history, "TOPLEFT", 0, -23)
    bg:SetPoint("BOTTOMRIGHT", history)
    bg:SetAlpha(.3)
    bg:SetTexture(0, 0, 0)
    
    local button = CreateFrame("Button", nil, board)
    button:SetWidth(20)
    button:SetHeight(20)
    button:SetPoint("BOTTOMRIGHT", -4, 4)
    button:SetScript("OnClick", onAdvance)
    button:SetNormalTexture("Interface\\BUTTONS\\UI-SpellbookIcon-NextPage-Up.blp")
    button:SetPushedTexture("Interface\\BUTTONS\\UI-SpellbookIcon-NextPage-Down.blp")
    button:SetDisabledTexture("Interface\\BUTTONS\\UI-SpellbookIcon-NextPage-Disabled.blp")
    button:SetHighlightTexture("Interface\\BUTTONS\\UI-Common-MouseHilight.blp")
    board.next = button
    
    button = CreateFrame("Button", nil, board)
    button:SetWidth(20)
    button:SetHeight(20)
    button:SetPoint("BOTTOMRIGHT", -26, 4)
    button:SetScript("OnClick", onRegress)
    button:SetNormalTexture("Interface\\BUTTONS\\UI-SpellbookIcon-PrevPage-Up.blp")
    button:SetPushedTexture("Interface\\BUTTONS\\UI-SpellbookIcon-PrevPage-Down.blp")
    button:SetDisabledTexture("Interface\\BUTTONS\\UI-SpellbookIcon-PrevPage-Disabled.blp")
    button:SetHighlightTexture("Interface\\BUTTONS\\UI-Common-MouseHilight.blp")
    board.prev = button
    
    button = CreateFrame("Button", nil, board, "UIPanelButtonTemplate")
    button:SetHeight(20)
    button:SetWidth(100)
    button:SetText("Resign")
    button:SetPoint("BOTTOMLEFT", 4, 4)
    button:SetScript("OnClick", onResign)
    board.resign = button
    
    button = CreateFrame("Button", nil, board, "UIPanelButtonTemplate")
    button:SetHeight(20)
    button:SetWidth(100)
    button:SetText("Draw")
    button:SetPoint("BOTTOMLEFT", 103, 4)
    button:Disable()
    button:SetScript("OnClick", onDraw)
    board.draw = button
    
    local bottom_pane = newTexture(board, "Interface\\TUTORIALFRAME\\TutorialFrameBackground.blp", "BACKGROUND")
    bottom_pane:SetPoint("BOTTOMLEFT", 3, 3)
    bottom_pane:SetPoint("TOPRIGHT", board, "BOTTOMRIGHT", -3, 23)
  end
  
  shown_games[board] = true
  
  board:ClearAllPoints()
  board:SetPoint("BOTTOMRIGHT", 0, 0)
  board:SetWidth(32*8+6)
  board:SetHeight(32*8+46)
  board:SetToplevel(true)
  
  board.white = white
  board.black = black
  board.title:SetTextColor(0, 0, 0)
  board.status = winner and "finished" or "running"
  board.winner = winner
  board.move50 = -50
  
  updateTitle(board)
  
  board.resign:Enable()
  board.draw:Disable()
  board.draw:SetText("Offer Draw")
  board.requested_draw = nil
  
  board.changes = newTable()
  board.changes.next = 1
  board.changes.pos = 1
  board.next:Disable()
  board.prev:Disable()
  
  local title_bg = newTexture(board, "title.tga", "BACKGROUND")
  board.title_bg = title_bg
  
  title_bg:SetPoint("TOPLEFT", 3, -3)
  title_bg:SetPoint("BOTTOMRIGHT", board, "TOPRIGHT", -3, -23)
  title_bg:SetVertexColor(0, 0, 0, 1)
  
  board.white = white
  board.black = black
  
  if PLAYER == white then
    host = black
  end

  local bg = newTable()
  board.bg = bg
  if host == nil then
    for i = 0,7 do
      for j = 0,7 do
        local tex = newTexture(board, ((i+j)%2==0 and "b.tga" or "w.tga"), "BACKGROUND")
        bg[i*8+j] = tex
        
        tex:SetWidth(32)
        tex:SetHeight(32)
        tex:SetAlpha(1)
        tex:SetPoint("TOPRIGHT", -j*32-3, -i*32-23)
      end
    end
  end
  
  if host ~= nil then
    for j = 0,7 do
      for i = 0,7 do
        local tex = newTexture(board, ((i+j)%2==0 and "b.tga" or "w.tga"), "BACKGROUND")
        bg[i*8+j] = tex
        
        tex:SetWidth(32)
        tex:SetHeight(32)
        tex:SetAlpha(1)
        tex:SetPoint("BOTTOMLEFT", j*32+3, i*32+23)
      end
    end
  end

  board.fg = newTable()
  
  board:SetScript("OnEvent", onEvent)
  
  for key in pairs(events) do
    board:RegisterEvent(key)
  end
  
  board:SetScript("OnMouseDown", onMouseDown)
  board:SetMovable(true)
  board:EnableMouse(true)
  
  board.state = newState()
  board.old_states = newTable()
  board.old_states[stateID(board.state)] = 1

  redrawBoard(board)
  
  if data then
    local state, old_states = board.state, board.old_states
    local changes = board.changes
    local n, next = 0, 1
    
    for name in data:gmatch("[^ ]+") do
      local move = nameToMove(state, name)
      if move == nil or move == true or move == false then
        DEFAULT_CHAT_FRAME:AddMessage(("|c0000ff02[Chess]:|r |c00FFFFFFHANDLED ERROR - Caught attempt to perform arithmetic on field 'move' | line 1373."))
        return
      end

      
      changes[next  ], changes[next+1], changes[next+2], changes[next+3],
      changes[next+4], changes[next+5], changes[next+6], changes[next+7] =
      doMoveNoWeight(state, move)
      
      local id = stateID(state)
      old_states[id] = (old_states[id] or 0) + 1
      
      if changes[next+2] == 1 or changes[next+2] == -1 then
        board.move50 = n-50
      end
      
      n = n - 1
      state.n = n
      state[n] = name
      next = next + 8
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(("|c0000ff02[Chess]:|r |c00FFFFFFRestored game session."))
    changes.pos, changes.next = next, next
    
    if next ~= 1 then
      board.prev:Enable()
    end
    
    for i = 1,next,8 do
      animateMove(board, unpack(changes, i, i+7))
    end
    
    if n%2 == 0 then
      board.title:SetTextColor(1, 1, 1)
      board.title_bg:SetVertexColor(0, 0, 0, 1)
    else
      board.title:SetTextColor(1, 1, 1)
      board.title_bg:SetVertexColor(0, 0, 0, 1)
    end
  end
  
  if board.state == "finished" then
    board.resign:Disable()
  end
  
  if board.state.n <= board.move50 or board.old_states[stateID(board.state)] >= 3 then
    board.draw:SetText("Claim Draw")
  else
    board.draw:SetText("Offer Draw")
  end
  
  if board.status ~= "finished" and
     ((board.white == PLAYER and board.state.n%2 == 0) or
      (board.black == PLAYER and board.state.n%2 ~= 0)) then
    board.draw:Enable()
  else
    board.draw:Disable()
  end
  
  if board.status == "running" and (white == COMPUTER or black == COMPUTER) then
    board:SetScript("OnUpdate", onUpdate)
    board.ai = true
  else
    board.ai = nil
  end
  
  raise(board)
  
  if InCombatLockdown() then
    board:Hide()
  else
    PlaySoundFile(SOUND_BEGIN)
    board:Show()
  end
  
  currentBoard = board
  return board, true
end

function events:PLAYER_REGEN_DISABLED()
 
end

function events:PLAYER_REGEN_ENABLED()

end

function events:PLAYER_LOGOUT()
  if self.status == "running" then
    
    if self == (self.white ~= PLAYER and peer_games[self.white]) or self == (self.black ~= PLAYER and peer_games[self.black]) then
      finishGame(self)
    else
      local data = getBoardData(self)
      
      if data then
        Chess_SuspendedGames = Chess_SuspendedGames or {}
        insert(Chess_SuspendedGames, data)
      end
    end
  end
end

local function remoteMove(board, peer, name)
  if board.status == "finished" then
    return
  end
  
  local state = board.state
  local move
  
  local first_move = state.n == 0
  
  if name == "0-1" and (board.white == peer or first_move) then
    finishGame(board, first_move and "white" or "black")
    return true
  end
  
  if name == "1-0" and board.black == peer then
    finishGame(board, "white")
    return true
  end
  
  if not first_move and not ((state.n%2 == 0 and board.white == peer) or
     (state.n%2 ~= 0 and board.black == peer)) then
    
    if not (board.requested_draw and name == "½-½") then
      return
    end
  end
  
  if not first_move and name == "½-½" then
    if board.requested_draw or board.state.n <= board.move50 or board.old_states[stateID(board.state)] >= 3 then
      finishGame(board, "draw")
      return true
    else
      board.draw:SetText("Accept Draw")
      board.draw:Enable()
      return true
    end
  end
  
  if first_move then
    move = nameToMove(state, name)
  elseif state.n%2 == 0 then
    if board.white == peer then
      move = nameToMove(state, name)
    end
  else
    if board.black == peer then
      move = nameToMove(state, name)
    end
  end
  
  if move then
    if first_move then
      updateTitle(board)
      
      local moves = board.moves
      
      if moves then
        local bg = board.bg
        
        for _, move in ipairs(moves) do
          bg[move]:SetAlpha(1)
        end
        
        deleteTable(moves)
        board.origin = nil
        board.moves = nil
      end
    end
    
    makeMove(board, move)
    return true
  end
  
  return move
end

function events.CHAT_MSG_ADDON(board, prefix, msg, dist, peer)
  if prefix == CHESS_MSG_PREFIX and dist == "PARTY" and peer == board.white or peer == board.black then
    for command in string.gmatch(msg, "[^|]+") do
      local func, data = command:match("^([^:]*):?(.*)")
      if func == "m" then
        if not remoteMove(board, peer, data) then
          DEFAULT_CHAT_FRAME:AddMessage(("|c0000ff02[Chess]:|r |c00FFFFFF" .. peer .. " made an invalid move."))
        end
      end
    end
  end
end

local function doLFG(peer)
  requestAccepted = true
  host = nil
  if currentBoard ~= nil then
    destroyBoard(currentBoard)
  end
  createBoard(peer, PLAYER)
end

local promote_frame = CreateFrame("Frame", nil, UIParent)

promote_frame:SetWidth(32*4+8)
promote_frame:SetHeight(32+8)
promote_frame:SetPoint("CENTER")
promote_frame:EnableMouse(true)
promote_frame:SetToplevel(true)

for i = 1,4 do
  local bg = newTexture(promote_frame, i%2==0 and "b.tga" or "w.tga", "BACKGROUND")
  bg:SetAlpha(1)
  bg:SetWidth(32)
  bg:SetHeight(32)
  bg:SetPoint("BOTTOMLEFT", 32*i-60, 4)
  
  local icon = newTexture(promote_frame, "b.tga", "OVERLAY")
  icon:SetWidth(32)
  icon:SetHeight(32)
  icon:SetPoint("BOTTOMLEFT", 32*i-60, 4)
  promote_frame[i] = icon
end

promote_frame:SetScript("OnShow", function (self) 
  self:ClearAllPoints()
  local x, y = GetCursorPosition()
  local scale = self:GetEffectiveScale()
  self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x/scale, y/scale)
end)

promote_frame:Hide()

local promotion_boards = {}

local showPromotion

promote_frame:SetScript("OnMouseDown", function (self)
  x, y = mousePosition(self)
  if y > 4 and y < 68 and x > 4 and x < 260 then
    local board = promote_frame.board
    makeMove(board, floor((x+60)/32)*4096+promotion_boards[board])
    promotion_boards[board] = nil
    showPromotion(next(promotion_boards))
  end
end)

showPromotion = function(board)
  promote_frame.board = board
  
  if board then
    local side = board.state.n%2 == 0 and 1 or -1
    
    for i = 1,4 do
      promote_frame[i]:SetTexture(pieceTexture((i+1)*side))
    end
    
    promote_frame:Show()
  else
    promote_frame:Hide()
  end
end

makePromoteMove = function(board, move)
  promotion_boards[board] = move
  if move then
    showPromotion(board)
  elseif promote_frame.board == board then
    showPromotion(next(promotion_boards))
  end
end

local menu = CreateFrame("Frame", nil, UIParent)

menu:Hide()
menu:SetPoint("CENTER")
menu:SetWidth(264)
menu:SetHeight(264)
menu:EnableMouse(true)
menu:SetMovable(true)
menu:SetToplevel(true)

for i, str in ipairs({"Past Games", "Find Opponent", "VS Target", "VS Computer White", "VS Computer Black"}) do
  local text = addText(menu, str, 18)
  text:SetPoint("BOTTOMLEFT", 52, 3+i*48-48)
  text:SetPoint("TOPRIGHT", menu, "BOTTOMRIGHT", -4, 3+i*48)
end

local frame = addText(menu, addonName)
frame:SetPoint("TOPRIGHT", -4, -4)
frame:SetPoint("BOTTOMLEFT", menu, "TOPLEFT", 4, -24)

closeButton(menu)

menu:SetScript("OnMouseDown", function(self, btn)
  local x, y = mousePosition(self)
  if btn == "LeftButton" and y >= 244 then self:StartMoving() end
end)

menu:SetScript("OnMouseUp", function(self, btn)
  self:StopMovingOrSizing()
  local x, y = mousePosition(self)
  if btn == "LeftButton" and x > 3 and x < 256 and y > 3 and y < 244 then
    local option = floor((y-3)/48)
    
    if option == 4 then
      createBoard(PLAYER, COMPUTER)
    end
    
    if option == 3 then
      createBoard(COMPUTER, PLAYER)
    end
    
    if option == 2 then
      if UnitIsPlayer("target") and UnitFactionGroup("target") == UnitFactionGroup("player") then
        if UnitIsUnit("target", "player") then
          createBoard(PLAYER, PLAYER)
        else
          local peer = GetUnitName("target", true)
          requestPeerGame(peer, doLFG)
        end
      else
        return
      end
    end
    
    if option == 1 then
      lfg(doLFG)
    end
    
    if option == 0 then
      saved_frame.loadGame = createBoard
      saved_frame:Show()
    end
    
    self:Hide()
  end
end)

menu:RegisterEvent("ADDON_LOADED")
menu:SetScript("OnEvent", function (self, event, arg)
  if event == "ADDON_LOADED" and arg == addonName then
  	local retOK = C_ChatInfo.RegisterAddonMessagePrefix(CHESS_MSG_PREFIX)
    if Chess_SuspendedGames then
      for i, data in ipairs(Chess_SuspendedGames) do
        raise(createBoard(data))
      end
      
      Chess_SuspendedGames = nil
    end
  end
end)

SLASH_CHESS1 = "/chess"

SlashCmdList["CHESS"] = function(cmd)
  if cmd == "" then
    if GetUnitName("target", true) == nil then
      DEFAULT_CHAT_FRAME:AddMessage(("|c0000ff02[Chess]:|r |c00FFFFFFYou don't have anyone targeted."))
      return
    end
    DEFAULT_CHAT_FRAME:AddMessage(("|c0000ff02[Chess]:|r |c00FFFFFFYou challenged " .. GetUnitName("target", true) .. "."))
    requestPeerGame(GetUnitName("target", true), doLFG)
  else
    DEFAULT_CHAT_FRAME:AddMessage(("|c0000ff02[Chess]:|r |c00FFFFFFYou challenged " .. cmd .. "."))
    requestPeerGame(cmd, doLFG)
  end
end

local orig_ChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow

function ChatFrame_OnHyperlinkShow(...)
  local type, data = (select(2, ...)):match("^(.-):(.*)$")
  if type == "chess" then
    if not requestAccepted then
      if currentBoard ~= nil then
        destroyBoard(currentBoard)
      end
      
      host = data
      local board, created = createBoard(PLAYER, data)

      if created then
        acceptPeerGame(data)
      end

      return
    else
      DEFAULT_CHAT_FRAME:AddMessage(("|c0000ff02[Chess]:|r |c00FFFFFFYou already accepted a game."))
    end
  end

  return orig_ChatFrame_OnHyperlinkShow(...)
end

