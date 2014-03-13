// RhythmSequencer_Midi.ck
// A rhythm sequencer that triggers midi 
// by Bruce Lott, 2013
public class MidiRhythmSequencer extends Sequencer{
    MidiOut mout;
    MidiMsg msg;
    int curCC;     //current CC 
    int chan;
    //Initializer
    fun void init(int moutName,int ch,int newCC){
        _init(); //base Sequencer's init
        mout.open(moutName);
        CC(newCC);
        channel(ch);
        100 => msg.data3;
    }    
    
    fun int CC(){ return curCC; }
    fun int CC(int newCC){
        newCC => curCC;
        curCC => msg.data2;
        return curCC;
    }

	fun int channel(){ return chan; }
	fun int channel(int c){
		c => chan;
		return chan;
	}
    
    fun void doStep(){                 //opens gate and sporks closeGate()
        if(trig[pPlay][cStep]){ 
            0x90+chan => msg.data1;
            mout.send(msg);
            spork ~ closeGate();
        }
    }
    
    fun void closeGate(){              //quickly closes gate
        25::ms => now;
        0x80+chan => msg.data1;
        mout.send(msg);
    }   
}
