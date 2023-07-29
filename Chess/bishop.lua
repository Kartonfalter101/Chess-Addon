local insert, min = table.insert, math.min
local wcheck, bcheck = _G.ChessInitData.white_check, _G.ChessInitData.black_check
local floor = math.floor

_G.ChessInitData.piece_enum[4] = function(i, state, out, king)
  local file, rank = i%8, floor(i/8)
  state[i] = 0
  
  for i=i+7,i+min(file, 7-rank)*7,7 do
    local n = state[i]
    
    if n > 0 then break end
    
    state[i] = 4
    if wcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    
    if n ~= 0 then break end
  end
  
  for i=i+9,i+min(7-file, 7-rank)*9,9 do
    local n = state[i]
    if n > 0 then break end
    state[i] = 4
    if wcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    if n ~= 0 then break end
  end
  
  for i=i-9,i-min(file, rank)*9,-9 do
    local n = state[i]
    if n > 0 then break end
    state[i] = 4
    if wcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    if n ~= 0 then break end
  end
  
  for i=i-7,i-min(7-file, rank)*7,-7 do
    local n = state[i]
    if n > 0 then break end
    state[i] = 4
    if wcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    if n ~= 0 then break end
  end
  
  state[i] = 4
end

_G.ChessInitData.piece_enum[-4] = function(i, state, out, king)
  local file, rank = i%8, floor(i/8)
  state[i] = 0
  
  for i=i+7,i+min(file, 7-rank)*7,7 do
    local n = state[i]
    if n < 0 then break end
    state[i] = -4
    if bcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    if n ~= 0 then break end
  end
  
  for i=i+9,i+min(7-file, 7-rank)*9,9 do
    local n = state[i]
    if n < 0 then break end
    state[i] = -4
    if bcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    if n ~= 0 then break end
  end
  
  for i=i-9,i-min(file, rank)*9,-9 do
    local n = state[i]
    if n < 0 then break end
    state[i] = -4
    if bcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    if n ~= 0 then break end
  end
  
  for i=i-7,i-min(7-file, rank)*7,-7 do
    local n = state[i]
    if n < 0 then break end
    state[i] = -4
    if bcheck(king, state) then
      insert(out, i)
    end
    state[i] = n
    if n ~= 0 then break end
  end
  
  state[i] = -4
end
