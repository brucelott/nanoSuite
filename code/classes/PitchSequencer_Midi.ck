// PitchSequencer_Midi.ck
// A pitch sequencer that triggers midi on channel 1
// by Bruce Lott, 2013-2014
public class PitchSequencer extends Sequencer{
    int accent[][];
    int tie[][];
    float pitch[][];  
    int trans, oct, vel, lastPitch;
	60 => int gateT; 
	MidiOut mout;
	MidiMsg msg;

    fun void init(int newBusMout){
        _init();
        mout.open(newBusMout);
        4 => oct;
        new int[nPats][nSteps] @=> accent;
        new int[nPats][nSteps] @=> tie;
        new float[nPats][nSteps] @=> pitch;
    }

    fun void setPitch(float p){ p => pitch[pEdit][cStep]; }
    fun void setPitch(int s, float p){ p => pitch[pEdit][s]; }
    fun void setPitch(int pat, int s, float p){ p => pitch[pat][s]; }

    fun float getPitch(){ return pitch[pEdit][cStep]; }
    fun float getPitch(int s){ return pitch[pEdit][s]; } 
    fun float getPitch(int p, int s){ return pitch[p][s]; }

	fun int gateTime(){ return gateT; }
	fun int gateTime(int gt){
		gt => gateT;
		return gateT;
	}

	fun int octave(){ return oct; }
	fun int octave(int o){
		o => oct;
		return oct;
	}

    fun void setAccent(int t){ t => accent[pEdit][cStep]; }
    fun void setAccent(int s, int t){ t => accent[pEdit][s]; }
    fun void setAccent(int p, int s, int t){ t => accent[p][s]; }

    fun void toggleAccent(int s){
        !accent[pEdit][s] => accent[pEdit][s];
    }    
    fun void toggleAccent(int p, int s){
        !accent[p][s] => accent[p][s];
    }

    fun int getAccent(){ return accent[pEdit][cStep]; }
    fun int getAccent(int s){ return accent[pEdit][s]; }
    fun int getAccent(int p, int s){ return accent[p][s]; }

    fun void setTie(int t){ t => tie[pEdit][cStep]; }
    fun void setTie(int s, int t){ t => tie[pEdit][s]; }
    fun void setTie(int p, int s, int t){ t => tie[p][s]; }

    fun void toggleTie(int s){
        if(tie[pEdit][s]) 0 => tie[pEdit][s];
        else 1 => tie[pEdit][s];
    }    
    fun void toggleTie(int p, int s){
        if(tie[p][s]) 0 => tie[p][s];
        else 1 => tie[p][s];
    }

    fun int getTie(){ return tie[pEdit][cStep]; }
    fun int getTie(int s){ return tie[pEdit][s]; }
    fun int getTie(int p, int s){ return tie[p][s]; }

    fun int transpose(){ return trans; }
    fun int transpose(int t){
    	t => trans;
    	return trans;
    }

    fun void doStep(){
        if(trig[pPlay][cStep]>0){
     		80 => int vel;
     		if(accent[pPlay][cStep]) 40 +=> vel;
			(pitch[pPlay][cStep]+trans+(oct*12))$int => int pit;
            if(tie[pPlay][cStep]){
                midiOut(0x90, pit, vel); // cur note on
                1::ms => now;
                midiOut(0x80, lastPitch, 10); // last note off
            }
            else{ // gate
                midiOut(0x90, pit, vel); // cur note on
                spork ~ gateOff(pit, vel) @=> Shred g; // timed cur note off
                if(pit != lastPitch){
                    1::ms => now;
                    midiOut(0x80, lastPitch, vel); 
                }
            }
            pit => lastPitch;
        }
        else{
            if(!tie[pPlay][cStep] & lastPitch !=0){ 
                midiOut(0x80, lastPitch, vel);
                0 => lastPitch;
            }
        }
    }

	fun void gateOff(int p, int v){
    	gateT::ms => now;
    	midiOut(0x80, p, v); 
	}

    fun void midiOut(int d1, int d2, int d3){
		d1 => msg.data1;
		d2 => msg.data2;
		d3 => msg.data3;
		mout.send(msg);
    }
}
