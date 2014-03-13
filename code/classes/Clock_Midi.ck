// Clock_Midi.ck
// waits on midi note ons
// sends local OSC to chuck things, using velocity as step number
// by Bruce Lott, february 2013 
public class MidiClock{

    int metroOn, networking;
    float cStep;
    Shred loopS;
    SinOsc metro;
    ADSR metroEnv;
    OscSend locXmit;    // sends clock info locally
    OscSend netXmit[0]; // sends clock over network	
    OscRecv orec;
	MidiIn min;
	MidiMsg msg;

	// initializer
	fun void init(int minName){
		min.open(minName);
        locXmit.setHost("localhost", 98765);
        0 => metroOn;
        spork ~ loop() @=> loopS;
        //Metronome
        if(metroOn){
            metro.freq(Std.mtof(60));
            metroEnv.set(1::ms, 10::ms, 0, 0::ms);
            metro => metroEnv => dac;
        }
	}

    fun void initOscRecv(){
        11111 => orec.port;
        orec.listen();
        spork ~ metronomeOSC();
        spork ~ killOSC();
    }

    fun void initNetOsc(string adr, int port){
        1 => networking;
        netXmit << new OscSend;
        netXmit[netXmit.cap()-1].setHost(adr,port);
    }    

	// clocks heart <3
	fun void loop(){
		while(min => now){
			while(min.recv(msg)){
				if(msg.data1 == 0x90){	
					msg.data3-1 => cStep;	
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
        	}
		}
	}

    fun int metronome(){ return metroOn; }
    fun int metronome(int m){
        if(!m) 0 => metroOn;
        else 1 => metroOn;
        return metroOn;
    }

    fun void kill(){ loopS.exit(); } 

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

    //Utilities
    fun float unitClip(float f){ //clips to 0.0-1.0
        if(f<0) return 0.0;
        else if(f>1) return 1.0;
        else return f;
    }
}
