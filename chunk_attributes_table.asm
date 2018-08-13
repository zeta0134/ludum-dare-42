CHUNK_ENTRANCE EQU 0
CHUNK_EXIT EQU 0
CHUNK_TOTAL EQU %00010000 ; (8) note: should be a power of two!
CHUNK_MASK  EQU %00001111 ; used for quick loop iteration

chunkAttributes:
        ; Index, Entrance, Exit, Dummy (power of 2)
        DB 0, $FF, $FF, 0 ; end of the road - Note: should always remain index 0
        DB 1, "AA", 0 ; plain               - Note: index one is our starting chunk
        DB 6, "BB", 0 ; lower split with jumps
        DB 2, "AC", 0 ; path narrows
        DB 3, "CA", 0 ; path widens
        DB 6, "BB", 0 ; lower split with jumps
        DB 2, "AC", 0 ; path narrows
        DB 3, "CA", 0 ; path widens
        DB 3, "CA", 0 ; path widens
        DB 4, "AB", 0 ; path split 1
        DB 2, "AC", 0 ; path narrows
        DB 5, "BA", 0 ; path split 2
        DB 1, "AA", 0 ; plain
        DB 4, "AB", 0 ; path split 1
        DB 1, "AA", 0 ; plain                       the table to a power of 2
