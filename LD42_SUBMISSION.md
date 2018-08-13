# Dyson's Fear

Something has caused a runaway chain reaction on your space station and now you're running for your life from a massive explosion! There's just one problem - there's only so much space station to run through - but there are intelligent wrenches that can build additional sections of the station laying around. How long can you sprint from the flames without running out of ship and flying into the vastness of space? Don't panic! This is Dyson's Fear.

This is our fourth ludum dare entry, but it's our first attempt at making a Gameboy game! I knew a little bit of z80 assembly going in and have written a [gameboy emulator](https://github.com/zeta0134/LuaGB), so I knew the hardware pretty well, but hadn't actually tried my hand at making a game before this contest. @cromo created all of our artwork within some tiny VRAM constraints, and wrote some of his first ever assembly code on this project; mad props to him for picking up assembly language so quickly! We targeted a 32k cartridge so we wouldn't have to worry about bank switching, and had a true "Don't Panic!" moment towards the end once we started making level data. We had filled up the first 16k bank entirely, and the project wouldn't build! I'm amazed we wrote enough code and levels to make that a remote possibility, but we didn't realize our mistake at first and thought we were totally done for. After some quick reshuffling of data and removal of dead features, we got under our bank limit and were ready to release.

We unfortunately didn't have time to get any music or sound effects into the engine, so we'll submit this game under every category except for those. The release is a Gameboy ROM, and source code is available. It should run in almost any gameboy emulator out there. We tested in [BGB for Windows](http://bgb.bircd.org/), which is known for its accuracy, but even then I expect there are a few bugs lurking here and there.

## Controls:

**A** - Jump

**Start** - Begin

## Objectives

This is an endless runner, so you'll move forward automatically.

1. Escape from the fiery explosion! Just keep running to the right. The explosion gets faster as the game goes on.
2. Collect wrenches, and build more of your ship in front of you! If you **run out of space** in your ship, you'll be thrown into the bleak, empty abyss!
3. Use crates wisely! You'll speed up slowly over time, which helps to escape from the fiery explosion. But going too fast might make it difficult to avoid slamming into walls. Hitting a crate or bumping into a ceiling slows you down, so use these to help control your speed.

High scores are tracked, but the cartridge we targeted doesn't support SRAM, so they won't be saved. If you want to show off to your friends, take a screenshot!

