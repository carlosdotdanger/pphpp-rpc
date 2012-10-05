%fixed terms have tag + vlue in one byte.

						%Remainder
-define (FIX_POS,0:1). 	% Val:7
-define (FIX_NEG,7:3). 	% Val:5
-define (FIX_MAP,8:4). 	% Size:4
-define (FIX_ARR,9:4). 	% Size:4
-define (FIX_RAW,5:3). 	% Size:5

%one byte tags
-define (NIL,    16#c0).	
-define (FALSE,  16#c2).
-define (TRUE,   16#c3).
-define (FLOAT,  16#ca).
-define (DOUBLE, 16#cb).
-define (UINT_8, 16#cc).
-define (UINT_16,16#cd).
-define (UINT_32,16#ce).
-define (UINT_64,16#cf).
-define (INT_8,  16#d0).
-define (INT_16, 16#d1).
-define (INT_32, 16#d2).
-define (INT_64, 16#d3).
-define (RAW_16, 16#da).
-define (RAW_32, 16#db).
-define (ARR_16, 16#dc).
-define (ARR_32, 16#dd).
-define (MAP_16, 16#de).
-define (MAP_32, 16#df).

%rpc tags
-define (REQU, 0).
%[type,   msgid,   method, params]
%[posfix, uint_32, raw,    array ]

-define (NOTI, 2).
%[type,   method,  params]
%[posfix, uint_32, array ]

-define (RESP, 1).
%[type,   msgid,   error,   result  ]
%[posfix, uint_32, nil|ANY, ANY|nil ]

%min/max vals for integer types
%signed 
-define (MIN_5,  -32).
-define (MIN_8,  -128).
-define (MIN_16, -32768).
-define (MIN_32, -2147483648).

%unsigned
-define (MAX_U4,  15).
-define (MAX_U7,  63).
-define (MAX_U5,  31).
-define (MAX_U8,  255).
-define (MAX_U16, 65535).
-define (MAX_U32, 4294967295).
