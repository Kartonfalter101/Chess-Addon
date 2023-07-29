local insert = table.insert
local wcheck, bcheck = _G.ChessInitData.white_check, _G.ChessInitData.black_check

_G.ChessInitData.piece_enum[1] = function(i, state, out, king)
  state[i] = 0
  
  if 0 == state[i+8] then
    state[i+8] = i > 47 and 5 or 1
    if wcheck(king, state) then
      insert(out, i+8)
    end
    state[i+8] = 0
    
    if i >= 8 and i < 16 and 0 == state[i+16] then
      state[i+16] = 1
      if wcheck(king, state) then
        insert(out, i+16)
      end
      state[i+16] = 0
    end
  end
  
  local file = i%8
  
  if file > 0 then
    local n = state[i+7]
    if 0 > n then
      state[i+7] = 1
      if wcheck(king, state) then
        insert(out, i+7)
      end
      state[i+7] = n
    end
    
    if state.wep == i+7 then
      state[i-1] = 0
      state[i+7] = 1
      if wcheck(king, state) then
        insert(out, i+7)
      end
      state[i-1] = -1
      state[i+7] = 0
    end
  end
  
  if file < 7 then
    local n = state[i+9]
    if 0 > n then
      state[i+9] = 1
      if wcheck(king, state) then
        insert(out, i+9)
      end
      state[i+9] = n
    end
    
    if state.wep == i+9 then
      state[i+1] = 0
      state[i+9] = 1
      if wcheck(king, state) then
        insert(out, i+9)
      end
      state[i+1] = -1
      state[i+9] = 0
    end
  end
  
  state[i] = 1
end

_G.ChessInitData.piece_enum[-1] = function(i, state, out, king)
  state[i] = 0
  
  if 0 == state[i-8] then
    state[i-8] = i < 16 and -5 or -1
    
    if bcheck(king, state) then
      insert(out, i-8)
    end
    state[i-8] = 0
    
    if i >= 48 and i < 56 and 0 == state[i-16] then
      state[i-16] = -1
      if bcheck(king, state) then
        insert(out, i-16)
      end
      state[i-16] = 0
    end
  end
  
  local file = i%8
  
  if file > 0 then
    local n = state[i-9]
    if 0 < n then
      state[i-9] = -1
      if bcheck(king, state) then
        insert(out, i-9)
      end
      state[i-9] = n
    end
    
    if state.bep == i-9 then
      state[i-1] = 0
      state[i-9] = -1
      if bcheck(king, state) then
        insert(out, i-9)
      end
      state[i-1] = 1
      state[i-9] = 0
    end
  end
  
  if file < 7 then
    local n = state[i-7]
    if 0 < n then
      state[i-7] = -1
      if bcheck(king, state) then
        insert(out, i-7)
      end
      state[i-7] = n
    end
    
    if state.bep == i-7 then
      state[i+1] = 0
      state[i-7] = -1
      if bcheck(king, state) then
        insert(out, i-7)
      end
      state[i+1] = 1
      state[i-7] = 0
    end
  end
  
  state[i] = -1
end
