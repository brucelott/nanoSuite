// nanoRhythm.ck
// nanoKONTROL2 based 16 step rhythm seqeuncer
// by Bruce Lott, 2013-2014
public class nanoRhythm{
    // nano midi in/out
    MidiIn nanoMin;
    MidiOut nanoMout;
    MidiMsg nanoMsg;
    // midi bus out (to sequencer)
    MidiOut busMout;             // uses channel 2 by default
    MidiMsg busMsg;
    1.0/127.0 => float midiNorm; // normalizes 0-127 to 0.0-1.0
    OscSend clockXmit;// osc to control clock params
    int clockControl; // if this nano controls clock params
    //classes
    NanoKONTROL2 nano;
	DrumBox box;

    // initializer
    fun void init(int clockCtrl, int nanoIn, int nanoOut, int busOut){
        clockCtrl => clockControl;
        if(clockControl){
            clockXmit.setHost("localhost", 11111); 
        }
            box.init(busOut); //C1-G1 
            box.patternLengthAll(16);
        //--------------change CC's here!----------------\\
        /*
           box.rseq[0].CC(60));
           box.rseq[1].CC(63));
           box.rseq[2].CC(67));
           box.rseq[3].CC(71));
           box.rseq[4].CC(66));
           box.rseq[5].CC(68));
           box.rseq[6].CC(74));
           box.rseq[7].CC(76));
         */
        nanoMout.open(nanoOut);
        nanoMin.open(nanoIn);
        busMout.open(busOut);

        spork ~ nanoMidi(nanoMin);
        // initialize LEDs
        allLEDsOff();
        nanoMidiOut(nano.rew, 127); // pat 1 LED
        nanoMidiOut(nano.cyc, 127);
        spork ~ playBlink();
        spork ~ recBlink();
        nanoMidiOut(nano.button[0][0], 127); //drumSelect 0 LED 
    }

    // functionss

    fun void toggleStep(int s){
		box.toggleStep(s);
		updateStep(s);
    }

	fun void updateStep(int s){ // updates leds for a step on/off button
		if(s<8){ 
    		if(box.trigger(s)){
        		nanoMidiOut(nano.button[s%8][1], 127);
    		}
    		else nanoMidiOut(nano.button[s%8][1], 0);
		}
		else{
    		if(box.trigger(s)){
        		nanoMidiOut(nano.button[s%8][2], 127);
    		}
    		else nanoMidiOut(nano.button[s%8][2], 0);
		}
	}

	fun void drumSelect(int d){ // changes drum being edited
    	nanoMidiOut(nano.button[box.drumSelect()][0], 0);
    	box.drumSelect(d);
    	nanoMidiOut(nano.button[box.drumSelect()][0], 127);
    	showEditing();
	}

	fun void showEditing(){
    	if(box.patternEditing() != box.patternPlaying()){ 
        	nanoMidiOut(nano.cyc, 0);
    	}
    	else nanoMidiOut(nano.cyc, 127);
    	// updates step LEDs
    	for(int i; i<16; i++){
        	updateStep(i);
    	}
	}

	fun void patternEditing(int p){ // changes selected drums pattern being edited
		box.patternEditing(p);
      	showEditing();
	}

	// parameters controls

	fun void nanoMidi(MidiIn theMin){ 
    	MidiMsg msg;
    	while(true){ // waits on midi pass to function
        	theMin => now;
        	while(theMin.recv(msg)){
            	if(nano.isKnob(msg.data2)){
                	knobs(msg.data2, msg.data3);
            	}
            	else if(nano.isFader(msg.data2)){ 
                	faders(msg.data2, msg.data3);
            	}
            	else if(nano.isButton(msg.data2)){ 
                	buttons(msg.data2, msg.data3);
            	}
            	else if(nano.isTransport(msg.data2)){ 
                	transport(msg.data2, msg.data3);
            	}
        	}
    	}
	}

	fun void buttons(int cc, int val){ // main grid of buttons
    	if(val){
        	if(nano.buttonRow(cc) == 0){     // drum select 
            	for(int i; i<8; i++){
                	if(cc == nano.button[i][0]) drumSelect(i);
            	}
        	}
        	else if(nano.buttonRow(cc)==1){  // steps 0-7 on/offs
        		for(int i; i<8; i++){
            		if(cc == nano.button[i][1]){ 
						box.toggleStep(i);
						updateStep(i);
					}
        		}
    		}
    		else if(nano.buttonRow(cc)==2){  // steps 8-15 on/off
    			for(int i; i<8; i++){
        			if(cc == nano.button[i][2]){
        				box.toggleStep(i+8);
        				updateStep(i+8);
        			}
    			}
			}
		}
	}

	fun void knobs(int cc, int val){
    	if(clockControl){ //if using ChucK clock
        	if(cc==nano.knob[5]){  // pattern length of all drums/rseqs
            		box.patternLengthAll(Math.pow(2,Math.round(val*midiNorm*4))$int);
    		}
    		else if(cc==nano.knob[6]){ // swing
        		clockXmit.startMsg("/swing, f");
        		clockXmit.addFloat(val*midiNorm); 
    		}
    		else if(cc==nano.knob[7]){ // tempo
        		clockXmit.startMsg("/tempo, f"); 	
        		clockXmit.addFloat(val*midiNorm*180+50);
    		}
    		else{
        		for(0 => int i; i<5; i++){ // diff range CCs per drum
            		if(cc==nano.knob[i]){  // midi learn to drum params
                		busMidiOut(box.drumSelect()*8+8+i, val);
                		break;
            		}
        		}
    		}
		}
		else{
    		if(cc==nano.knob[7]){ // pattern length of all drums/rseqs
    			for(int i; i<box.numberOfDrums(); i++){
        			box.patternLengthAll(Math.pow(2,Math.round(val*midiNorm*4))$int);
    			}
			}
			else{
    			for(0 => int i; i<7; i++){ // diff range CCs per drum
        			if(cc==nano.knob[i]){  // midi learn to drum params
            			busMidiOut(box.drumSelect()*8+8+i, val);
            			break;
        			}
    			}
			}

		}
	}

	fun void faders(int cc, int val){ // midi learn to drum vols
    	for(int i; i<box.numberOfDrums(); i++){
        	if(cc==nano.fader[i]) busMidiOut(i + 64, val);
    	}
	}

	fun void transport(int cc, int val){ // transport buttons
    	if(val){
        	if(clockControl){ // if using ChucK clock
            	if(cc==nano.ply){ 
                	clockXmit.startMsg("/play, i");
                	clockXmit.addInt(1);
                	nanoMidiOut(nano.stp,0);
                	nanoMidiOut(nano.ply,127);
            	}
            	else if(cc==nano.stp){ 
                	clockXmit.startMsg("/play, i");
                	clockXmit.addInt(0);
                	nanoMidiOut(nano.ply,0);
                	nanoMidiOut(nano.rec,0);
                	nanoMidiOut(nano.stp,127);
            	}
        	}
        	// pattern select/playing buttons
        	else if(cc==nano.rew) {
            	for(int i; i<box.numberOfDrums(); i++){
                	box.patternEditing(0);
            	}
            	nanoMidiOut(nano.ffw,0);
            	nanoMidiOut(nano.rew,127);
            	showEditing();
        	}
        	else if(cc==nano.ffw){
            	for(int i; i<box.numberOfDrums(); i++){
                	box.patternEditing(1);
            	}
            	nanoMidiOut(nano.rew,0);
            	nanoMidiOut(nano.ffw,127);
            	showEditing();
        	}
        	else if(cc==nano.cyc){
            	for(int i; i<box.numberOfDrums(); i++){
                	box.patternPlaying(box.patternEditing());
            	}
            	showEditing();
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
    	for(int i; i<nano.trans.cap(); i++){
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
            	if(box.trigger(e.getFloat()$int % box.patternLength())){
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
            	if(!(e.getFloat()$int % 4)){
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

	fun void nanoMidiOut(int d1, int d2, int d3){
    	d1 => nanoMsg.data1;
    	d2   => nanoMsg.data2;
    	d3   => nanoMsg.data3;
    	nanoMout.send(nanoMsg);
	}

	fun void busMidiOut(int d2, int d3){
    	0xB1 => busMsg.data1;
    	d2 => busMsg.data2;
    	d3 => busMsg.data3;
    	busMout.send(busMsg);
	}

}
