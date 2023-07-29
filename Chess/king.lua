local insert = table.insert
local wcheck, bcheck = _G.ChessInitData.white_check, _G.ChessInitData.black_check
local floor = math.floor

_G.ChessInitData.piece_enum[6] = function(i, state, out)
  local file, rank = i%8, floor(i/8)
  
  state[i] = 0
  
  if file > 0 then
    local n = state[i-1]
    if 0 >= n and wcheck(i-1, state) then
      insert(out, i-1)
      
      if n == 0 and i == 4 and state.wcq and state[2] == 0 and state[1] == 0 and wcheck(4, state) and wcheck(2, state) then
        insert(out, 2)
      end
    end
    
    if rank > 0 and 0 >= state[i-9] and wcheck(i-9, state) then
      insert(out, i-9)
    end
    
    if rank < 7 and 0 >= state[i+7] and wcheck(i+7, state) then
      insert(out, i+7)
    end
  end
  
  if file < 7 then
    local n = state[i+1]
    if 0 >= n and wcheck(i+1, state) then
      insert(out, i+1)
      
      if n == 0 and i == 4 and state.wck and state[6] == 0 and wcheck(4, state) and wcheck(6, state) then
        insert(out, 6)
      end
    end
    
    if rank > 0 and 0 >= state[i-7] and wcheck(i-7, state) then
      insert(out, i-7)
    end
    
    if rank < 7 and 0 >= state[i+9] and wcheck(i+9, state) then
      insert(out, i+9)
    end
  end
  
  if rank > 0 and 0 >= state[i-8] and wcheck(i-8, state) then
    insert(out, i-8)
  end
  
  if rank < 7 and 0 >= state[i+8] and wcheck(i+8, state) then
    insert(out, i+8)
  end
  
  state[i] = 6
end

_G.ChessInitData.piece_enum[-6] = function(i, state, out)
  local file, rank = i%8, floor(i/8)
  
  state[i] = 0
  
  if file > 0 then
    local n = state[i-1]
    if 0 <= n and bcheck(i-1, state) then
      insert(out, i-1)
      
      if n == 0 and i == 60 and state.bcq and state[58] == 0 and state[57] == 0 and bcheck(60, state) and bcheck(58, state) then
        insert(out, 58)
      end
    end
    
    if rank > 0 and 0 <= state[i-9] and bcheck(i-9, state) then
      insert(out, i-9)
    end
    
    if rank < 7 and 0 <= state[i+7] and bcheck(i+7, state) then
      insert(out, i+7)
    end
  end
  
  if file < 7 then
    local n = state[i+1]
    if 0 <= n and bcheck(i+1, state) then
      insert(out, i+1)
      
      if n == 0 and i == 60 and state.bck and state[62] == 0 and bcheck(60, state) and bcheck(62, state) then
        insert(out, 62)
      end
    end
    
    if rank > 0 and 0 <= state[i-7] and bcheck(i-7, state) then
      insert(out, i-7)
    end
    
    if rank < 7 and 0 <= state[i+9] and bcheck(i+9, state) then
      insert(out, i+9)
    end
  end
  
  if rank > 0 and 0 <= state[i-8] and bcheck(i-8, state) then
    insert(out, i-8)
  end
  
  if rank < 7 and 0 <= state[i+8] and bcheck(i+8, state) then
    insert(out, i+8)
  end
  
  state[i] = -6
end
