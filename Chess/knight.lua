local insert = table.insert
local wcheck, bcheck = _G.ChessInitData.white_check, _G.ChessInitData.black_check
local floor = math.floor

_G.ChessInitData.piece_enum[3] = function(i, state, out, king)
  local file, rank = i%8, floor(i/8)
  state[i] = 0
  
  if rank < 7 then
    if file > 0 then
      if file > 1 then
        local t = i+6
        local n = state[t] 
        if 0 >= n then
          state[t] = 3
          if wcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
      
      if rank < 6 then
        local t = i+15
        local n = state[t] 
        if 0 >= n then
          state[t] = 3
          if wcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
    end
    
    if file < 7 then
      if file < 6 then
        local t = i+10
        local n = state[t] 
        if 0 >= n then
          state[t] = 3
          if wcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
      
      if rank < 6 then
        local t = i+17
        local n = state[t] 
        if 0 >= n then
          state[t] = 3
          if wcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
    end
  end
  
  if rank > 0 then
    if file > 0 then
      if file > 1 then
        local t = i-10
        local n = state[t] 
        if 0 >= n then
          state[t] = 3
          if wcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
      
      if rank > 1 then
        local t = i-17
        local n = state[t] 
        if 0 >= n then
          state[t] = 3
          if wcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
    end
    
    if file < 7 then
      if file < 6 then
        local t = i-6
        local n = state[t] 
        if 0 >= n then
          state[t] = 3
          if wcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
      
      if rank > 1 then
        local t = i-15
        local n = state[t] 
        if 0 >= n then
          state[t] = 3
          if wcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
    end
  end
  
  state[i] = 3
end

_G.ChessInitData.piece_enum[-3] = function(i, state, out, king)
  local file, rank = i%8, floor(i/8)
  state[i] = 0
  
  if rank < 7 then
    if file > 0 then
      if file > 1 then
        local t = i+6
        local n = state[t] 
        if 0 <= n then
          state[t] = -3
          if bcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
      
      if rank < 6 then
        local t = i+15
        local n = state[t] 
        if 0 <= n then
          state[t] = -3
          if bcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
    end
    
    if file < 7 then
      if file < 6 then
        local t = i+10
        local n = state[t] 
        if 0 <= n then
          state[t] = -3
          if bcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
      
      if rank < 6 then
        local t = i+17
        local n = state[t] 
        if 0 <= n then
          state[t] = -3
          if bcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
    end
  end
  
  if rank > 0 then
    if file > 0 then
      if file > 1 then
        local t = i-10
        local n = state[t] 
        if 0 <= n then
          state[t] = -3
          if bcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
      
      if rank > 1 then
        local t = i-17
        local n = state[t] 
        if 0 <= n then
          state[t] = -3
          if bcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
    end
    
    if file < 7 then
      if file < 6 then
        local t = i-6
        local n = state[t] 
        if 0 <= n then
          state[t] = -3
          if bcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
      
      if rank > 1 then
        local t = i-15
        local n = state[t] 
        if 0 <= n then
          state[t] = -3
          if bcheck(king, state) then
            insert(out, t)
          end
          state[t] = n
        end
      end
    end
  end
  
  state[i] = -3
end
