# Content
These files come from the PMC Hard Disk distribution for the Micromate. The following files have been modified:
- bnkbios3.asm
- diskioh.asm
- pmcequ.lib
- ports.lib

The rest are unchanged. When editing, make sure to keep the DOS file format (CR+LF line endings). The GENCPM.DAT file is probably different from the one in the floppy setup.

To build the new system, run `SUBMIT BIOS` on the target system, and make sure you have RMAC, LINK and GENCPM available on the disk, in addition to the BDOS SPR files.

The GENCPM.OUT file contains the output from my build - for reference. You will notice one warning in the listing, caused by the buffer allocations for the second hard disk. This is OK. 

As noted in the source, the directory allocations for the 2nd (N:) disk is really too small, and should be doubled. Experiment with this . and/or more drives at your leisure.
