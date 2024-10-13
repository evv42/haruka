# haruka - Z80 computer/ game of life tamagotchi

A computer designed to play Conway's Game of Life.

## Features

- a 512 byte ROM
- 8192 bits of RAM (8Kx1)
- one 4-bit output port, used for a SSD1306 display and a speaker

## Contents

```
rom.bin: assembled firmware
rom.asm: firmware sources
build.sh: build script for the firmware
harukascm.pdf : schematics
```

## Address space

```
(addresses in hex)
0000 - 1FFF : ROM (512 bytes, repeated)
2000 - DFFF : Unmapped, for additional stuff
E000 - FFFF : RAM (8Kx1)

```
IO space: every write goes to the output port, reads are unmapped

## Legal annoyances (licensing, that is GPL2-only)

Copyright (C) 2024 evv42

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
