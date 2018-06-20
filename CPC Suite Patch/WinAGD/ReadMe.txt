AGD version 0.6
(C) Jonathan Cauldwell April 2018

http://www.spanglefish.com/egghead/
http://arcadegamedesigner.proboards.com/
@zxspectrumdev



Notes

Version 0.6 should be compatible with the ZX Spectrum, Timex/Spectrum Next and Amstrad CPC464.  At the time of writing, an Acorn Atom version, courtesy of Kees van Oss, is nearing completion.  Going forward the intention is to create versions for other 8-bit machines as well as support for things like hardware sprites on the Next.  The idea is that a game can be developed on one system and then, with a change of graphics, be converted to run on other systems.

The Windows editor is basic at the moment but the intention is to expand it to include more features.  It presently supports Spectrum, Timex, CPC and Acorn Atom although the compiler and engine for the Atom are not yet complete.  Next users should use the Timex editors for now but compile with CompilerNxt.exe.  You'll find that some actions require a mouse, others such as copy/paste, change block type, set object position still use the keyboard.  Keys should be the same as the Spectrum and CPC versions.  More details are included in the help document.

The AGD compilers are DOS console programs and the C source code is included should you wish to fix any issues you have with them or consider porting the system to an as yet unsupported system - please get in touch if you're interested.

This version has no DEFINESOUND command yet.  You'll have to make do with the predfined AY sounds and the BEEP command (Spectrum) for now.

The Windows editors will take care of most of the data for you and will export this as a .AGD file and then build it into an assembly language listing if desired.  Projects consist of .PJT and .MSG files for data and messages, then twenty separate scripts stored as .A00 to .A19.  The scripts and messages cadn be edited using a text editor.  The 4.6/4.7 conversion program Convert.exe will create a complete .AGD file from a 48K snapshot, complete with data and events although WinAGD can also perform this task for you.

The example coding templates are NOT complete AGD games but snippets of code to be copied and pasted into your events.


Importing an existing Spectrum game:

There's an option to import existing AGD games written using versions 4.0 to 4.7 in the File menu.  You'll need to create a 48K snapshot (.SNA) from the game.  As part of this process AGD will generate placeholder graphics for the Timex, Amstrad CPC and Acorn Atom but you'll probably wish to edit these to take account of the differing colour capabilities of these machines.


Building using WinAGD:

Export your game as a .AGD file first.  Make sure you save it in the same directory as the compiler or AGD will be unable to create an assembly language listing or the compiler will be unable to find the relevant engine.


To build your game manually:

Create an assembler source file from your AGD project by typing (eg) compilercpc mygame.  DO NOT type the .AGD extension or the assembly file generated will generate dozens of errors (This is still on my list of things to fix!)
If successful, mygame.asm will be created
Build mygame.asm using an assembler of your choice
Note: sjAsmPlus may require a line to be added to the top of the source code, eg:
       output mygame.bin

Assembler output has been tested with sjAsmPlus, 2500 AD and with the assemblers built into ZX Spin and WinApe.

Advanced users may wish to tinker with engine*.asm.  Other users will be undoubtedly interested in any modifications you make, so please post details on the AGD forums or on the AGD Facebook group.  AGD already has a fantastic community of users who are always interested in getting the most out of the tool.


Version History
===============

Version   Date     Comment
-------   ----     -------

0.1     Dec 2016   Initial release of Next/Timex version

0.2     Nov 2017   Added ULANext palette support
                   Various bug fixes

0.3     Jan 2018   ZX Spectrum compiler and engine added
                   Added DEFINEMESSAGES and MESSAGE
                   JUMP code tweaked
                   Fixed Next/Timex CLS routine

0.4     Feb 2018   Amstrad CPC compiler and engine added
                   Fixed CONTROL and other variables

0.5     Mar 2018   PUTBLOCK now sets up correct coordinates (thanks for spotting this Kees!)
                   Windows editors added
                   Separated Timex and Next compilers and engines, corrected Timex sound port.

0.6     Apr 2018   Old JUMP functionality included as DEFINEJUMP and TABLEJUMP for compatibility
                   Added FAST, MEDIUM, SLOW and VERYSLOW as parameters for ANIMATE and ANIMBACK
                   Added DEFINEFONT
                   Various bug fixes
                   More Windows editors added
