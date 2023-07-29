local insert = table.insert
local wcheck, bcheck = _G.ChessInitData.white_check, _G.ChessInitData.black_check
local floor = math.floor

_G.ChessInitData.piece_enum[2] = function(i, state, out, king)
  local file, rank = i%8, floor(i/8)*8
  
  state[i] = 0
  
  for i=i+1,rank+7 do
    local n = state[i]
    
    if n > 0 then break end
    
    state[i] = 2
    if wcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    
    if n ~= 0 then break end
  end
  
  for i=i-1,rank,-1 do
    local n = state[i]
    if n > 0 then break end
    state[i] = 2
    if wcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    if n ~= 0 then break end
  end
  
  for i=i+8,63,8 do
    local n = state[i]
    if n > 0 then break end
    state[i] = 2
    if wcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    if n ~= 0 then break end
  end
  
  for i=i-8,file,-8 do
    local n = state[i]
    if n > 0 then break end
    state[i] = 2
    if wcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    if n ~= 0 then break end
  end
  
  state[i] = 2
end

_G.ChessInitData.piece_enum[-2] = function(i, state, out, king)
  local file, rank = i%8, floor(i/8)*8
  
  state[i] = 0
  
  for i=i+1,rank+7 do
    local n = state[i]
    if n < 0 then break end
    state[i] = -2
    if bcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    if n ~= 0 then break end
  end
  
  for i=i-1,rank,-1 do
    local n = state[i]
    if n < 0 then break end
    state[i] = -2
    if bcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    if n ~= 0 then break end
  end
  
  for i=i+8,63,8 do
    local n = state[i]
    if n < 0 then break end
    state[i] = -2
    if bcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    if n ~= 0 then break end
  end
  
  for i=i-8,file,-8 do
    local n = state[i]
    if n < 0 then break end
    state[i] = -2
    if bcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    if n ~= 0 then break end
  end
  
  state[i] = -2
end
