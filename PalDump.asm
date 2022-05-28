; VGA Palette Dumping module for TSR.

MOV WORD BX, [CEInDOS_Offset]    ; Skips palette dumping if either the critical error or InDOS flag are set.
MOV WORD ES, [CEInDOS_Segment]   ;
ES                               ;
CMP BYTE [BX - 0x01], 0x00       ;
JNE Done                         ;
ES                               ;
CMP BYTE [BX], 0x00              ;
JNE Done                         ;

IN AL, 0x60             ; Skips palette dumping unless the F12 key is being pressed.
CMP AL, 0x58            ;
JNE Done                ;

CMP BYTE [Busy], 0x00   ; Checks whether a dump is already in progress.
JNE Done                ;

MOV BYTE [Busy], 0x01   ; Sets the flag indicating a dump is in progress.

MOV AH, 0x3C          ; Creates the output file.
MOV CX, 0x00          ;
LEA DX, OutputFile    ;
INT 0x21              ;
JC Done               ;

MOV BX, AX            ; Closes the newly created output file.
MOV AH, 0x3E          ;
INT 21h               ;
JC Done               ;

MOV AH, 0x3D          ; Opens the output file for writing.
MOV AL, 0x01          ;
LEA DX, OutputFile    ;
INT 0x21              ;
JC Done               ;

MOV BX, AX            ; Retrieves the filehandle.

XOR AL, AL            ; Resets the color index.
MOV [Color], AL       ;

MOV DI, Palette       ; Sets the target to the palette buffer.

Dump:
   MOV AL, [Color]    ; Sets the color's index.
   MOV DX, 0x3C8      ;
   OUT DX, AL         ;

   MOV CX, 0x03       ; Retrieves the RGB values.
   GetRGB:            ;
      MOV DX, 0x3C9   ;
      IN AL, DX       ;
      MOV [DI], AL    ;
      INC DI          ;
   LOOP GetRGB        ;

   MOV AL, [Color]    ; Moves to the next color index or stops dumping when the last one has been reached.
   CMP AL, 0xFF       ;
   JE DumpFinished    ;
   INC AL             ;
   MOV [Color], AL    ;
JMP Dump              ;

DumpFinished:
MOV AH, 0x40          ; Saves the retrieved palette.
MOV CX, 0x300         ;
MOV DX, Palette       ;
INT 0x21              ;
JC Done               ;

MOV AH, 0x3E          ; Closes the output file.
INT 21h               ;
JMP NEAR Done         ;

Busy DB 0x00
CEInDOS_Offset DW 0x0000
CEInDOS_Segment DW 0x0000
Color DB 0x00
OutputFile DB "PalDump.dat", 0x00
Palette Times 0x300 DB 0x00

Done:
MOV BYTE [Busy], 0x00   ; Clears the flag indicating a dump is progress.
