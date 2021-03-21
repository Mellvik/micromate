# micromate
Software and instructions for improving the PMC 101 Micromate Z80-CP/M3 personal computer (1983).

I bought a Micromate PMC 101 computer in 1983. Turns out it still works. Actually, it's a great little machine. But one floppy drive (400kB) is very limiting. And more capacity is cheap and easily available. Here's how to add an IDE-based CF/SD-card and a 3.5" 720K floppy drive to the machine.

If you own a Micromate, you can do it too.

## Summary

- The PMC 101 has an unused buffered 8bit bidirectional I/O port which can be used to connect an IDE disk or a solid state disk via an IDE adapter.
- Such use requires only a minor hardware change - a wire and a cut PCB path. Minimal soldering.
- Hardware documentation is available on the net, making the changes a lot easier than guesswork. [The disk images are here.](http://dunfield.classiccmp.org/img/index.htm)
- And software - BIOS-changes and some tools are provided in this project.
- Using CF (actually, SD) cards, makes lots of fast storage available for the Micromate. However, CP/M 3 does not lend itself well to big disks, so - as it turns out - splitting the card into a few 10, 16 or 32 byte logical disks is optimal. And – in a CP/M 3 environment, 32 MB is HUGE. Using a SD card larger than 128MB is a waste.
- The Micromate Floppy Disk Controller can handle 3.5" 720k floppies - and the GOTEK floppy emulator when run in 720K mode. Admittedly, now that a solid state hard disk available, this option seems less important. On the other hand, while 3.5in floppies may not be as ubiquitous as they used to, they are still an easy means to move files back and forth in bulk. Either as a CP/M file system or using the floppy as a raw device with files in some archiver format.

Go to the code directory for source code, to the docs directory for documentation, links and experiences along the way.

Please comment and ask questions.

--Mellvik
