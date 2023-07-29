local new, delete = _G.ChessInitData.newTable, _G.ChessInitData.deleteTable
local floor = math.floor
local piece_enum = _G.ChessInitData.piece_enum

_G.ChessInitData.newState = function()
  local b = new()
  
  -- White pieces.
  b[0] = 2 --0
  b[1] = 3 --1
  b[2] = 4 --2
  b[3] = 5 --3
  b[4] = 6 --4
  b[5] = 4 --5
  b[6] = 3 --6
  b[7] = 2 --7
  
  -- White pawns.
  for i = 8,15 do b[i] = 1 end
  
  -- Empty space
  for i = 16,47 do b[i] = 0 end
  
  -- Black pawns
  for i = 48,55 do b[i] = -1 end
  
  -- Black pieces.
  b[56] = -2 --56
  b[57] = -3 --57
  b[58] = -4 --58
  b[59] = -5 --59
  b[60] = -6 --60
  b[61] = -4 --61
  b[62] = -3 --62
  b[63] = -2 --63
  
  b.wk = 4
  b.bk = 60
  
  b.wck = true -- king-side
  b.wcq = true -- queen-side
  b.bck = true -- king-side
  b.bcq = true -- queen-side
  
  b.n = 0
  
  b.score = 0
  return b
end

local function doMove(state, origin, dest, weight)
  local score = -weight[state[dest]]
  local n = state[origin]
  
  state[origin] = 0
  
  if n > 0 then
    if origin == 0 then state.wcq = nil end
    if origin == 7 then state.wck = nil end
    if dest == 56 then state.bcq = nil end
    if dest == 63 then state.bck = nil end

    if n == 6 then
      state.wk = dest
      
      if origin == 4 then
        if dest == 6 then
          state[7] = 0
          state[5] = 2
        elseif dest == 2 then
          state[0] = 0
          state[3] = 2
        end
      end
      
      state.wcq, state.wck = nil, nil
    end
    
    if n == 1 then
      if dest == state.wep then
        score = score - weight[-1]
        state[dest-8] = 0
      elseif dest >= 56 then
        score = score - weight[1] + weight[5]
        n = 5
      elseif dest-origin == 16 then
        state.bep = dest-8
      end
    end
    
    state.wep = nil
  else
    if origin == 56 then state.bcq = nil end
    if origin == 63 then state.bck = nil end
    if dest == 0 then state.wcq = nil end
    if dest == 7 then state.wck = nil end
    
    if n == -6 then
      state.bk = dest
      
      if origin == 60 then
        if dest == 62 then
          state[63] = 0
          state[61] = -2
        elseif dest == 58 then
          state[56] = 0
          state[59] = -2
        end
      end
      
      state.bcq, state.bck = nil, nil
    end
    
    if n == -1 then
      if dest == state.bep then
        score = score - weight[1]
        state[dest+8] = 0
      elseif dest < 8 then
        score = score - weight[-1] + weight[-5]
        n = -5
      elseif origin-dest == 16 then
        state.wep = dest+8
      end
    end
    
    state.bep = nil
  end
  
  state[dest] = n
  
  return score
end

_G.ChessInitData.copyState = function(state)
  local new_state = new()
  
  for i=0,63 do new_state[i] = state[i] end
  
  new_state.wk, new_state.bk = state.wk, state.bk
  new_state.wck, new_state.wcq, new_state.bck, new_state.bcq = state.wck, state.wcq, state.bck, state.bcq
  new_state.wep, new_state.bep = state.wep, state.bep
  new_state.n = state.n
  
  return new_state
end

local nil_weight= {}
for i = -6,6 do nil_weight[i] = 0 end

_G.ChessInitData.doMove = doMove

local function deleteState(state)
  for i = 64,state.states or 63 do
    deleteState(state[i])
  end
  
  delete(state)
end

_G.ChessInitData.doMoveNoWeight = function(state, move)
  local origin, dest = floor(move/64), move%64
  local prom

  origin, prom = origin%64, floor(origin/64)
  
  local type = state[origin]
  local origin2, dest2, type2, promote2 = dest, dest, state[dest], 0
  
  if state[dest] == 0 then
    origin2, dest2, type2, promote2 = nil, nil, nil, nil
  end
  
  if state[origin] == 1 and dest == state.wep then
    origin2, dest2, type2, promote2 = dest-8, dest, -1, 0
  elseif state[origin] == -1 and dest == state.bep then
    origin2, dest2, type2, promote2 = dest+8, dest, 1, 0
  elseif state[origin] == 6 and origin == 4 then
    if dest == 6 then
      origin2, dest2, type2, promote2 = 7, 5, 2, 2
    elseif dest == 2 then
      origin2, dest2, type2, promote2 = 0, 3, 2, 2
    end
  elseif state[origin] == -6 and origin == 60 then
    if dest == 62 then
      origin2, dest2, type2, promote2 = 63, 61, -2, -2
    elseif dest == 58 then
      origin2, dest2, type2, promote2 = 56, 59, -2, -2
    end
  end
  
  doMove(state, origin, dest, nil_weight)
  
  if type ~= state[dest] then
    assert(type == 1 or type == -1)
    assert(prom ~= 0)
    
    state[dest] = type * (prom+1)
  end
  
  if state.states then
    local empty = true
    
    if move >= 16384 then
      move = move - 16384
    end
    
    for i = 64,state.states do
      local sub_state = state[i]
      if sub_state.move == cmove then
        
        for i = i+1,state.states do
          deleteState(state[i])
        end
        
        if sub_state.states then
          for i=64,sub_state.states do
            state[i] = sub_state[i]
          end
        end
        
        state.states = sub_state.states
        sub_state.states = nil
        deleteState(sub_state)
        
        empty = false
        
        break
      end
      
      deleteState(sub_state)
    end
    
    if empty then
      state.states = nil
    end
  end
  
  state.n = state.n-1
  
  return origin, dest, type, state[dest], origin2, dest2, type2, promote2
end

_G.ChessInitData.deleteState = deleteState

local insert, concat = table.insert, table.concat

_G.ChessInitData.stateID = function(state)
  local moves, result = new(), new()
  
  for i = 0,63 do
    local n = state[i]
    insert(result, tostring(n))
    
    if n < 0 then
      piece_enum[n](i, state, moves, state.bk)
    else
      piece_enum[n](i, state, moves, state.wk)
    end
    
    for i = 1,#moves do
      local mv = moves[i]
      moves[i] = nil
      insert(result, "."..tostring(mv))
    end
  end
  
  local id = concat(result, " ")
  
  delete(result)
  delete(moves)
  
  return id
end
