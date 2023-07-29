local wrook, wbishop, brook, bbishop = _G.ChessInitData.piece_enum[2],
                                       _G.ChessInitData.piece_enum[4],
                                       _G.ChessInitData.piece_enum[-2],
                                       _G.ChessInitData.piece_enum[-4]

_G.ChessInitData.piece_enum[5] = function(i, state, out, king)
  wrook(i, state, out, king)
  wbishop(i, state, out, king)
  
  state[i] = 5
end

_G.ChessInitData.piece_enum[-5] = function(i, state, out, king)
  brook(i, state, out, king)
  bbishop(i, state, out, king)
  
  state[i] = -5
end
