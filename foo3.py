#!/usr/bin/python

samplerate = 48000
int_max = 0x100000000

for x in range(120, 131):
    step = round(0x100000000 * 440.0 / 48000.0 * (2.0 ** ((x - 69) / 12.0)))
    step = int(step)
    print(hex(step))
