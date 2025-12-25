import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import MuseScore 3.0

MuseScore {
    menuPath: "Plugins.Jianpu Labels"
    description: "Label selected notes with jianpu notation (for use with JianpuASCII font)"
    version: "1.0"
    pluginType: "dialog"
    width: 350
    height: 360

    // Reference octave: the octave where "do" has no dots
    property int referenceOctave: 4
    
    // Key signature detected from score (TPC of tonic)
    property int detectedKeyTpc: 14  // Default C
    property string detectedKeyName: "C"

    // Voice selection state
    property bool voice1Selected: true
    property bool voice2Selected: false
    property bool voice3Selected: false
    property bool voice4Selected: false

    // Convert TPC to note name
    function tpcToNoteName(tpc) {
        // TPC: Fb=6, Cb=7, Gb=8, Db=9, Ab=10, Eb=11, Bb=12, F=13, C=14, G=15, D=16, A=17, E=18, B=19, F#=20, C#=21, G#=22, D#=23, A#=24, E#=25, B#=26
        var names = ["Fbb", "Cbb", "Gbb", "Dbb", "Abb", "Ebb", "Bbb",
                     "Fb", "Cb", "Gb", "Db", "Ab", "Eb", "Bb",
                     "F", "C", "G", "D", "A", "E", "B",
                     "F#", "C#", "G#", "D#", "A#", "E#", "B#",
                     "F##", "C##", "G##", "D##", "A##", "E##", "B##"];
        var index = tpc + 1;  // TPC -1 = Fbb, so offset by 1
        if (index >= 0 && index < names.length) {
            return names[index];
        }
        return "?";
    }

    // Detect key signature from the score
    function detectKeySignature() {
        if (!curScore) return;

        var cursor = curScore.newCursor();
        cursor.rewind(Cursor.SCORE_START);
        var keySig = cursor.keySignature;
        detectedKeyTpc = 14 + keySig;  // C=14, keySig is -7 to +7
        detectedKeyName = tpcToNoteName(detectedKeyTpc);
    }

    onRun: {
        detectKeySignature();
        updateOctaveLabels();
    }

    // Update octave labels in the ComboBox model
    function updateOctaveLabels() {
        for (var i = 0; i < octaveModel.count; i++) {
            var item = octaveModel.get(i);
            octaveModel.setProperty(i, "text", detectedKeyName + item.octave + " - " + item.desc);
        }
    }

    // Map TPC difference to jianpu number (movable do, diatonic only)
    function intervalToJianpu(diff) {
        // TPC difference of 0 = unison (1), +1 = fifth, -1 = fourth, etc.
        var map = {
            0: "1",
            2: "2",
            4: "3",
            "-1": "4",
            1: "5",
            3: "6",
            5: "7"
        };
        var normalized = ((diff % 7) + 7) % 7;
        for (var key in map) {
            if (((parseInt(key) % 7) + 7) % 7 === normalized) {
                return map[key];
            }
        }
        return "?";
    }

    // Add octave markers using JianpuASCII font syntax
    // octave: 0 = reference octave, positive = higher, negative = lower
    // Higher octave: append ' (e.g., 1' 1'')
    // Lower octave: append , (e.g., 1, 1,,)
    function addOctaveMarkers(jianpu, octave) {
        if (octave === 0) return jianpu;
        
        var marker = octave > 0 ? "'" : ",";
        var count = Math.abs(octave);
        
        for (var i = 0; i < count; i++) {
            jianpu += marker;
        }
        return jianpu;
    }

    // Calculate octave relative to reference octave
    // Octave changes at "do" (the key root), not at C
    function getOctave(note, keyTpc) {
        var pitch = note.pitch;

        // TPC to pitch class: (tpc - 14) * 7, mod 12
        // C=14->0, D=16->2, E=18->4, F=13->5, G=15->7, A=17->9, B=19->11
        var keyPitchClass = (((keyTpc - 14) * 7) % 12 + 12) % 12;

        // Calculate the reference "do" pitch (key root in the selected octave)
        // MIDI pitch = pitchClass + 12 * (midiOctave + 1)
        var referenceDoPitch = keyPitchClass + 12 * (referenceOctave + 1);

        // Calculate octave relative to reference
        // Notes from referenceDoPitch to referenceDoPitch+11 are octave 0
        var diff = pitch - referenceDoPitch;
        return Math.floor(diff / 12);
    }

    // Get accidental by comparing TPC to determine chromatic alteration
    // TPC (Tonal Pitch Class): encodes note name + accidental
    // Circle of fifths positions for diatonic scale degrees relative to tonic:
    // do=0, re=2, mi=4, fa=-1, sol=1, la=3, ti=5
    function getAccidental(note, keyTpc) {
        var diff = note.tpc - keyTpc;
        
        // Diatonic TPC differences (no accidentals needed)
        var diatonicDiffs = [0, 1, 2, 3, 4, 5, -1];
        
        for (var i = 0; i < diatonicDiffs.length; i++) {
            if (diff === diatonicDiffs[i]) {
                return "";
            }
        }
        
        // Not diatonic - determine sharp or flat
        // Sharps are on the positive side of circle of fifths (> 5)
        // Flats are on the negative side (< -1)
        if (diff > 5) {
            return "#";
        } else {
            return "b";
        }
    }

    // Convert note duration to jianpu length notation using JianpuASCII font syntax
    // Eighth note: suffix / (e.g., 1/)
    // Sixteenth note: suffix // (e.g., 1//)
    // Half note: 1 -
    // Whole note: 1 - - -
    // Dotted: append . (e.g., 1.)
    function formatDuration(jianpu, duration, isRest) {
        var numerator = duration.numerator;
        var denominator = duration.denominator;

        // Detect dots from the fraction
        // Dotted notes have numerator 3, 7, 15... (2^n - 1) patterns
        var dots = 0;
        var baseDenom = denominator;

        if (numerator === 3) {
            dots = 1;
            baseDenom = denominator / 2;  // e.g., 3/8 -> base is 1/4
        } else if (numerator === 7) {
            dots = 2;
            baseDenom = denominator / 4;  // e.g., 7/16 -> base is 1/4
        } else if (numerator === 15) {
            dots = 3;
            baseDenom = denominator / 8;
        }

        // Calculate base note value (quarter = 1/4)
        var value = 1 / baseDenom;

        var result = jianpu;

        // Eighth note or shorter: add slashes
        if (value <= 1/8) {
            var slashes = 0;
            if (value <= 1/64) slashes = 4;
            else if (value <= 1/32) slashes = 3;
            else if (value <= 1/16) slashes = 2;
            else if (value <= 1/8) slashes = 1;
            
            for (var s = 0; s < slashes; s++) {
                result += "/";
            }
        }
        // Half note or longer
        else if (value >= 1/2) {
            if (isRest) {
                // Rests: repeat 0 for each quarter beat
                var quarters = Math.round(value / (1/4));
                result = "0";
                for (var q = 1; q < quarters; q++) {
                    result += " 0";
                }
            } else {
                // Notes: add dashes
                var dashes = Math.round(value / (1/4)) - 1;
                for (var d = 0; d < dashes; d++) {
                    result += " -";
                }
            }
        }

        // Add dots for dotted notes
        for (var i = 0; i < dots; i++) {
            result += ".";
        }

        return result;
    }

    function getKeySigAtTick(cursor) {
        return cursor.keySignature;
    }

    function keySigToTpc(keySig) {
         // keySig: -7 (Cb) to +7 (C#), 0 = C
         // TPC of the tonic: C=14, G=21, D=16, etc.
         return 14 + keySig;
     }
    
    // Check if a voice is selected
    function isVoiceSelected(voiceNumber) {
        // voiceNumber is 1-based (1, 2, 3, 4 for voices 1-4)
        if (voiceNumber === 1) return voice1Selected;
        if (voiceNumber === 2) return voice2Selected;
        if (voiceNumber === 3) return voice3Selected;
        if (voiceNumber === 4) return voice4Selected;
        return false;
    }

    // Check if text looks like jianpu notation
    function isJianpuLabel(text) {
        if (!text) return false;
        // Jianpu labels contain only: 0-7, #, b, /, -, ., ', ,, and spaces
        var jianpuPattern = /^[0-7#b\/\-\.\'\, ]+$/;
        return jianpuPattern.test(text);
    }

    // Remove existing jianpu labels from the selection
    function clearJianpuLabels(startTick, endTick, startStaff, endStaff) {
        var toRemove = [];
        
        // Iterate through all segments in range
        var segment = curScore.firstSegment();
        while (segment) {
            if (segment.tick >= startTick && segment.tick < endTick) {
                // Check all annotations on this segment
                var annotations = segment.annotations;
                for (var i = 0; i < annotations.length; i++) {
                    var ann = annotations[i];
                    // Check if annotation is on a selected staff
                    var annStaff = Math.floor(ann.track / 4);
                    if (annStaff >= startStaff && annStaff < endStaff) {
                        if (ann.type === Element.STAFF_TEXT && isJianpuLabel(ann.text)) {
                            toRemove.push(ann);
                        }
                    }
                }
            }
            segment = segment.next;
        }
        
        // Remove collected elements
        for (var j = 0; j < toRemove.length; j++) {
            removeElement(toRemove[j]);
        }
    }

    function applyJianpu() {
        var startTick, endTick;
        var startStaff, endStaff;
        var hasSelection = curScore.selection.startSegment;

        if (hasSelection) {
            startTick = curScore.selection.startSegment.tick;
            endTick = curScore.selection.endSegment ? curScore.selection.endSegment.tick : curScore.lastSegment.tick + 1;
            startStaff = curScore.selection.startStaff;
            endStaff = curScore.selection.endStaff;
        } else {
            // No selection - process entire score
            startTick = 0;
            endTick = curScore.lastSegment.tick + 1;
            startStaff = 0;
            endStaff = curScore.nstaves;
        }

        curScore.startCmd();

        // Clear existing jianpu labels in range
        clearJianpuLabels(startTick, endTick, startStaff, endStaff);

        var cursor = curScore.newCursor();

        // Iterate through selected staves and all 4 voices (reverse order so voice 1 appears on top)
        for (var staff = startStaff; staff < endStaff; staff++) {
            for (var voice = 3; voice >= 0; voice--) {
                var voiceNumber = voice + 1;  // Convert 0-based to 1-based

                // Skip voices that aren't selected
                if (!isVoiceSelected(voiceNumber)) {
                    continue;
                }

                // Set staff and voice, then rewind to start position
                // Note: rewind() resets staffIdx, so we must set it after rewinding
                cursor.rewind(Cursor.SCORE_START);
                cursor.staffIdx = staff;
                cursor.voice = voice;
                cursor.rewindToTick(startTick);

                while (cursor.segment && cursor.tick < endTick) {

                    var element = cursor.element;

                    if (element && element.type === Element.CHORD) {
                        var chord = element;
                        var notes = chord.notes;
                        var tick = cursor.tick;
                        var duration = chord.duration;

                        var keySig = getKeySigAtTick(cursor);
                        var keyTpc = keySigToTpc(keySig);

                        for (var i = 0; i < notes.length; i++) {
                            var note = notes[i];
                            var diff = note.tpc - keyTpc;
                            var accidental = getAccidental(note, keyTpc);
                            var jianpu = accidental + intervalToJianpu(diff);
                            var octave = getOctave(note, keyTpc);
                            jianpu = addOctaveMarkers(jianpu, octave);
                            var label = formatDuration(jianpu, duration, false);

                            var text = newElement(Element.STAFF_TEXT);
                            text.text = label;
                            text.fontFace = "Jianpu ASCII";
                            text.track = cursor.track;

                            cursor.add(text);
                        }
                    }
                    else if (element && element.type === Element.REST) {
                        var rest = element;
                        var duration = rest.duration;

                        // Skip full measure rests (duration equals time signature)
                        var timeSigNum = cursor.measure.timesigActual.numerator;
                        var timeSigDen = cursor.measure.timesigActual.denominator;
                        var restValue = duration.numerator / duration.denominator;
                        var measureValue = timeSigNum / timeSigDen;

                        if (restValue >= measureValue) {
                            cursor.next();
                            continue;
                        }

                        var label = formatDuration("0", duration, true);

                         var text = newElement(Element.STAFF_TEXT);
                         text.text = label;
                         text.fontFace = "Jianpu ASCII";
                         text.track = cursor.track;

                         cursor.add(text);
                    }
                    cursor.next();
                }
            }
        }

        curScore.endCmd();
        Qt.quit();
    }

    Rectangle {
        anchors.fill: parent
        color: palette.window

        SystemPalette { id: palette }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10

            Label {
                text: "Reference \"Do\" (1)"
                color: palette.windowText
                font.bold: true
            }
            
            Label {
                text: "Key: " + detectedKeyName + " major. Select which " + detectedKeyName + " should be \"do\" (1) with no octave dots."
                color: palette.windowText
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                font.pointSize: 9
            }

         RowLayout {
              Label { text: "Do (1) ="; color: palette.windowText }
              ComboBox {
                  id: octaveSelect
                  model: ListModel {
                      id: octaveModel
                      ListElement { text: ""; octave: 2; desc: "Bass, Low Male" }
                      ListElement { text: ""; octave: 3; desc: "Tenor, Baritone, Alto" }
                      ListElement { text: ""; octave: 4; desc: "Soprano, Mezzo (Standard)" }
                      ListElement { text: ""; octave: 5; desc: "High Soprano, Instruments" }
                      ListElement { text: ""; octave: 6; desc: "Very High, Piccolo" }
                  }
                  textRole: "text"
                  currentIndex: 2  // Default to octave 4
                  onCurrentIndexChanged: {
                      referenceOctave = octaveModel.get(currentIndex).octave;
                  }
              }
          }

          Label {
              text: "Select voices to label:"
              Layout.topMargin: 15
              color: palette.windowText
          }

          ColumnLayout {
              CheckBox {
                  id: voice1Check
                  text: "Voice 1"
                  checked: true
                  onCheckedChanged: voice1Selected = checked
                  contentItem: Text {
                      text: parent.text
                      color: palette.windowText
                      leftPadding: parent.indicator.width + parent.spacing
                      verticalAlignment: Text.AlignVCenter
                  }
              }
              
              CheckBox {
                  id: voice2Check
                  text: "Voice 2"
                  checked: false
                  onCheckedChanged: voice2Selected = checked
                  contentItem: Text {
                      text: parent.text
                      color: palette.windowText
                      leftPadding: parent.indicator.width + parent.spacing
                      verticalAlignment: Text.AlignVCenter
                  }
              }
              
              CheckBox {
                  id: voice3Check
                  text: "Voice 3"
                  checked: false
                  onCheckedChanged: voice3Selected = checked
                  contentItem: Text {
                      text: parent.text
                      color: palette.windowText
                      leftPadding: parent.indicator.width + parent.spacing
                      verticalAlignment: Text.AlignVCenter
                  }
              }
              
              CheckBox {
                  id: voice4Check
                  text: "Voice 4"
                  checked: false
                  onCheckedChanged: voice4Selected = checked
                  contentItem: Text {
                      text: parent.text
                      color: palette.windowText
                      leftPadding: parent.indicator.width + parent.spacing
                      verticalAlignment: Text.AlignVCenter
                  }
              }
          }

         RowLayout {
             Layout.alignment: Qt.AlignRight
             Layout.topMargin: 15
             
             Button {
                 text: "Apply"
                 onClicked: applyJianpu()
             }
             
             Button {
                 text: "Cancel"
                 onClicked: Qt.quit()
             }
         }
        }
    }
}
