# CFinit.asm

CFinit was first created to dump the Indentity (ID) parameters from CFcards connected via IDE to a Z80 computer. Grant Searle's Format128.asm was the convenient starting point (and Searle's Z80 design was the first machine it ran on).
As my Micromate project evolved, a more comprehensive diagnostic tool was needed, and CFinit grew into just that - a comprehensive diag tool.
Here's a summary of the commands and their purpose.

- When started, CFinit reads and dumps the card's ID data in a readable format. A quick way to check if you're actually talking to the card. If you get gibberish, you have a hardware problem. Or, if you've moved the program to a different platform, an addressing problem (check the EQUs at the beginning of the program).
- CFinit will read and write any 'sector' (block) on the card, and always uses LBA addressing. In order to avoid introducing 32 bit arithmetic, CFinit divides the card into logical drives (aka 'units'). Each drive has 64k blocks, and LBA2, the third byte of the block address, is the 'drive number', set by the 'u' command.
- Notice that this program is created for CF-cards. It is useful for IDE drives and SD cards via IDE adapters, but some of the commands may not be meaningful. When used with SD card adapters, the ID data are coming from the adapter, not from the SD card (see examples below).
- Use the tool with great care - it overwrites data indiscriminately - there is no undo!

## The commands:
- The H (HELP) command lists a short description of all commands.
- The S command sets the 'current address' - the block # for the next read/write operation. Entering a number > 64k gives the modulo 64k number (65536 = 0 etc.). Entering nothing (CR) means zero.
- The U command sets the logical drive # (unit), there is not sanity check.
- The I command is partly a leftover from Searle's Format128. It initializes 128 consecutive blocks with a CP/M 2.2 directory pattern, starting at the current block address.
- The D command dumps the content of the data buffer (last read data) in hex and ascii.
- The C command reads the default and actual CHS data from the card. These are always the same, I have not found a way to change them even though the specs indicate it should be possible.
- The R command reads the card's ID data into the buffer and displays the content in a reasonable way. This is what happens on startup. Use the D command after the R command to look at the raw data.
- The G (Get) command reads the data block at the current address into the buffer and displays the content in hex/ascii.
- The L command is a write/read test of the currently addressed block. It creates a diagnostic pattern in the data buffer, writes it to the card and reads it back. See trhe chapter on CF-card problems below.
- The F command will interpret the data in the buffer as ID data and display. Unless preceded by a R command, this command is not meaningful.
- The T command only tests the internal decimal conversion routine, a leftover from development.
- The Y command will reset the CF card to 16 bit mode. Useful for cards that store the mode, to make the useful on non-8bit systems that never initializes word width. Turn off the machine and remove the card immediately after issuing this command to make sure it doesn't accidentally make it back to 8 bit mode.
- X or Q exits the program. Entering ^C when the program prompts for input does the same.

The CFinit.asm source is set up to be cross assembled using zasm (from GitHub - https://github.com/andrewrk/zasm.git). I use the following command line to assemble:
`zasm -uwyx --dotnames cfinit.asm`
If you're in a hurry and can use the program as is, the hex file is available.

For simplicity I use PIP to transfer the hex file to the Micromate:
`pip cfinit.hex=con:`
and then just paste the hex file into Minicom. Make sure the character delay in Minicom (^AT) is set to 3 or 4 before sending files this way.
Then convert the file to .COM using HEXCOM or LOAD in the CP/M system.

## CF-card problems
The L command addresses a specific problem found when using CF-cards. While text files make it to the card flawlessly, I found occasional problems with binary files. Debugging revealed that the errors were triggered by certain data petterns. Thus the L command which creates a tesat pattern in memory, writes it to the current block on the card, and reads it back for display.

It turns out that writing xxFF (FF in the odd byte) will cause a random number of zeroes to be written to the card, followed by the bytes after the FF. The FF will not be written, and the number of zeroes injected depend on the byte before the FF. Thus the diag pattern starts with 00ff and decrements the first byte for a total of 256 words: 00ff, ffff, feff, fdff etc. to 01ff.

The same CF-cards (and adapters) work fine on Grant Searle's design. I have not (yet) found the reason for this problem. It seems likely that the problem is either timing or cable noise. SD-cards with IDE adapters work fine – the problem is now on the backburner.

```
CP/M V3.0 Loader
Copyright (C) 1982, Digital Research

 61K TPA
128K PMC-101       CP/M 3.0 with extended HD Bios for MicroMate   -Vers3.0-
A>cfinit
CF card utility program
Read CF data OK.

 Serial #: 10F2F78B
 Firmware: Rev. 1.2
 Model: SINTECHI HighSpeed SD to CF Adapter V1.0
 LBA Size: 000F1F00
# h
Valid commands:
D - Dump memory buffer in hex
C - Show default and actual CHS data
I - Init directory starting at LBA
R - Read CF ID data into buffer
G - Get CF data block into buffer
L - Load e5 pattern into current CF block
F - Show data in buffer
H - Help, show this message
T - Test decimal number input and conversion
M - Modify CHS
Y - reset to 16 bit mode
S - set LBA # to read
U - set drive unit for I/O
X or Q - Exit program

#
```
The above example is accessing an SD card via a IDE interface. The one below is accessing a CF card.
```
A>cfinit
CF card utility program
Read CF data OK.

 Serial #:     1060911B95W87314
 Firmware: DH X.430
 Model: SanDisk SDCFJ-512
 LBA Size: 000F45F0

 #
```
