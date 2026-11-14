# Octobus Mincraft - Nintendo DS (Lite) build
# Needs only: arm-none-eabi-gcc (Arm GNU Toolchain) + Python 3 with Pillow.
PREFIX  ?= arm-none-eabi-
CC      := $(PREFIX)gcc
OBJCOPY := $(PREFIX)objcopy
PY      ?= python3

CFLAGS  := -Os -Wall -ffreestanding -fno-builtin -nostdlib -fno-strict-aliasing
ARM9F   := -mcpu=arm946e-s -mthumb
ARM7F   := -mcpu=arm7tdmi -mthumb

ARM9_C  := $(wildcard src/arm9/*.c)
B       := build

all: OctobusMincraft.nds

UNIFONT ?= /usr/share/fonts/opentype/unifont/unifont.otf
src/arm9/lang.c src/arm9/lang.h: lang/strings.txt tools/make_lang.py
	$(PY) tools/make_lang.py lang/strings.txt src/arm9 $(UNIFONT)

src/arm9/assets.c src/arm9/assets.h $(B)/icon.png: $(wildcard gfx/*/*.bmp) tools/make_assets.py
	@mkdir -p $(B)
	$(PY) tools/make_assets.py gfx src/arm9

ARM9_SRC := $(sort $(ARM9_C) src/arm9/assets.c src/arm9/lang.c)
ARM9_OBJ := $(patsubst src/arm9/%.c,$(B)/o9/%.o,$(ARM9_SRC))
HOT      :=
HDRS     := src/arm9/assets.h src/arm9/lang.h src/arm9/game.h src/arm9/fat.h src/common/ds.h

$(B)/o9/%.o: src/arm9/%.c $(HDRS)
	@mkdir -p $(B)/o9
	$(CC) $(CFLAGS) -mcpu=arm946e-s $(if $(filter $*,$(HOT)),-marm,-mthumb) -c $< -o $@

$(B)/arm9.elf: src/arm9/crt0.s src/arm9/dldi.s $(ARM9_OBJ) src/arm9/arm9.ld
	$(CC) $(CFLAGS) $(ARM9F) src/arm9/crt0.s src/arm9/dldi.s $(ARM9_OBJ) -nostartfiles -T src/arm9/arm9.ld -lgcc -o $@

$(B)/arm7.elf: src/arm7/crt0.s src/arm7/main.c src/common/ds.h src/arm7/arm7.ld
	@mkdir -p $(B)
	$(CC) $(CFLAGS) $(ARM7F) src/arm7/crt0.s src/arm7/main.c -nostartfiles -T src/arm7/arm7.ld -lgcc -o $@

$(B)/%.bin: $(B)/%.elf
	$(OBJCOPY) -O binary $< $@

OctobusMincraft.nds: $(B)/arm9.bin $(B)/arm7.bin $(B)/icon.png tools/mknds.py
	$(PY) tools/mknds.py $(B)/arm9.bin $(B)/arm7.bin $@ --icon $(B)/icon.png --title "Octobus Mincraft;Octobus Entertainment;DS Lite"

clean:
	rm -rf $(B) OctobusMincraft.nds

.PHONY: all clean
