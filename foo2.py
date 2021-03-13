#!/usr/bin/python

x = 0
for i in range(0, 32):
    key1 = x % 12
    key1 |= (10 - x / 12) << 4
    x += 1
    key2 = x % 12
    key2 |= (10 - x / 12) << 4
    x += 1
    key3 = x % 12
    key3 |= (10 - x / 12) << 4
    x += 1
    key4 = x % 12
    key4 |= (10 - x / 12) << 4
    x += 1
    res = key1 | (key2 << 8) | (key3 << 16) | (key4 << 24)
    print(hex(res))
