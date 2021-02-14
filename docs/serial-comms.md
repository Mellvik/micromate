# The serial connection
Firing up the Micromate (or any other old, serial based computer) is only the first little step. Getting the console to work is the next, followed by some mechanism to move data back and forth.

## In short
- A RaspberryPi zero is cheap and practical for serial connections. 
- The connections must be RS232 level, not TTL. A 'Serial Hat' for the Pi and a USB-RS232 adapter are good choices. Or 2 USB-RS232 adapters.
- The console port and the modem port are wired differently on the Micromate. The console port is wired as DCE (Data Communications Equipment), the Modem port is a DTE.
- Use the Micromate `config` program to set the speeds, turn off hardware handshake and enable 8 bit communications.
- Minicom is good for connecting to the Micromate because you can set a per character delay. This is required for reliable transfer of text files into the system until you have a working communication program running.
- Kermit is the most flexible and reliable comms-program. Not the most efficient and quite complicated because of all the options, but IMHO still the best.

![Micromate setup with RaspberryPi Zero](https://github.com/Mellvik/micromate/blob/main/docs/img/IMG_6586.jpeg)

## File Transfer 

Many systems have storage media that can be shared with other systems. Not fast, but efficient for large amounts of data. And not an option for the Micromate. 
The diskettes are physically the same as low density (aka DSDD, double sided, double density) diskettes on old PCs, but the format is different. The Micromate uses 1024 byte sectors, squeezing 409 kBytes out of the 360k diskette. For good and bad.

So we need serial for data transfer. In our case, the console port was connected to a 'serial hat' on a RaspberryPi zero. A cheap and  flexible way to make the CP/M console available via the network. Doing the same with the modem port was an obvious choice. I pulled a USB-RS232 adapter from a drawer, spent some time getting the null modem setup (effectively disabling hardware handshake) to work, and we were on line - so to speak. 

## Configuring the system
Unfortunately (but unsurprising) I had forgotten all about the Micromate hardware `config` program. That cost me many hours of extra work, so here is the todo list:
- Since no modern serial devices use hardware handshake, turn off DTR and DSR using the `config` program. Also set the ports to 8 bits, no parity and to your preferred speed (presumably 19200 bps although I tend to use 9600 on the modem port).
- Remember that most USB/serial adapters are TTL (5V) not RS232 (12-15V) which the Micromate and all older systems are using. Thus the USB-to-D9 adapter (see photo) which does the RS232 level conversion for you. 
- Some of these adapters even have hardware handshake enabled, make sure you handle that.
- The Linux Screen program is a convenient companion when connecting from the RaspberryPi (or other Linux/Unix system) via serial ports. However, in this case Minicom turns out to be a better option. It does something Screen cannot do: Injecting a per character delay - which you are going to need, at least temporarily. Without the delay, the Micromate will lose serial data every now and then, even at 9600 bps. So - install Minicom and set the per char delay (in the terminal settings) to 3ms.

## Kermit to the rescue
Modem7 - a vintage communication program - was installed on the Micromate, but I could not get it to work reliably. I eventually gave up and decided I needed Kermit, which is more robust and flexible. The question was how to get Kermit across to the Micromate without a comms-program. I discovered later that the [Kermit-80 manual](ftp://ftp.columbia.edu/kermit/cpm80/cpkerm.pdf) has a recipe for such situations, which I would probably use if I had to do it again. Still, the chosen method was reasonably straightforward.

- Kermit works best if configured for the machine it's running on. This means linking the final program on the target machine. In order to do that, three binary files must be transferred to the target system - the Kermit main module, the Kermit Micromate adaption module and the linker. 
- All three are available for download in hex format, are binaries and need to be converted to ASCII in order to be transferred.
- A side note: If you have programs (.COM files) that need to be transferred to the CPM system before you have your Kermit up and running, there is a simple com2hex program on the net (GitHub) which converts CPM COM programs to Intel Hex format files, that can be turned back into COM files with standard CPM utilities (`LOAD` or `HEXCOM`). http://www.nj7p.org/Computers/Software/Tools1.html Com2hex.c compiles easily on Linux and Unix machines, and a Windows .EXE file is included.
- The main Kermit hex file (CPSKER.HEX) is too big for direct transfer using PIP (`PIP DESTFILE.HEX=CON:`), but can easily be split into two using the Linux/Unix split() program. Merge them back to one on CPM using PIP: `PIP CPSKER.HEX=PT1.HEX+PT2.HEX`. Remember to set the Minicom character delay before transferring files into PIP, and to type ^Z when the transfer is finished. .
- For the actual sending, cat the hex file in a local window, put it into the paste buffer and paste it into the Microcom window after entering the PIP command (above) and allow the system time to load PIP. Enter ^Z in Microcom to tell PIP the the transfer is finished.
- Load the kerm411.com file as described in the Kermit manual, and you’re ready to run - after downloading CKermit on the RaspberryPi (or whatever you have at the other end of the serial line). Configure the ‘server’-side like this, modified to fit your setup.
```
kermit -i
>set file bin
>set port /dev/ttyUSB0
>set flow none
>set speed 19200
> server
```
- On CPM, like this:
```
M>kerm411
Kermit-80 v4.11 configured for PMC Micromate using port I/O with Generic (Dumb) CRT Terminal type selected 

For help, type ? at any point in a command
Kermit-80   0M:>take kerm.ini
Kermit-80   0M:>set coll over
Kermit-80   0M:>set file bin
Kermit-80   0M:>set buf 64
Kermit-80   0M:>
```
- I created a startup-file on the Micromate (`kerm.ini`) to speed up the process, as can be seen from the example (use the `take` command). Notice: While running from floppy, you need to set the buffer size to 8, otherwise you will not get stable transfers. The `set coll over` (set collisions overwrite) means wipe out local files if they exist. Very convenient when downloading lots of files, and you have to do it several times. Use with care.
- Use the `remote dir` command to ensure that the server side of the connection is working.
- I’ve used the `get *.*` command a lot when populating ‘directories’ locally when everything is running.
- Kermit is VERY helpful with text files. In fact, painfully helpful. Therefore - make sure you get both sides of the link to understand that files are indeed binaries. Including text files. Thus the `kermit -i` when starting the server.

