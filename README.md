# micromate
Software and instructions for improving the PMC 101 Micromate Z80-CP/M3 personal computer (1983)

I bought a Micromate PMC 101 computer in 1983. Turns out it still works. Actually, it's a great little machine. But one floppy drive (400kB) is very limiting. And more capacity is cheap and easily available. Here's what I did to add an IDE-based CF/SD-card to the machine.

If you own a Micromate, you can do it too.

## Summary

- The PMC 101 has an unused buffered 8bit bidirectional I/O port which can be used to connect an IDE disk or a solid state disk via an IDE adapter.
- Such use requires only a minor hardware change - a wire and a cut PCB path. Minimal soldering.
- Hardware documentation is available on the net, making the changes a lot easier than guesswork. [The disk images are here.](http://dunfield.classiccmp.org/img47321/d/pmc101.zip)
- And software - BIOS-changes and some tools are provided in this project.
- Using CF (actually, SD) cards, makes lots of fast storage available for the Micromate. However, CPM3 does not lend itself well to big disks, so - as it turns out - splitting the card into a few 10, 16 or 32 byte logical disks is optimal. And – in a CP/M3 environment, 32 MB is HUGE. Using a SD card larger than 128MB is a waste.
- TODO: The Micromate Floppy Disk Controller can (technically) handle 3.5" 720k floppies and the GOTEK floppy emulator when run in 720K mode. However, since IBM 'screwed up' the floppy cabling 'standard' with the PC, some cabling mods are required. Admittedly, now that a solid state hard disk available, this project is less interesting. Still its (potential) simplicity is a temptation.

Go to the code directory for source code, to the docs directory for documentation, links and experiences along the way.

Please comment and ask questions.

--Mellvik
