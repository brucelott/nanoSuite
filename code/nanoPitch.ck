// nanoPitch.ck
// nanoKONTROL2 based 8 step pitch sequencer
// by Bruce Lott, jan 2014
public class nanoPitch{
	// nano midi in/out
	MidiIn nanoMin;
	MidiOut nanoMout;
	MidiMsg nanoMsg;
	// midi bus out (to sequencer)
	MidiOut busMout;  // uses channel 1 by default
	MidiMsg busMsg;
	1.0/127.0 => float midiNorm; // normalizes 0-127 to 0.0-1.0
	// OSC control of ChucK clock
	OscSend clockXmit; // osc to control clock params
    int clockControl; // if this nano controls clock params
    //classes
	NanoKONTROL2 nano;
	PitchSequencer pseq;

	// initializer
	fun void init(int clockCtrl, int nanoIn, int nanoOut, int busOut){
		clockCtrl => clockControl;
		if(clockControl){	
			clockXmit.setHost("localhost",11111);	
		}
    	pseq.init(busOut);
    	pseq.patternLength(8);
     	pseq.octave(4);	
    	nanoMout.open(nanoOut);
    	nanoMin.open(nanoIn);
   		busMout.open(busOut);
    	spork ~ nanoMidi(nanoMin);
		// initialize LEDs
    	allLEDsOff();
    	nanoMidiOut(nano.rew, 127);
    	nanoMidiOut(nano.cyc, 127);
    	spork ~ playBlink();
    	spork ~ recBlink();
	}

	// functions

	fun void updateStep(int s){  // updates a steps LEDs
    	if(s<8){ 
    		if(pseq.trigger(s)){
    			nanoMidiOut(nano.button[s%8][0], 127);
    		}
    		else nanoMidiOut(nano.button[s%8][0], 0);
        	nanoMidiOut(nano.button[s][1], pseq.getTie(s)*127);
        	nanoMidiOut(nano.button[s][2], pseq.getAccent(s)*127);
    	}
	}

	fun void buttons(int cc, int val){ // main grid of buttons
    	if(val){
        	if(nano.buttonRow(cc)==0){ // gate step
            	for(int i; i<8; i++){
                	if(cc == nano.button[i][0]){ 
                		if(pseq.trigger(i)){
                			pseq.trigger(i,0);
                		}
                		else pseq.trigger(i,0.75);
                    	updateStep(i);
                	}
            	}
        	}
        	else if(nano.buttonRow(cc)==1){ // tie step to next
            	for(int i; i<8; i++){
                	if(cc == nano.button[i][1]){
                    	pseq.toggleTie(i);
                    	updateStep(i);
                	}
            	}
        	}
        	else if(nano.buttonRow(cc)==2){ // accent step
            	for(int i; i<8; i++){
                	if(cc == nano.button[i][2]){
                    	pseq.toggleAccent(i);
                    	updateStep(i);
                	}
            	}
        	}
    	}
	}

	fun void knobs(int cc, int val){
		if(clockControl){ // if using ChucK clock
			if(cc==nano.knob[3]){ // step gate time length
				pseq.gateTime(Math.pow(val*midiNorm*15,2)$int+1);
			}
			else if(cc==nano.knob[4]){
				pseq.transpose((val*midiNorm*24)$int); // transpose
			}
    		else if(cc==nano.knob[5]){   // pattern length
       			pseq.patternLength(Math.pow(2,Math.round(val*midiNorm*3))$int);
			}
    		else if(cc==nano.knob[6]){ //  swing
    			clockXmit.startMsg("/swing, f");
    			clockXmit.addFloat(val*midiNorm); 
    		}
    		else if(cc==nano.knob[7]){ // tempo
   				clockXmit.startMsg("/tempo, f");  	
    			clockXmit.addFloat(val*midiNorm*180+60);
    		}
			else{
    			for(0 => int i; i<3; i++){
        			if(cc==nano.knob[i]){    //midi learn to these
            			busMidiOut(i+8, val);
            			break;
        			}
    			}
			}
		}
		else{           // if using midi clock 
			if(cc==nano.knob[5]){
				pseq.gateTime(Math.pow(val*midiNorm*15,2)$int+1);
			}
			else if(cc==nano.knob[6]){
				pseq.transpose((val*midiNorm*24)$int); // transpose
			}
    		else if(cc==nano.knob[7]){    // pattern length 
       			pseq.patternLength(Math.pow(2,Math.round(val*midiNorm*3))$int);
			}
			else{
    			for(0 => int i; i<5; i++){
        			if(cc==nano.knob[i]){ // midi learn to these
            			busMidiOut(i+8, val);
            			break;
        			}
        		}
        	}
		}
	}

	fun void faders(int cc, int val){
    	for(int i; i<8; i++){
        	if(cc==nano.fader[i]){ // chromatic octave
        		pseq.setPitch(i, Math.round(val*midiNorm*12)); 
        	}	
    	}
	}

	fun void transport(int cc, int val){ // transport buttons
    	if(val){
    		if(clockControl){ // if using ChucK clock
        		if(cc==nano.ply){ 
            		clockXmit.startMsg("/play,i");
            		clockXmit.addInt(1);
            		nanoMidiOut(nano.stp,0);
            		nanoMidiOut(nano.ply,127);
        		}
        		else if(cc==nano.stp){ 
            		clockXmit.startMsg("/play,i");
            		clockXmit.addInt(0);
            		nanoMidiOut(nano.ply,0);
            		nanoMidiOut(nano.rec,0);
            		nanoMidiOut(nano.stp,127);
        		}
        	}
            // pattern select/playing buttons
        	else if(cc==nano.rew) {
            	pseq.patternEditing(0);
            	nanoMidiOut(nano.ffw,0);
            	nanoMidiOut(nano.rew,127);
            	showEditing();
        	}
        	else if(cc==nano.ffw){
            	pseq.patternEditing(1);
            	nanoMidiOut(nano.rew,0);
            	nanoMidiOut(nano.ffw,127);
            	showEditing();
        	}
        	else if(cc==nano.cyc){
            	pseq.patternPlaying(pseq.patternEditing());
            	showEditing();
        	}
    	}
	}

	fun void patternEditing(int p){ // change pattern being edited
    	if(0<=p<8){
        	pseq.patternEditing(p);
        	showEditing();
    	}
	}

	fun void showEditing(){ // loads all steps of pat being edited
    	if(pseq.patternEditing() != pseq.patternPlaying()){
    		nanoMidiOut(nano.cyc, 0);
   		}
    	else nanoMidiOut(nano.cyc, 127);
    	for(int i; i<8; i++){ // updates step LEDs
        	updateStep(i);
    	}
	}

	fun void nanoMidi(MidiIn theMin){ // passes midi to ctrl funcs
    	MidiMsg nanoMsg;
    	while(true){
        	theMin => now;
        	while(theMin.recv(nanoMsg)){
            	if(nano.isKnob(nanoMsg.data2)){
                	knobs(nanoMsg.data2, nanoMsg.data3);
            	}
            	else if(nano.isFader(nanoMsg.data2)){
                	faders(nanoMsg.data2, nanoMsg.data3);
            	}
            	else if(nano.isButton(nanoMsg.data2)){
                	buttons(nanoMsg.data2, nanoMsg.data3);
            	}
            	else if(nano.isTransport(nanoMsg.data2)){
                	transport(nanoMsg.data2, nanoMsg.data3);
            	}
        	}
    	}
	}

	// visual feedback

	fun void allLEDsOff(){
    	for(int i; i<8; i++){
        	for(int j; j<3; j++){
        		nanoMidiOut(nano.button[i][j], 0);
       		}
    	}
    	for( int i; i<nano.trans.cap(); i++){
    		nanoMidiOut(nano.trans[i], 0);
    	}
    	nanoMidiOut(nano.cyc, 0);
	}

	fun void recBlink(){ // blinks record button if a step is on
    	OscRecv orec;
    	98765 => orec.port;
    	orec.listen();
    	orec.event("/c, f") @=> OscEvent e;
    	while(e => now){
        	while(e.nextMsg() !=0){
            	if(pseq.trigger(e.getFloat()$int % pseq.pLen)){
                	nanoMidiOut(nano.rec, 127);
            	}
            	else nanoMidiOut(nano.rec, 0);
        	}
    	}
	}

	fun void playBlink(){ // blinks on quarter notes
    	OscRecv orec;
    	98765 => orec.port;
    	orec.listen();
    	orec.event("/c, f") @=> OscEvent e;
    	while(e => now){
        	while(e.nextMsg() !=0){
            	if(! (e.getFloat()$int % 4)){
                	nanoMidiOut(nano.ply, 127);
            	}
            	else nanoMidiOut(nano.ply, 0);
        	}
    	}
	}

 	// midi utilities

	fun void nanoMidiOut(int d2, int d3){
    	0xB0 => nanoMsg.data1;
    	d2   => nanoMsg.data2;
    	d3   => nanoMsg.data3;
    	nanoMout.send(nanoMsg);
	}


	fun void busMidiOut(int d2, int d3){
    	0xB0 => busMsg.data1;
    	d2   => busMsg.data2;
    	d3   => busMsg.data3;
    	busMout.send(busMsg);
	}

	fun void nanoMidiOut(int d1, int d2, int d3){
    	d1   => nanoMsg.data1;
    	d2   => nanoMsg.data2;
    	d3   => nanoMsg.data3;
    	nanoMout.send(nanoMsg);
	}

}
