; This table is based on the standard MIDI index of 0-127. I pulled the
; data from http://www.devrs.com/gb/files/sndtab.html

; Each note is a 16-bit value, so start with the MIDI number of the note
; and shift to the left once, then use that to index the table.

; Pedantic note: Yes this is technically a _period_ table, but
; frequency is the term the homebrew community tends to use when
; referring to these values in documentation, so I stuck with that
; term for ease of understanding.

FrequencyTable:
        DW 0     ; C 0  - Engine treats this as SILENCE
        DW 0     ; C# 0  
        DW 0     ; D 0 
        DW 0     ; D# 0  
        DW 0     ; E 0 
        DW 0     ; F 0 
        DW 0     ; F# 0  
        DW 0     ; G 0 
        DW 0     ; G# 0  
        DW 0     ; A 0 
        DW 0     ; A# 0  
        DW 0     ; B 0 
        DW 0     ; C 1 
        DW 0     ; C# 1  
        DW 0     ; D 1 
        DW 0     ; D# 1  
        DW 0     ; E 1 
        DW 0     ; F 1 
        DW 0     ; F# 1  
        DW 0     ; G 1 
        DW 0     ; G# 1  
        DW 0     ; A 1 
        DW 0     ; A# 1  
        DW 0     ; B 1 
        DW 0     ; C 2 
        DW 0     ; C# 2  
        DW 0     ; D 2 
        DW 0     ; D# 2  
        DW 0     ; E 2 
        DW 0     ; F 2 
        DW 0     ; F# 2  
        DW 0     ; G 2 
        DW 0     ; G# 2  
        DW 0     ; A 2 
        DW 0     ; A# 2  
        DW 0     ; B 2 
        DW 44    ; C 3 
        DW 156   ; C# 3  
        DW 262   ; D 3 
        DW 363   ; D# 3  
        DW 457   ; E 3 
        DW 547   ; F 3 
        DW 631   ; F# 3  
        DW 710   ; G 3 
        DW 786   ; G# 3  
        DW 854   ; A 3 
        DW 923   ; A# 3  
        DW 986   ; B 3 
        DW 1046  ; C 4 
        DW 1102  ; C# 4  
        DW 1155  ; D 4 
        DW 1205  ; D# 4  
        DW 1253  ; E 4 
        DW 1297  ; F 4 
        DW 1339  ; F# 4  
        DW 1379  ; G 4 
        DW 1417  ; G# 4  
        DW 1452  ; A 4 
        DW 1486  ; A# 4  
        DW 1517  ; B 4 
        DW 1546  ; C 5 
        DW 1575  ; C# 5  
        DW 1602  ; D 5 
        DW 1627  ; D# 5  
        DW 1650  ; E 5 
        DW 1673  ; F 5 
        DW 1694  ; F# 5  
        DW 1714  ; G 5 
        DW 1732  ; G# 5  
        DW 1750  ; A 5 
        DW 1767  ; A# 5  
        DW 1783  ; B 5 
        DW 1798  ; C 6 
        DW 1812  ; C# 6  
        DW 1825  ; D 6 
        DW 1837  ; D# 6  
        DW 1849  ; E 6 
        DW 1860  ; F 6 
        DW 1871  ; F# 6  
        DW 1881  ; G 6 
        DW 1890  ; G# 6  
        DW 1899  ; A 6 
        DW 1907  ; A# 6  
        DW 1915  ; B 6 
        DW 1923  ; C 7 
        DW 1930  ; C# 7  
        DW 1936  ; D 7 
        DW 1943  ; D# 7  
        DW 1949  ; E 7 
        DW 1954  ; F 7 
        DW 1959  ; F# 7  
        DW 1964  ; G 7 
        DW 1969  ; G# 7  
        DW 1974  ; A 7 
        DW 1978  ; A# 7  
        DW 1982  ; B 7 
        DW 1985  ; C 8 
        DW 1988  ; C# 8  
        DW 1992  ; D 8 
        DW 1995  ; D# 8  
        DW 1998  ; E 8 
        DW 2001  ; F 8 
        DW 2004  ; F# 8  
        DW 2006  ; G 8 
        DW 2009  ; G# 8  
        DW 2011  ; A 8 
        DW 2013  ; A# 8  
        DW 2015  ; B 8 
        DW 0     ; C 9 
        DW 0     ; C# 9  
        DW 0     ; D 9 
        DW 0     ; D# 9  
        DW 0     ; E 9 
        DW 0     ; F 9 
        DW 0     ; F# 9  
        DW 0     ; G 9 
        DW 0     ; G# 9  
        DW 0     ; A 9 
        DW 0     ; A# 9  
        DW 0     ; B 9 
        DW 0     ; C 10  
        DW 0     ; C# 10 
        DW 0     ; D 10  
        DW 0     ; D# 10 
        DW 0     ; E 10  
        DW 0     ; F 10  
        DW 0     ; F# 10 
        DW 0     ; G 10  

