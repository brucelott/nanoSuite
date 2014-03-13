hi! 
nanoSuite is a nanoKONTROL2(s) based sequencer. it can sequence drums, a synth, or both.
nanoSuite is written in ChucK. this package comes with ChucK, so you don't need to download it yourself (even though you should :) ). also included in this package is documentation and a demo ableton set. 

to use, double click the suite_launcher.command and follow the set up instructions that pop up.

you will need your nanoKONTROL2(s) to have the included template loaded (nanoSuite.nktrl2_data, load it with KORG KONTROL editor). be warned: this will change all the nano's CCs and will put your it in external LED mode, so save your old template.

check out nanoRhythm.jpeg and nanoPitch.jpeg to learn how they work.

some elaboration on certain nano aspects follows:

CLOCK MODE:
0 = midi clock (sync to DAW). an implementation example is included in nanoSuite.als. 
in this mode, make a midi clip in your DAW that send 16 note with velocities 1-16, one per pulse (16th notes). send this to your IAC bus.  you will want to compensate for the delay caused by the IAC bus.
1 = ChucK based clock. pulses OSC, can send signal over network, has swing, metronome

NANOPITCH was designed for D16's Phoscyon. if using Phoscyon, for accents make sure you have the highest velocity tolerance (above 96) selected in settings. 

NANORHYTHM: you can customize which notes #s are triggered by which each drum seq if you open up nanoRhythm.ck, its towards the top (and should be highly visible). this may be necessary to set up nanoRhythm with a vst drumbox like Drumazon that by default has non-linear note #s.
pitch sequencing starts at C2 in Ableton.


USING ABLETON LIVE
check out ableton.jpeg for midi help.
make sure the nano's midi input/out are NOT on in Ableton. the midi will be passed from chuck through the IAC bus to your DAW. just have your IAC's input midi enabled and midi learn them as normal. 

the knobs available for midi learning change depending on if you use the chuck clock (see .png). if using suite mode 2 (both rhythm and pitch) with chuck clock, the clock controls are on the nanoRhythm.

don't forget to compensate for the delay caused by the IAC bus.

-----------------------------------------------------------------
feel free to use any of this code in any way you see fit. let me know if you do anything cool with it (bruce dot lott at gmail dot com)!
       .__                   __               __                 .__                 
  ____ |  |__  __ __   ____ |  | __   ______  \ \   _______ __ __|  |   ____   ______
_/ ___\|  |  \|  |  \_/ ___\|  |/ /  /_____/   \ \  \_  __ \  |  \  | _/ __ \ /  ___/
\  \___|   Y  \  |  /\  \___|    <   /_____/   / /   |  | \/  |  /  |_\  ___/ \___ \ 
 \___  >___|  /____/  \___  >__|_ \           /_/    |__|  |____/|____/\___  >____  >
     \/     \/            \/     \/                                        \/     \/