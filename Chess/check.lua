local insert = table.insert
local floor, min = math.floor, math.min

_G.ChessInitData.white_check = function(i, state)
  local file, rank = i%8, floor(i/8)
  local rank8 = rank*8
  local n
  
  if rank < 7 then
    n = state[i+8]
    if n == -2 or n == -5 or n == -6 then return false end
    if n == 0 then
      for i=i+16,63,8 do
        n = state[i]
        if n ~= 0 then if n == -5 or n == -2 then return false end break end
      end
    end
    
    if file > 0 then
      n = state[i+7]
      if n == -1 or n == -4 or n == -5 or n == -6 then return false end
      if n == 0 then
        for i=i+14,i+min(file, 7-rank)*7,7 do
          n = state[i]
          if n ~= 0 then if n == -5 or n == -4 then return false end break end
        end
      end
      
      if file > 1 and state[i+6] == -3 then return false end
      if rank < 6 and state[i+15] == -3 then return false end
    end
    
    if file < 7 then
      n = state[i+9]
      if n == -1 or n == -4 or n == -5 or n == -6 then return false end
      if n == 0 then
        for i=i+18,i+min(7-file, 7-rank)*9,9 do
          n = state[i]
          if n ~= 0 then if n == -5 or n == -4 then return false end break end
        end
      end
      
      if file < 6 and state[i+10] == -3 then return false end
      if rank < 6 and state[i+17] == -3 then return false end
    end
  end
  
  if rank > 0 then
    n = state[i-8]
    if n == -2 or n == -5 or n == -6 then return false end
    if n == 0 then
      for i=i-16,file,-8 do
        n = state[i]
        if n ~= 0 then if n == -5 or n == -2 then return false end break end
      end
    end
    
    if file > 0 then
      n = state[i-9]
      if n == -4 or n == -5 or n == -6 then return false end
      if n == 0 then
        for i=i-18,i-min(file, rank)*9,-9 do
          n = state[i]
          if n ~= 0 then if n == -5 or n == -4 then return false end break end
        end
      end
      
      if file > 1 and state[i-10] == -3 then return false end
      if rank > 1 and state[i-17] == -3 then return false end
    end
    
    if file < 7 then
      n = state[i-7]
      if n == -4 or n == -5 or n == -6 then return false end
      if n == 0 then
        for i=i-14,i-min(7-file, rank)*7,-7 do
          n = state[i]
          if n ~= 0 then if n == -5 or n == -4 then return false end break end
        end
      end
      
      if file < 6 and state[i-6] == -3 then return false end
      if rank > 1 and state[i-15] == -3 then return false end
    end
  end
  
  if file > 0 then
    n = state[i-1]
    if n == -2 or n == -5 or n == -6 then return false end
    if n == 0 then
      for i=i-2,rank*8,-1 do
        n = state[i]
        if n ~= 0 then if n == -5 or n == -2 then return false end break end
      end
    end
  end
  
  if file < 7 then
    n = state[i+1]
    if n == -2 or n == -5 or n == -6 then return false end
    if n == 0 then
      for i=i+2,rank*8+7 do
        n = state[i]
        if n ~= 0 then if n == -5 or n == -2 then return false end break end
      end
    end
  end
  
  return true
end

_G.ChessInitData.black_check = function(i, state)
  local file, rank = i%8, floor(i/8)
  local n
  
  if rank < 7 then
    n = state[i+8]
    if n == 2 or n == 5 or n == 6 then return false end
    if n == 0 then
      for i=i+16,63,8 do
        n = state[i]
        if n ~= 0 then if n == 5 or n == 2 then return false end break end
      end
    end
    
    if file > 0 then
      n = state[i+7]
      if n == 4 or n == 5 or n == 6 then return false end
      if n == 0 then
        for i=i+14,i+min(file, 7-rank)*7,7 do
          n = state[i]
          if n ~= 0 then if n == 5 or n == 4 then return false end break end
        end
      end
      
      if file > 1 and state[i+6] == 3 then return false end
      if rank < 6 and state[i+15] == 3 then return false end
    end
    
    if file < 7 then
      n = state[i+9]
      if n == 4 or n == 5 or n == 6 then return false end
      if n == 0 then
        for i=i+18,i+min(7-file, 7-rank)*9,9 do
          n = state[i]
          if n ~= 0 then if n == 5 or n == 4 then return false end break end
        end
      end
      
      if file < 6 and state[i+10] == 3 then return false end
      if rank < 6 and state[i+17] == 3 then return false end
    end
  end
  
  if rank > 0 then
    n = state[i-8]
    if n == 2 or n == 5 or n == 6 then return false end
    if n == 0 then
      for i=i-16,file,-8 do
        n = state[i]
        if n ~= 0 then if n == 5 or n == 2 then return false end break end
      end
    end
    
    if file > 0 then
      n = state[i-9]
      if n == 1 or n == 4 or n == 5 or n == 6 then return false end
      if n == 0 then
        for i=i-18,i-min(file, rank)*9,-9 do
          n = state[i]
          if n ~= 0 then if n == 5 or n == 4 then return false end break end
        end
      end
      
      if file > 1 and state[i-10] == 3 then return false end
      if rank > 1 and state[i-17] == 3 then return false end
    end
    
    if file < 7 then
      n = state[i-7]
      if n == 1 or n == 4 or n == 5 or n == 6 then return false end
      if n == 0 then
        for i=i-14,i-min(7-file, rank)*7,-7 do
          n = state[i]
          if n ~= 0 then if n == 5 or n == 4 then return false end break end
        end
      end
      
      if file < 6 and state[i-6] == 3 then return false end
      if rank > 1 and state[i-15] == 3 then return false end
    end
  end
  
  if file > 0 then
    n = state[i-1]
    if n == 2 or n == 5 or n == 6 then return false end
    if n == 0 then
      for i=i-2,rank*8,-1 do
        n = state[i]
        if n ~= 0 then if n == 5 or n == 2 then return false end break end
      end
    end
  end
  
  if file < 7 then
    n = state[i+1]
    if n == 2 or n == 5 or n == 6 then return false end
    if n == 0 then
      for i=i+2,rank*8+7 do
        n = state[i]
        if n ~= 0 then if n == 5 or n == 2 then return false end break end
      end
    end
  end
  
  return true
end