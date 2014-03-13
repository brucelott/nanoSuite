// Clock_OSC.ck
// A clock that pulse local OSC (and network OSC if desired)
// by Bruce Lott & Ness Morris, August 2013 
public class Clock{
    int stepDiv, playing, metroOn, networking;
    float BPM, cStep, nSteps, swingAmt;
    dur stepLen, SPB, swing; 
    time lastStep;
    Shred loopS;
    SinOsc metro;
    ADSR metroEnv;
    OscSend locXmit;    // sends clock info locally
    OscSend netXmit[0]; // for sending clock over network	
    OscRecv orec;


    //-------------------- Functions --------------------
    //---- Inits ----
    fun void init(){ init(120.0); }
    fun void init(float nTempo){
        locXmit.setHost("localhost", 98765);
        1 => stepDiv;
        0 => metroOn;
        Math.FLOAT_MAX => nSteps;
        tempo(nTempo);
        stepDivider(4); // sets steps to 16th notes
        play(1);
        spork ~ loop() @=> loopS;
        // metronome
        if(metroOn){
            metro.freq(Std.mtof(60));
            metroEnv.set(1::ms, 10::ms, 0, 0::ms);
            metro => metroEnv => dac;
        }
    }

    fun void initOscRecv(){
        11111 => orec.port;
        orec.listen();
        spork ~ playOSC();
        spork ~ tempoOSC();
        spork ~ incTempoOSC();
        spork ~ swingAmountOSC();
        spork ~ stepDividerOSC();
        spork ~ metronomeOSC();
        spork ~ killOSC();
    }

    fun void initNetOsc(string adr, int port){
        1 => networking;
        netXmit << new OscSend;
        netXmit[netXmit.cap()-1].setHost(adr,port);
    }    

    //---- Clocks Heart <3s ----
    fun void loop(){ // main loop, if not playing, wait
        while(true){
            if(playing) wait();
            else samp => now;
        }
    }

    fun void wait(){ // checks if a step has passed
        if(cStep%2==0){ 
            if(now-lastStep >= stepLen + swing) incStep();
        }
        else{
            if(now-lastStep >= stepLen - swing) incStep();
        }

        samp => now;
    }

    fun void incStep(){ // increments and broadcasts step event
        now => lastStep;
        if(cStep+1 < nSteps) 1 +=> cStep;
        else 0 => cStep;
        locXmit.startMsg("/c, f");
        locXmit.addFloat(cStep);
        if(networking){
            for(int i; i<netXmit.cap(); i++){
                netXmit[i].startMsg("/c, f");
                netXmit[i].addFloat(cStep);
            }
        }
        if(metroOn){ 
            metroEnv.keyOff();
            metroEnv.keyOn();
        } 
    }

    //----- controls -----
    fun int play(){ return playing; } 
    fun int play(int p){
        if(p){
            now => lastStep; // start playing/if already playing, re-cue
            0 => cStep;
            1 => playing;
            locXmit.startMsg("/c, f");
            locXmit.addFloat(cStep);
            if(networking){
                for(int i; i<netXmit.cap(); i++){
                    netXmit[i].startMsg("/c, f");
                    netXmit[i].addFloat(cStep);
                }
            }
        }
        else 0 => playing; // else stop
        return playing;
    }    

    fun float tempo(){ return BPM; } 
    fun float tempo(float newBPM){
        newBPM => BPM;
        60.0::second/BPM => SPB;
        stepDivider(stepDiv);
        return BPM;
    }

    fun float incTempo(int inc){ return tempo(BPM + inc); }
    fun float incTempo(float inc){ return tempo(BPM + inc); }

    fun float swingAmount(){ return swingAmt; }
    fun float swingAmount(float s){
        unitClip(s) => swingAmt;
        stepLen * swingAmt => swing;
    }    

    fun int stepDivider() { return stepDiv; }
    fun int stepDivider(int d){
        if(d>0){
            d => stepDiv;
            SPB/stepDiv => stepLen;
            swingAmount(swingAmt);
        }
        return stepDiv;
    }

    fun int metronome(){ return metroOn; }
    fun int metronome(int m){
        if(!m) 0 => metroOn;
        else 1 => metroOn;
        return metroOn;
    }

    fun dur stepLength(){ return stepLen; }

    fun void kill(){ loopS.exit(); } 

    // OSC    
    fun void playOSC(){
    	orec.event("/play, i") @=> OscEvent playEv;
        while(playEv => now){
            while(playEv.nextMsg() != 0){	
                play(playEv.getInt());	
            }
        }
    }

    fun void tempoOSC(){
    	orec.event("/tempo, f") @=> OscEvent tempoEv;
        while(tempoEv => now){
            while(tempoEv.nextMsg() != 0){	
                tempo(tempoEv.getFloat());	
            }
        }
    }     

    fun void incTempoOSC(){
    	orec.event("/incTempo, f") @=> OscEvent incTempoEv;
        while(incTempoEv => now){
            while(incTempoEv.nextMsg() != 0){	
                incTempo(incTempoEv.getFloat());	
            }
        }
    }

    fun void swingAmountOSC(){
    	orec.event("/swing, f") @=> OscEvent swingEv;
        while(swingEv => now){
            while(swingEv.nextMsg() != 0){
                swingAmount(swingEv.getFloat());
            }
        }
    }     

    fun void stepDividerOSC(){
    	orec.event("/stepDiv, i") @=> OscEvent stepDivEv;
        while(stepDivEv => now){
            while(stepDivEv.nextMsg() != 0){	
                stepDivider(stepDivEv.getInt());			
            }
        }
    }

    fun void metronomeOSC(){
    	orec.event("/metro, i") @=> OscEvent metroEv;
        while(metroEv => now){
            while(metroEv.nextMsg() != 0){	
                metronome(metroEv.getInt());
            }
        }
    }  

    fun void killOSC(){
    	orec.event("/kill") @=> OscEvent killEv;
        while(killEv => now){
        	while(killEv.nextMsg() != 0){
            	kill();
        	}
        }
    } 

    // utilities
    fun float unitClip(float f){ // clips to 0.0-1.0
        if(f<0) return 0.0;
        else if(f>1) return 1.0;
        else return f;
    }
    
}