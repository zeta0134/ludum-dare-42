hello.gb: hello_world.asm graphics.asm
	rgbasm -o hello.obj hello_world.asm
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