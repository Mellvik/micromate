A Micromate story
The kickoff
There was this cardboard box in the garage. The only one still unopened after the move two years before. In fact this was the third move it had survived without being opened. Packed up some time in 1993 I knew it contained computers and stuff. Some remembered, some - as it turned out - forgotten.
My opening of this pandora box in the fall of 2016 ignited a series of events that no one could have predicted. One of them is the Micromate story - this story.
I had almost forgotten the Micromate. An 8-bit Z80-based computer running the CPM3 operating system and played an important role in the early days of the company I started in the early 80s. As I lifted it out of the box, where it had been resting – accompanied in the company of diskettes, cables and other computers whose story are told elsewhere, memories flowed.
But I was not in the mood for reminiscing. Rather, the intent of opening the box was to check whether it contained something worth keeping before ditching it. Still, the little Micromate, small for its time and age, looked exactly like new, and just firing it up became too tempting. I needed a 220/110V adapter. It was in the box. I needed something to connect to the serial port. I didn't have that. Serial ports disappeared from the computers I'd been using 10+ years before. I decided I didn't need it. Having a 5 ¼ in floppy drive as its sole storage mechanism it would be easy to hear if the machine still worked. There were plenty of boot floppies to choose from - 3 boxes, plus a stack I ha recovered from a different box the year before.
Power up - LED comes on, floppy drive making noises. Yes, the Micromate works. I just could not throw it away, I had to find out more, maybe reminisce a little anyway.

Genesis

8 bit processors were the buzz of the technology business in 1980 and CP/M was the operating system enabling the personal computing revolution. Since its feeble start in 1976, personal computing had become viable, important and big. Byte Magazine, Creative Computing and a handful of other magazines were feeding a growing market of amateurs, enthusiasts and professionals – while feeding off of an increasing number of fast-growing companies in the segment.
And I was in the middle of it. In Norway, where a good friend and I built a CP/M based personal computer in 1979 and wrote tons of software for it. And at UC Berkeley where I arrived in the fall of -82 to work on Berkeley Unix. Buying a personal computer was out of reach, so I spent the first months at UCB writing Unix software to read and write CP/M floppies. A great way to learn Unix, the tools, and the C programming language, all of which were new to me at the time.
While growing fast, Unix was a different market and CP/M continued to rule the personal computing and 8-bit computing space, even though the IBM PC had recently been introduced. So what was more natural than a CPM World Conference – CP/M'83 – in San Francisco? I spent two and a half inspiring, some times breathtaking - days walking the halls of the Moscone Center just across the bay from Berkeley. Talked to people, vendors, developers, exchanging ideas and experiences, getting email addresses – and studying the new features of the show's main product, the new CP/M Plus, also known as CP/M3.
That's where I found it. The Micromate. A small stand presenting a small computer from a small company. The PMC-101 was the only product of Personal Microcomputers (PMC) of Mountain View, California. But what they lacked in size, they delivered in enthusiasm. To me, a perfect little machine running cp/m3 at a very reasonable price, about USD 1.300 including a QUME ASCII terminal. And software, which I didn't care all that much about. I just wanted a CP/M machine which could connect to a modem and a printer. 
I really wanted this machine. So I maxed out my (Norwegian) credit card and placed the order. For delivery in March. As March arrived, I was doing some consulting work for a company in Mountain View, and picking up my new digital buddy was easy.
It was indeed a perfect match. Even with only one floppy, the Micromate became my workhorse for a numbers of projects – in California and after I moved back to Norway. About a year later, having moved from Berkeley to work for the Mountain View company I previously consulted for, I expanded the Micromate with two additional floppies – in a separate cabinet identical in size to the first. With 3 drives totalling 1.2MB of storage capacity I felt I had a head start in the  computer revolution.

￼
From InfoWorld dec 18, 1982

The new dawn
Back to 2017 I eventually got a serial connection going and could connect to the Micromate console port. The first impression was right – the machine worked fine, and the floppies were not only readable but useable. Not all of them, but most. So I decided to try to turn it into a useable system, meaning getting more floppy drives. The original expansion box was long gone - the drives moved to an IBM PC at some point after the the Micromate fell out of use.
Two drives similar to the one included (Teac) were found and ordered on eBay, from somewhere in eastern Europe. Partly successful. As they arrived, both drives worked. One konked out after less than a week of very limited use. The motor just stopped. Being a tinkerer I wanted to fix it, so I set the system aside till I could find the time.
The wait turned into a long hiatus. The Micromate and the extra drives moved to the side of my workshop desk and stayed there for almost 3 years. As I finished up another vintage PC project, incidentally also triggered by my opening of the 'Pandora storage box', I decided it was time to get back to the Micromate in late 2020. 
In the meanwhile I had regularly scanned the net for Micromate-related resources, and found some. One that had copies of the original distribution software diskettes, another with the original user's guide plus a technical manual with schematics, and a third with CP/M3 programs and documentation. I didn't need all of these, but some of them were important for my Micromate project. In particular the technical manual with the schematics. Plus one of the software distribution floppy images, containing BIOS hard disk drivers. I had noe idea such a thing existed, and I still have no idea what the hardware may have looked like, but adding a hard disk was #1 on my agenda, so this was an important inspiration.
What really kicked me off in this direction though, was another Z80 project. I came across it more or less accidentally on the net – in 2019: Grant Searle's 5 chip Z80 system. Fascinating - to the extent that I ordered the board and the components - not a package, rather bits and pieces from more than a handful of different sources in 3 different countries. It took a couple of months and sent me back to my first homebrew system in terms of required experience. But the EPROMs got burned and the software loaded and the system booted. Not only that, it had a 'disk interface', really just a parallel interface to the databus connected to an IDE-adapter containing a CF card. Another experience that qualifies its own story, in particular converting it to CPM3, which I believe has not been chronicled on the net yet.
Comparing the Micromate schematics with Searle's schematics made it clear that attaching an IDE-disk/CF card to the Micromate should be no problem. So that was the project I decided to launch - in 2019. A decision that brought the 'ingredients' to my workshop desk, but not the time and priority. There were other issues to tend to.
Which again brings us back to late 2020 and early 2021: It was indeed possible. As I write this - feb6th 2021 - the Micromate is operational with it'd own hard disk. Not a CFcard via IDE, but a SD-card via IDE – the difference is totally unimportant from a usage point of view, but there is a technical reason for it, which is discussed in another document.
The physical attachment was almost trivial. The Micromate has what we can call a general 8-bit I/O-channel, simply a 2way buffer (74LS245) and address selection logic. This is not what was used in their own hard disk interface, but then again I have no idee what that looked like. When I say 'almost trivial', I mean that literally. There is a small hardware mod required to get the disk interface to work. The mod and the reasoning are both described in the practical documents.
An important experience from the project - which took muuuuuuch longer than anticipated - is the importance of small ambitions. While it is hard to come by small CFdisks these days, when 512MB is very small, a 16MB hard disk is big for CP/M. So regardless of the size of the CF or SD card you end up using, don't plan on creating big disks for CPM - even though CPM3 can handle 512MB drives. You're better off with 16MB, max 32MB drives, and here's the reason: Even though the solid state disks are fast compared to anything from the time and day of these machines, the CPM file system was created for (very) small disks and becomes slow and inefficient when the file system grows. More about that in the technical documentation, but the rule of thumb is: Several 16MB (logical) drives is better than fewer larger drives. And keep the block size to 4k.
