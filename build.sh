#!/bin/sh
set -e
set -x
vasmz80_oldstyle -Fbin -dotdir rom.asm
mv a.out rom.bin && echo "build successful"
