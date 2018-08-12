;* LEGEND
;*
;* 0 = nothing
;* 1 = floor
;* 2 = solid wall
;* 3 = ceiling
;* 4 = floaty platform

collisionLUT:
        DB 0, 0, 2, 4, 3, 3, 2, 0
        DB 0, 0, 0, 4, 0, 0, 2, 0
        DB 0, 0, 0, 0, 1, 1, 2, 0
        DB 0, 0, 0, 1, 1, 3, 3, 0