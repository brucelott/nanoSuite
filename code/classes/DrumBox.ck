// this is a set of sequencers used in a classic-esque drumbox setup.
// you can select a pattern to edit seperately from the one playing.
// you can only edit params of the selected drum or a global param.
public class DrumBox{
    MidiRhythmSequencer drum[];
    int drumSel, numDrums, patLenAll;
    int patLen[];
    
    // initialize
    fun void init(int busOut){ init(busOut,1, 8, 16); }
    fun void init(int busOut, int ch, int nDrums, int pLen){
        nDrums => numDrums;
        new MidiRhythmSequencer[numDrums] @=> drum;
        new int[numDrums] @=> patLen;
        for(int i; i<numDrums; i++){
            drum[i].init(busOut, ch, i+36);
            pLen => patLenAll;
            patLenAll => patLen[i];
            drum[i].patternLength(patLen[i]);
        }
    }
    
    // functions
    fun int patternLength(int pl){
        pl => patLen[drumSel];
        if(patLen[drumSel]<patLenAll){
            return drum[drumSel].patternLength(patLen[drumSel]);
        }
        //return patLen[drumSel];
    }
    
    fun int patternLength(int d, int pl){
        if(d>-1 & d<numDrums){
            pl => patLen[d];
            if(patLen[d]<patLenAll){
                drum[d].patternLength(patLen[d]);
            }
        }
        return patLen[drumSel];
    }
    
    fun int patternLengthAll(int pl){
        pl => patLenAll;
        for(int i; i<numDrums; i++){
            if(patLenAll<patLen[drumSel]){
                drum[i].patternLength(patLenAll);
            }
        }
    }
    
    fun int drumSelect(){ return drumSel; }
    fun int drumSelect(int d){
        d => drumSel;
        return drumSel;
    }
    
    fun float trigger(int step){
        return drum[drumSel].trigger(step);
    }
    
    fun int toggleStep(int step){  
        if(drum[drumSel].trigger(step)){
            drum[drumSel].trigger(step, 0);
            return 0;
        }
        else{ 
            drum[drumSel].trigger(step, .75);
            return 1;
        }
    }
    
    fun int channel(){ return drum[0].channel(); }
    fun int channel(int c){
        if(c>=0 & c<16){
            for(int i; i<numDrums; i++){
                return drum[i].channel(c);
            }
        }
        //return drum[0].channel();
    }		
    
    fun void foldAll(int f){
        for(int i; i<numDrums; i++){
            drum[i].fold(f);
        }
    }
    
    fun void fold(int f){
        drum[drumSel].fold(f);
    }
    
    fun int patternEditing(){ return drum[drumSel].patternEditing(); } 
    fun int patternEditing(int p){ // changes selected drums pattern being edited
        if(p>=0 & p<drum[0].numberOfPatterns()){
            for(int i; i<numDrums; i++){
                return drum[i].patternEditing(p);
            }
        }
    }
    
    fun int patternPlaying(){ return drum[0].patternPlaying(); }
    fun int patternPlaying(int p){
        if(p>=0 & p<drum[0].numberOfPatterns()){
            for(int i; i<numDrums; i++){
                return drum[i].patternPlaying(p);
            }
        }
    }
    fun int patternLength(){ return drum[drumSel].patternLength(); } 
    fun int patternLength( int p){
        if(p>=0 & p<drum[0].numberOfSteps()){
           return drum[drumSel].patternLength(p);
        }
    }
    
    fun int patternLengthAll(int p){
        if(p>=0 & p<drum[0].numberOfSteps()){
            for(int i; i<numDrums; i++){
                return drum[i].patternLength(p);
            }
        }
    }
    
    fun void clearTriggers(){
        drum[drumSel].clearTriggers();
    }
    
    fun void clearAllTriggers(){
        for(int i; i<numDrums; i++){
            drum[i].clearTriggers();
        }
    }
    
    fun int numberOfDrums(){ return numDrums; }
    
    fun int currentStep(){ return drum[drumSel].currentStep(); }
    
    fun void savePattern(){
        drum[drumSel].savePattern();
    }
    
    fun void loadPattern(){
        drum[drumSel].loadPattern();
    }
    
    fun void saveAllPatterns(){
        for(int i; i<numDrums; i++){
            drum[i].savePattern();
        }
    }
    
    fun void loadAllPattern(){
        for(int i; i<numDrums; i++){
            drum[i].loadPattern();
        }
    }
}
