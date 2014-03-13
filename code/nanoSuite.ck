// nanoSuite.ck
// launches all classes and programs
// by Bruce Lott and Ness Morris
// 2013-2014

// clocking
Machine.add(me.dir()+"/classes/Clock_OSC.ck");
Machine.add(me.dir()+"/classes/Clock_Midi.ck");
// sequencing
Machine.add(me.dir()+"/classes/Sequencer.ck");
Machine.add(me.dir()+"/classes/RhythmSequencer_Midi.ck");
Machine.add(me.dir()+"/classes/DrumBox.ck");
Machine.add(me.dir()+"/classes/PitchSequencer_Midi.ck");
// nanoKONTROL interface
Machine.add(me.dir()+"/classes/nanoKONTROL2.ck");
Machine.add(me.dir()+"/nanoRhythm.ck");
Machine.add(me.dir()+"/nanoPitch.ck");
// push
Machine.add(me.dir()+"/classes/Push.ck");
Machine.add(me.dir()+"/classes/PushKnob.ck");
//nano runner
Machine.add(me.dir()+"/nanoRunner.ck");
