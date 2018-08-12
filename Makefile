SPRITE_FILES := $(wildcard art/sprites/*.png)
SPRITE_2BPP := $(patsubst art/sprites/%.png,data/sprites/%.2bpp,$(SPRITE_FILES))
TILEMAP_FILES := $(wildcard art/tiles/*.png)
TILEMAP_2BPP := $(patsubst art/tiles/%.png,data/tiles/%.2bpp,$(TILEMAP_FILES))

ASM_FILES := $(wildcard *.asm) $(wildcard vendor/*.asm)

hello.gb: $(ASM_FILES) $(SPRITE_2BPP) $(TILEMAP_2BPP)
	rgbasm -o hello.obj main.asm
	rgblink -o hello.gb hello.obj 
	rgbfix -v hello.gb

run: hello.gb
	gambatte-qt hello.gb

debug: hello.gb
	bgb hello.gb

.PHONY: clean
clean:
	@rm -f *.gb
	@rm -f *.obj

.PHONY: art
art: $(SPRITE_2BPP) $(TILEMAP_2BPP)
	@echo $(SPRITE_FILES)
	@echo $(SPRITE_2BPP)
	@echo $(TILEMAP_FILES)
	@echo $(TILEMAP_2BPP)
	@echo "Artwork built!"

data/sprites/%.2bpp: art/sprites/%.png
	@mkdir -p data/sprites
	rgbgfx -h -f -o $@ $<

data/tiles/%.2bpp: art/tiles/%.png
	@mkdir -p data/tiles
	rgbgfx -f -o $@ $<

