<img src="assets/6502_0.svg" height="96">

# C64 ASCII Text Editor V2
A text editor capable of loading, editing, and saving ASCII text.  
  
<p>
<img src="assets/screenshot-V1-00.png" alt="texteditor screen 1" width="400">
<img src="assets/screenshot-V1-04.png" alt="texteditor screen 2" width="400">  
</p>  

You can open and edit text files that you’ve transferred to the C64 from Windows or Linux. After editing them on the C64, you can process the text file on your PC again—it remains compatible.  
The editor supports the 7-bit ASCII character set (ANSI X3.4-1986), with the exception of the NUL and CR characters, which are deliberately ignored when loading a file.  
Special characters are mapped to suitable C64 screen codes for display.  
  
### Features
  
- Files are saved as C64 SEQ files containing plain ASCII text.  
  (On Windows, the file extension must be changed to `.txt`.)
- Optional line endings: LF or CRLF.
- Text buffer at `$4000–$CEFF` (approximately 36 KB); BASIC ROM is switched off.
- The uppercase/lowercase character set is copied to RAM at `$3000`.
- Application memory usage: approx. 12 KB.
- All keyboard input is converted to ASCII.  
- Characters that cannot be entered directly via the keyboard can be entered manually using F8.  
- German UTF-8 umlauts are displayed as inverted ASCII characters; no conversion is performed in the file.  
- Drives 8–11 can be selected for loading and saving; disks are checked for space before saving. 
- File access via the UCI interface (Ultimate 64, C64 Ultimate) presented as drive U.
- UCI: Files that are too large to fit in memory are split into parts; so you can still read them (e.g. book).
   
### ANSI X3.4-1986 Characters  
```
!"#$%&'()*+,-./ 
0123456789:;<=>? @  
ABCDEFGHIJKLMNO  
PQRSTUVWXYZ[\]^_ `  
abcdefghijklmno   
pqrstuvwxyz {|}~   
```  
  
### Keyboard Controls  
    F1 = Save   F3 = Load   F5 = New   F8 = Code input   F7 = Quit  
      
    Cursor keys  =  Move cursor 
    HOME    =   Start of line  
    CLR     =   Start of text 
    F2      =   End of text 
    F4 / F6 =   Page up / down   
  
    DEL          =  Backspace          
    SHIFT+DEL    =  Delete (INST)     
    RETURN       =  New line           
    CTRL+I       =  Tabulator  
  
    Direct character input on the C64 keyboard:  
        Pound              = Backslash \  
        SHIFT+Pound        = Underscope _ 
        Left Arrow         = Backtick `
        SHIFT+Plus         = Curly Brace {
        SHIFT+Minus        = Curly Brace }
        | (Up Arrow)       = ASCII character Pipe (|)         
        SHIFT+| (Up Arrow) = Caret ^  
        SHIFT+:            = Square Bracket [  
        SHIFT+;            = Square Bracket ]  
  
    F8 = Enter any ASCII code (decimal) 
         33–126 = printable ASCII characters   
         0–31 = control characters, 32 = SPACE, 127 = DEL
         (Inputs of 0 and 13 are ignored)  
  
         Examples of decimal values:  
         126 = ~  125 = }  123 = {  96 = `  9 = Tab   
  
         Umlauts as Unicode input:  
         228 = ä  246 = ö  252 = ü  
         196 = Ä  214 = Ö  220 = Ü  223 = ß  
  
    Special Character Mapping:  
        { } = displayed as inverted Parentheses ()  
         ~  = displayed as an inverted Minus Sign -  
         german UTF-8 umlauts = displayed as inverted ASCII character  
         UTF-8 Chevrons « » = displayed as inverted < >   
         
  
### Starting
Start the program from floppy disk using `LOAD"TEXTEDITOR",8,1` and `RUN`.
  
### File Loading, Saving, and Drive Selection
<p>
<img src="assets/screenshot-V2-drives.png" alt="loading file" width="400">
<img src="assets/screenshot-V2-USB-01.png" alt="loading file" width="400">
</p>
When loading (F3) or saving (F1), a file browser is displayed. You can select floppy drives 8–11. On Ultimate devices, drive U is also available, providing direct access to USB sticks and SD cards through UCI file access.

Use the CRSR Up/Down keys to navigate. Press RETURN to open a directory, or select .. to go back. In LOAD mode, press RETURN on a file to load it. In SAVE mode, press RETURN to copy the filename to the input line, then press RETURN again to save. A confirmation prompt helps prevent accidental overwrites.
The wildcards * and ? can be used when selecting files, but not when saving. Enter $ to re-read the drive contents. Filenames can be up to 25 characters long for UCI and 16 characters for disks. UCI access is case-sensitive.  
  
### Exiting
To exit the editor, press F8 then confirm by pressing Y.  
  
### Quick Note
The line ending (LF/CRLF), the file extensions in the blocklist, translated characters, colours, and text outputs, can all be easily changed in the source code. You’ll find them as options near the top, below the descriptions.  
  
    
<br>  
<br>  
     
> [!Important]
>**AI Notice:**  
>The code was created with the assistance of Claude.  
   
### Useful Information
PETSCII-Codes
```  
https://www.c64-wiki.de/wiki/PETSCII  
```  
ANSI X3.4
```  
https://en.wikipedia.org/wiki/ASCII  
```  
  
   
