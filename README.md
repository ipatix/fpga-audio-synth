# fpga-audio-synth

## Overview

Upon request I provide the source code to an FPGA audio synthesizer that I have run on a ZedBoard.
This is purely for archival purposes only and for people who might be interested.
If you're coming here, you're probably looking for the `audio_synth.vhd` file.

The synthesizer consists of a hardware and a software part. The software part runs on a MIPS-like CPU and
receives real MIDI commands over UART (I forgot the baud), put's it into the hardware components and synthesizes audio.
The audio is output over i2s to the ZedBoard's audio codec. The audio codec is initialized with code which is not mine.
Unfortunately I was not able to find where I got it from but I recall it was something like "ZedBoard DSP base project" or something.

The MIDI interface program is assembled with the MIPS simulator Mars.

## Disclaimer:
This project used to be an assignment of a class which had the primary goal of developing a MIPS-like CPU.
The audio synth was merely a late addition for a demo of the final assignment.

If you're here looking for a solution to your school/university assignemnt that you have to complete until next Monday:
Go away, don't waste your time reading this code. It's ugly, the CPU is nowhere near complete, it has pipeline hazards.

Don't send me E-Mail about this. Use it if it's helpful, but leave it alone if it's not. In most cases you're probably better off
rewriting it your own.
