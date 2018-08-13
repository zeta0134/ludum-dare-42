CHUNK_ENTRANCE EQU 0
CHUNK_EXIT EQU 0
CHUNK_TOTAL EQU 8 ; note: should be a power of two!
CHUNK_MASK EQU $111 ; used for quick loop iteration

chunkAttributes:
        ; Index, Entrance, Exit
        DB 0, $FF, $FF ; end of the road - Note: should always remain index 0
        DB 1, "AA" ; plain               - Note: index one is our starting chunk
        DB 2, "AC" ; path narrows
        DB 3, "CA" ; path widens
        DB 4, "AB" ; path split 1
        DB 5, "BA" ; path split 2
        DB 1, "AA" ; plain               - Note: extra copies of "plain" to fill out
        DB 1, "AA" ; plain                       the table to a power of 2
