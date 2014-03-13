// nanoRunner.ck
// helps setup and launch nanoSuite through console
// by Bruce Lott, feb 2014
Clock clock;
MidiClock mclock;
// console input suite setup 
ConsoleInput cI;
int suiteMode, clockMode, iacIn, iacOut;
int nano1in, nano1out, nano2in, nano2out;

chout <= IO.nl() <= "welcome to nanoSuite! let's get set up...";
chout <= IO.nl() <= IO.nl();

numericConsoleChoice(1,3,"suite mode: 1=drums, 2=synth, 3=both      ")=>suiteMode;
numericConsoleChoice(1,2,"clock mode: 1=midi clock, 2=chuck clock   ")=>clockMode;

// print midi device list
MidiIn min;
MidiOut mout;
min.printerr(0);
mout.printerr(0);

chout <= IO.nl() <= "Midi Ins:" <= IO.nl();
int devicesIn;
while(true){
	if(min.open(devicesIn)){
		chout<=devicesIn<= ": "<= min.name()<= IO.nl();
		devicesIn++;
	}
	else break;
}

chout <= IO.nl()<= "Midi Outs:"<=IO.nl();
int devicesOut;
while(true){
	if(mout.open(devicesOut)){ 
		chout<=devicesOut<=": "<=mout.name()<=IO.nl();
		devicesOut++;
	}
	else break;
}

chout <= IO.nl() <= "use numbers from the list above for the rest";
chout <= IO.nl() <= IO.nl();

numericConsoleChoice(0,devicesIn,"IAC bus in    ") => iacIn;
numericConsoleChoice(0,devicesOut,"IAC bus out   ") => iacOut;
numericConsoleChoice(0,devicesIn,"nano 1 in     ") => nano1in;
numericConsoleChoice(0,devicesOut,"nano 1 out    ") => nano1out;
if(suiteMode==2){
	numericConsoleChoice(0,devicesIn,"nano 2 in     ") => nano2in;
	numericConsoleChoice(0,devicesOut,"nano 2 out    ") => nano2out;
}

// which clock
if(clockMode-1){ // ChucK clock
	clock.init();
	clock.initOscRecv();
}
else{             // midi clock
	mclock.init(iacIn);
}

// suite mode
if(suiteMode==1){      // drums
    nanoRhythm nRhythm;
    nRhythm.init(clockMode-1, nano1in, nano1out, iacOut);

}
else if(suiteMode==2){ // synth
    nanoPitch nPitch;
    nPitch.init(clockMode-1, nano1in, nano1out, iacOut);   
}
else if(suiteMode==3){ // both
    nanoRhythm nRhythm;
    nanoPitch nPitch;
    nRhythm.init(clockMode-1, nano1in, nano1out, iacOut);
    nPitch.init(0, nano2in, nano2out, iacOut);   
}

chout <= IO.nl();
cI.prompt("nanoSuite setup complete!");

// main loop, keeps file nanoRunner.ck alive 
while(samp => now);

// function
fun int numericConsoleChoice(int minChoice,int maxChoice,string prompt){
	-1 => int val;
	string s;
	while(val<minChoice | val>maxChoice){
		cI.prompt(prompt);
		while(cI.more()){ 
			cI.getLine() => s;              // to protect against empty quotes
			if(RegEx.match("[[:digit:]]+",s)) Std.atoi(s) => val; // they atoi to 0
		}
	}
	return val;
}
