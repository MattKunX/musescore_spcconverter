/* 
 * SPC Converter v0.0.1
 * Created/maintained by Jared Bitz
 * ------------------------------------------
 * A MuseScore plugin for converting a score into a text format which can be compiled and
 * inserted into a Super Mario World ROM using using AddMusicK,
 * which is available at https://www.smwcentral.net/?p=section&a=details&id=24994
 */

import MuseScore 3.0
import FileIO 3.0
import QtQuick 2.2
import QtQuick.Dialogs 1.3
import QtQuick.Controls 2.0
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.5

MuseScore {
    menuPath: "Plugins.SPC Converter"
    description: "Converts your score to a .txt file which can be compiled by AddMusicK and inserted into a Super Mario World ROM."
    version: "0.0.1"
    pluginType: "dock"
    dockArea:   "right"
    width:  400
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Layout.fillWidth: true
            
        Button {
            text: "Reload Settings From Score";
            onClicked: loadDefaults();
            id: "reloadButton"
            Layout.leftMargin: 10
            
            contentItem: Text {
                text: reloadButton.text
                font: reloadButton.font
                opacity: enabled ? 1.0 : 0.3
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                implicitWidth: 100
                implicitHeight: 40
                opacity: enabled ? 1 : 0.3
                color: reloadButton.down ? "#aaaaaa" : "#cccccc"
                border.width: 1
                radius: 2
            }
        
        }
                    
        RowLayout {
            Layout.leftMargin: 10
            Layout.topMargin: 10
            Text { text: "Octave adjust: "}
            SpinBox { id: octaveAdjust; from: -5; to: 5; value: -2 }
        }
            
        CheckBox { Layout.leftMargin: 10; id: swingCheckBox; text: "Swing 8th notes" }
        CheckBox { Layout.leftMargin: 10; id: includeLabelsBox; text: "Include section labels" }

        Text { Layout.leftMargin: 10; text: "Header (use for custom instruments, metadata, etc.):" }
        TextArea {
            Layout.leftMargin: 10;
            text: ""
            id: "headerBox"
            Layout.fillWidth: true
            height: 200
            selectByMouse: true;
            background: Rectangle {
                implicitWidth: 400
                implicitHeight: 200
            }
        }

        RowLayout {
            Layout.leftMargin: 10
            Layout.topMargin:10

            Button { 
                id: "chooseFileButton"; 
                text: "Choose Destination" 
                onClicked: fileDialog.open();
                contentItem: Text {
                    text: chooseFileButton.text
                    font: chooseFileButton.font
                    opacity: enabled ? 1.0 : 0.3
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    implicitWidth: 100
                    implicitHeight: 40
                    opacity: enabled ? 1 : 0.3
                    color: chooseFileButton.down ? "#aaaaaa" : "#cccccc"
                    border.width: 1
                    radius: 2
                 }
            }            
            Text { id: "filePathLabel"; text: "(no destination chosen)" }
        }
                       
        Button {
            Layout.leftMargin: 10
            Layout.topMargin:10
            text: "Export"
            id: "exportButton"
            onClicked: {
                clearDebugLog();
                saveDefaults();
                if (exportFile.source === "") {
                    debugLog("Use the \"Choose Destination\" button to choose an export location before saving");
                }
                else {      
                    var output = processScore();
                    exportFile.write(output);
                    debugLog("File saved to " + exportFile.source);
                }
            }
            contentItem: Text {
                text: exportButton.text
                font: exportButton.font
                opacity: enabled ? 1.0 : 0.3
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                implicitWidth: 100
                implicitHeight: 40
                opacity: enabled ? 1 : 0.3
                color: exportButton.down ? "#aaaaaa" : "#cccccc"
                border.width: 1
                radius: 2
            }
        }

        Text { Layout.topMargin:10; text: "Messages:"; Layout.leftMargin: 10 }

        TextArea {
            Layout.leftMargin: 10
            id: debugBox
            text: ""
            Layout.fillWidth: true
            Layout.fillHeight: true
            wrapMode: TextEdit.Wrap
        }
    }
    //Dialogs
    FileDialog {
        id: fileDialog
        selectExisting: false
        title: "Export Location"
        folder: shortcuts.home
        onAccepted: {
            filePathLabel.text = fileDialog.fileUrl.toString();
            exportFile.source = filePathLabel.text.substring(7, filePathLabel.text.length);
        }
    }

    FileIO {
        id: exportFile;
        source: ""
    }

    function debugLog(msg) {
        debugBox.text += msg + "\n\n";
    }

    function clearDebugLog() {
        debugBox.text = "";
    }

    //Calculates the greatest common divisor of two integers x and y using Euclid's algorithm
    function gcd(x, y)  {
        x = Math.abs(x);
        y = Math.abs(y);
        if (x == 0 || y == 0) return 0;
        while(y) {
            var t = y;
            y = x % y;
            x = t;
        }
        return x;
    }

    //Calculates the least common multiple of two integers x and y
    function lcm(x, y) {
        if (x == 0 || y == 0) return 0;
        return (x * y) / gcd(x,y);
    }

    //Adds two FractionWrapper objects and returns the sum in lowest terms
    function addFrac(frac1, frac2) {
        if (frac1.numerator == 0) {
            return frac2;
        }
        if (frac2.numerator == 0) {
            return frac1;
        }

        var denom = lcm(frac1.denominator, frac2.denominator);
        var m1 = denom / frac1.denominator;
        var m2 = denom / frac2.denominator;
        return reduceFrac(fraction(frac1.numerator * m1 + frac2.numerator * m2, denom));
    }

    //Converts a FractionWrapper object to lowest terms
    function reduceFrac(frac) {
        if (frac.numerator == 0) {
            return fraction(0, 1);
        }
        var k = gcd(frac.numerator, frac.denominator);
        return fraction(frac.numerator / k, frac.denominator / k);
    }

    //Calcualtes the p-adic order of n, in other words the largest integer
    //k such that p^k evenly divides n
    function padicOrder(n, p) {
        var exponent = 0;
        while (n % Math.pow(p, exponent) == 0) {
            exponent += 1;
        }
        return exponent - 1;
    }

    //Converts a MuseScore tpc value into the corresponding note name for AddMusicK's SPC compiler
    function tpcToSpcName(tpc) {
        switch(tpc) {
            case -1: return "d+";
            case 0: return "a+";
            case 1: return "f";
            case 2: return "c";
            case 3: return "g";
            case 4: return "d";
            case 5: return "a";
            case 6: return "e";
            case 7: return "b";
            case 8: return "f+";
            case 9: return "c+";
            case 10: return "g+";
            case 11: return "d+";
            case 12: return "a+"
            case 13: return "f";
            case 14: return "c";
            case 15: return "g";
            case 16: return "d";
            case 17: return "a";
            case 18: return "e";
            case 19: return "b";
            case 20: return "f+";
            case 21: return "c+";
            case 22: return "g+";
            case 23: return "d+";
            case 24: return "a+";
            case 25: return "f";
            case 26: return "c";
            case 27: return "g";
            case 28: return "d";
            case 29: return "a";
            case 30: return "e";
            case 31: return "b";
            case 32: return "f+";
            case 33: return "c+";
            default: return "c"
        }
    }

    //Takes a FractionWrapper object and converts it to a string which can be used as a note length for AddMusicK
    //These strings are of the form "X^Y^Z^...". The total length of a note (as a fraction of a whole note) is 1/X + 1/Y + 1/Z + ...
    //So for example, "1" would be a whole note, "2^4" would be a dotted half note, and "8^16^32" would be a double-dotted eight note
    function literalDurationStringFromFraction(frac) {
        var durationString = "";
        var num = frac.numerator;
        var denom = frac.denominator;

        //First, seperate the whole and fractional parts
        while (num >= denom) {
            num -= denom;
            durationString += "1^"
        }

        /*OK, here's the deal with tuplets.
         *Suppose that a note has a length which can be written in fractional terms as p/q.
         *We can write q in the form 2^k * l, where l is not divisible by 2.
         *Then, we can use our normal duration processing code to get the representation of p/(2^k) in binary.
         *Multiplying the denominator of each of these digits by l then gives us a representation of p/q.
         *
         *For example, to write 5/6, we have l = 3 and k = 1, so we write
         *5/2 as 1/1 + 1/1 + 1/2. Therefore, 5/6 = (1/3)*(1/1 + 1/1 + 1/2),
         *which is the same as 1/3 + 1/3 + 1/6, with a string representation
         *of 3^3^6.
         */
        var k = padicOrder(denom, 2);
        var l = denom / Math.pow(2, k);
        denom = denom / l;

        //Convert numerator to base 2
        var base2String = num.toString(2);
        var numDigits = base2String.length;
        var curDenom = denom;
        for (var i = numDigits - 1; i >= 0; i--) {
            if (base2String[i] == "1") {
                durationString += (denom * l).toString() + "^"
            }
            denom /= 2
        }

        //Chop off excess caret if it exists
        if (durationString[durationString.length - 1] == "^") {
            durationString = durationString.substring(0, durationString.length - 1)
        }
        return durationString;
    }

    //Returns the amount of space in the measure before the given segment begins
    function getMeasurePositionOfSegment(curSegment, trackID) {
        var positionInMeasure = fraction(0, 1);
        while (curSegment.prevInMeasure != null) {
            curSegment = curSegment.prevInMeasure;
            //Search back in this specific track
            if (curSegment.segmentType == Segment.ChordRest && curSegment.elementAt(trackID) != null) {
                positionInMeasure = addFrac(positionInMeasure, curSegment.elementAt(trackID).actualDuration);
            }     
        }
        return positionInMeasure;
    }

    //If this note should be swung somehow, gets the proper duration based off
    //of its position in the measure
    function getSwingDuration(duration, positionInMeasure) {
        var num = duration.numerator;
        var denom = duration.denominator;

        /*If the denominator of the duration is 8, then since the fraction is always in simplest terms, the
         *numerator must be odd. So, we can write the duration as k/4 + 1/8 for some value of k, 
         *and view the note as some number of quarter notes (i.e. one full beat long) tied to an 8th note. 
         *Even when the eight note is swung, a quarter note will always have the same length 
         *(the only difference is whether it is represented as 1/3 + 2/3 of a beat or 2/3 + 1/3 of a beat). 
         *So, we only need to figure out whether that final eigth
         *note should be 1/3 of a beat or 2/3 in order to get the right duration for the entire note.
         */
        var k = Math.floor(num / 2);
        var nonSwungPortionString = "";  
        var nonSwungPortion = reduceFrac(fraction(k, 4));
        if (k > 0) {
            nonSwungPortionString = literalDurationStringFromFraction(nonSwungPortion);
        }

        //If the position in the measure has a denominator of 8, then this note must be on an offbeat
        //(again, it's in reduced form, so a denominator of 8 means the numerator cannot be odd)
        var swungPortion = positionInMeasure.denominator == 8 ? fraction(1, 12) : fraction(2, 12);
        var finalDuration = addFrac(nonSwungPortion, swungPortion);

        return literalDurationStringFromFraction(finalDuration);
    }

    //Given a duration [Fraction] and the position within the measure [Fraction] of  anote,
    //returns the a string representing its proper duration (possibly modified to account
    //for swing
    function durationStringFromFraction(duration, positionInMeasure) {
        if (swingCheckBox.checked && duration.denominator == 8) {
            return getSwingDuration(duration, positionInMeasure);

        } else {
            return literalDurationStringFromFraction(duration);    
        }
    }

    //Returns a string representing the duration of the given note
    function durationStringFromNote(note, trackID) {
        var curSegment = note.parent.parent;
        var positionInMeasure = getMeasurePositionOfSegment(curSegment, trackID);
        return durationStringFromFraction(note.parent.actualDuration, positionInMeasure);
    }

    //Takes a ScoreElement (either a rest or a chord) and returns its string representation to be used in
    //AddMusicK's compiler
    function stringifyElement(elm, trackID) {
        var noteName = "";
        var lengthString = "";
        if (elm.type == Element.CHORD) {
            var note = elm.notes[0] //Should only be one note per staff - no polyphony
                lengthString = durationStringFromNote(note, trackID);

            //If it's the first note in a group of ties, add durations together into one long note
            if (note.is(note.firstTiedNote)) {
                var end = note.lastTiedNote;
                var cur = note;
                while (!cur.is(end)) {
                    cur = cur.tieForward.endNote;
                    lengthString += "^" + durationStringFromNote(cur, trackID);
                }
            } else {  //Otherwise ignore it
                return "";
            }

            noteName = tpcToSpcName(note.tpc);

        } else if (elm.type == Element.REST) {
            var positionInMeasure = getMeasurePositionOfSegment(elm.parent, trackID);
            lengthString = durationStringFromFraction(elm.actualDuration, positionInMeasure);
            noteName = "r";
        }
        return noteName + lengthString;
    }

    //Given a Note object, returns its octave (as would be passed to AddMusicK)
    //Note: AddMusicK allows octave values between 1 and 5 (inclusive)
    //The spinbox in the interface can be adjusted to change how standard octave labels
    //(i.e. Middle C = C4) map onto the ones generated by this function
    function getOctave(note) {
        var MIN_ALLOWED_OCTAVE = 1;
        var MAX_ALLOWED_OCTAVE = 5;
        var octave = Math.floor(note.pitch / 12) + octaveAdjust.value;
        return Math.min(Math.max(octave, MIN_ALLOWED_OCTAVE), MAX_ALLOWED_OCTAVE);
    }

    //Checks whether the prevNote and curNote (both Note objects) lie in the same octave
    //If not, return the AddMusicK octave code which will switch octaves to the current note
    //Otherwise, return ""
    function getOctaveModifier(prevNote, curNote) {
        var prevOctave;
        if (prevNote === null)
            prevOctave = -99;
        else prevOctave = getOctave(prevNote);

        var curOctave = getOctave(curNote);

        if (prevOctave == curOctave) return "";
        else if (curOctave == prevOctave + 1) return ">";
        else if (curOctave == prevOctave - 1) return "<";
        else return "o" + curOctave;
    }

    //Processes any command written into the score as staff text with a "*" or "-" prefix
    //And converts it to the relevant code for AddMusicK
    function processCommand(text) {
        if(text.indexOf("tempo") == 1) {
            var SMB_TEMPO_CONSTANT = .4;
            var bpm = parseInt(text.split(" ")[1]);
            var smb_bpm = Math.round(bpm * SMB_TEMPO_CONSTANT);
            return "t" + Math.floor(smb_bpm);  
        } else if (text.indexOf("&amp") > -1) {
            while(text.indexOf("&amp") > -1) {
                var i = text.indexOf("&amp")
                    debugBox.text += i + "\n";
                text = text.substring(0, i + 1) + text.substring(i+5, text.length);
            }
            return text.substr(1, text.length);
        } else {
            return text.substr(1, text.length); //Chop off + or - postfix
        }

    }

    //Counts the number of measures in the given score
    function countMeasures(score) {
        var firstMeasure = score.firstMeasure;
        var count = 0;
        while (firstMeasure != null) {
            count += 1;
            firstMeasure = firstMeasure.nextMeasure;
        }
        return count;
    }
    
    function getMeasureNumber(measure) {
        var count = 0;
        while (measure != null) {
            count += 1;
            measure = measure.prevMeasure;
        }
        return count;
    }

    //Saves the export settings chosen in the interface into the current score's metadata
    function saveDefaults() {
        curScore.setMetaTag("spc_header", headerBox.text);
        curScore.setMetaTag("spc_octave_adjust", octaveAdjust.value.toString());
        curScore.setMetaTag("spc_swing", swingCheckBox.checked);
        curScore.setMetaTag("spc_section_labels", includeLabelsBox.checked);
        curScore.setMetaTag("spc_export_destination", exportFile.source);
        debugLog("Parameter settings saved to score");
    }

    //Loads export settings from score metadata, if those settings exist
    function loadDefaults() {
        headerBox.text = curScore.metaTag("spc_header");
        if (curScore.metaTag("spc_octave_adjust")) {
            octaveAdjust.value = parseInt(curScore.metaTag("spc_octave_adjust"));
        } else {
            octaveAdjust.value = -2;
        }
        swingCheckBox.checked = curScore.metaTag("spc_swing") === "true";
        includeLabelsBox.checked = curScore.metaTag("spc_section_labels") === "true";
        exportFile.source = curScore.metaTag("spc_export_destination");
        if(exportFile.source === "") {
            filePathLabel.text = "(no destination chosen)";
        } else {
            filePathLabel.text = exportFile.source;
        }
        debugLog("Loaded parameter settings from score.");
    }

    function processAnnotations(texts, staff) {
        var addSection = false;
        var sectionName = "";
        var prefix = "";
        var postfix = "";
        for (var i = 0; i < texts.length; i++) {
            //Make sure it's on the current staff
            if (texts[i].staff.is(staff)) {
                if(texts[i].text[0] == "@") {
                    prefix += texts[i].text.trim();
                }
                if (texts[i].text[0] == "-") {
                    prefix += processCommand(texts[i].text.trim());
                }
                if (texts[i].text[0] == "+") {
                    postfix += processCommand(texts[i].text.trim());
                }
                if(texts[i].text.indexOf("#SECTION") > -1) {
                    if(texts[i].text.substring(0, 8) === "#SECTION") {
                        addSection = true;
                        sectionName = texts[i].text.substring(9, texts[i].length);  
                    }
                }
            }
        }
        if(addSection && includeLabelsBox.checked) {
            prefix = "\n;" + sectionName + "\n";
        }
        var result = {};
        result.prefix = prefix;
        result.postfix = postfix;
        return result;
    }

    //Iterates through the score and generates an equivalent text file which can be
    //Provided to AddMusicK and compiled into SPC format
    function processScore(){
        saveDefaults();
        var cursor = curScore.newCursor();
        var startStaff = 0;
        var endStaff = curScore.nstaves - 1;
        var staffVoices = [];
        
        if (swingCheckBox.checked) {
            debugLog("Warning: Swing is turned on. Make sure that within each channel, in any beat where eighth notes occur, there are no notes of shorter" +
            " value. Otherwise, your channels may be out of sync. See the readme for more information.");
        }

        for (var staff = startStaff; staff <= endStaff; staff++) {
            var finalResult = "\n#" + staff.toString() + "\n";
            var prevNote = null;

            cursor.rewind(0);
            cursor.staffIdx = staff;

            while (cursor.segment) {
                var prefix = "";
                var postfix = "";
                //Process annotations if needed
                if (cursor.segment.annotations.length > 0) {
                    var result = processAnnotations(cursor.segment.annotations, cursor.element.staff);
                    prefix = result.prefix;
                    postfix = result.postfix;
                }
                finalResult += prefix;

                if (cursor.element && cursor.element.type === Element.CHORD) {
                    if (cursor.element.notes.length > 1) {
                        debugLog("Warning: Multiple notes found in chord at measure " 
                            + getMeasureNumber(cursor.measure) + ", channel " + staff
                            + ". All but one will be ignored.");
                    }
                    finalResult += getOctaveModifier(prevNote, cursor.element.notes[0]);
                    prevNote = cursor.element.notes[0];
                    if (prefix.indexOf("$dd") == 0 || prefix.indexOf("$DD") == 0) { //Special case for pitch bends
                        var stringified = stringifyElement(cursor.element, staff * 4);
                        finalResult += stringified[0] + "^" + stringified.substring(1, stringified.length);
                    } else {
                        finalResult += stringifyElement(cursor.element, staff * 4);
                    }
                }
                if (cursor.element && cursor.element.type === Element.REST) {
                    finalResult += stringifyElement(cursor.element, staff * 4);
                }
                finalResult += postfix;

                cursor.next();
            }
            staffVoices.push(finalResult);
        }

        var output = "#amk 2\n" + headerBox.text + "\n";
        for (var voice = 0; voice < staffVoices.length && voice < 8; voice++) {
            output += staffVoices[voice]
        }
        var numMeasures = countMeasures(curScore);
        //Honestly, the *8 is just for safety. If you're writing in a time signature 
        //larger than 32/4, then for the love of god
        //break it up into smaller segments
        //(The reason we can't just use numMeasures directly is because we could 
        //very reasonably be in 6/4 or some other time signature
        //Where the measure is longer than a single whole note
        for (var remaining = staffVoices.length; remaining < 8; remaining++) {
            output += "\n#" + remaining.toString() + "\nv255 [r1]" + numMeasures * 8 + "\n"
        }

        if (staffVoices.length > 8) {
            debugLog("Warning: More than 8 channels found in score. Only the first 8 will be converted.");
        }
        
        var currentDate = new Date();
        var time = currentDate.getHours() + ":" + currentDate.getMinutes() + ":" + currentDate.getSeconds();
        debugLog("Last export at " + time);

        return output;
    }

    onRun: {
        loadDefaults();
    }
}
