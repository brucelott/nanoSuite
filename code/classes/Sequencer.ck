// Sequencer.ck
// Sequencer base class to extend from
// Uses local OSC 
// by Bruce Lott, 2013

public class Sequencer{
    int pLen, nSteps, cStep; // pattern length, number of steps, current step
    int nPats, pPlay, pEdit; // number of pats, pat playing, pat being edited
    float trig[][]; // [pat][step] returns a velocity or note is off (0)
    float trigBuf[][]; // a backup to revert to
    Shred clockShred;
    
    //Initializer
    fun void _init(){
        //Defaults
        0  => cStep => pPlay => pEdit;
        8  => pLen => nPats;
        64 => nSteps;
        new float[nPats][nSteps] @=> trig;
        new float[nPats][nSteps] @=> trigBuf;
        clearAllTriggers();
        spork ~ clockInit() @=> clockShred;
    }  
    
    // --------- Functions ----------
    
    // ---- Sequencer's Heart <3 ----
    
    fun void clockInit(){
        OscRecv orec;
        98765 => orec.port;
        orec.listen();
        orec.event("/c, f") @=> OscEvent e; //
        while(e => now){
            while(e.nextMsg() !=0){
                Math.fmod(e.getFloat(), pLen)$int => cStep;
                doStep(); 
            }
        }
    }
    
    fun void doStep(){ } // what happens when arriving at a new step
                         // override this in child class     
                           
    // paramaters
    fun float[][] savePattern(){
		for(int i; i<nSteps; i++){
			trig[pEdit][i] => trigBuf[pEdit][i];
		}
		return trigBuf;
	}

	fun float[][] loadPattern(){
		for(int i; i<nSteps; i++){
			trigBuf[pEdit][i] => trig[pEdit][i];
		}
		return trig;
	}

	fun void fold(int f){
		if(f<nSteps){ // only even folds for now
			(nSteps/f)$int => int foldSize;
			for(1 => int j; j<f; j++){
				for(int i; i<foldSize; i++){
					trig[pEdit][i] => trig[pEdit][i+(foldSize*j)];
				}
			}
		}
	}
    
    fun float trigger(int step){ return trig[pEdit][step]; }// get step's trigger value
    fun float trigger(int step, float val){              // sets step's trigger value
        val => trig[pEdit][step];
        return trig[pEdit][step];
    }
   
    fun void clearTriggers(){            // clear editing pattern's triggers
        for(int i; i<trig[0].cap(); i++){
            0 => trig[pEdit][i];
        }
    }
    
    fun void clearAllTriggers(){         // clear all patterns' triggers
        for(int i; i<trig.cap(); i++){
            for(int j; j<trig[0].cap(); j++){
                0 => trig[i][j];
            }
        }
    }

    fun int numberOfSteps(){ return nSteps; }
    
    fun int numberOfPatterns(){ return nPats; }
    
    fun int currentStep(){ return cStep; }
    
    fun void kill(){ clockShred.exit(); }
    
    // pattern select functionality
    fun int patternPlaying(){ return pPlay; } // pattern being played/broadcast
    fun int patternPlaying(int pp){
        if(pp>=0 & pp<nPats) pp => pPlay;
        return pPlay;
    }
    
    fun int patternEditing(){ return pEdit; } // pattern being edited
    fun int patternEditing(int pe){
        if(pe>=0 & pe<nPats) pe => pEdit;
        return pEdit;
    }
    
    fun int patternLength(){ return pLen; }  // pattern 
    fun int patternLength(int pl){
        if(pl>0 & pl<=nSteps) pl => pLen;
        return pLen;
    }
}
