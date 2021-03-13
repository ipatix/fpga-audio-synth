#!/usr/bin/python

def bar(x):
    x = pow(x / 255.0, 10.0 / 6.0);
    x *= 255.0;
    x = round(x)
    return x
i = 0
for x in range(0, 64):
    res = int(bar(i))
    res |= int(bar(i+1)) << 8
    res |= int(bar(i+2)) << 16
    res |= int(bar(i+3)) << 24
    print(hex(res))
    i += 4
