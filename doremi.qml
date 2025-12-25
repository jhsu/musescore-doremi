import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import MuseScore 3.0

MuseScore {
    menuPath: "Plugins.Jianpu Labels"
    description: "Label selected notes with jianpu notation (for use with JianpuASCII font)"
    version: "1.0"
    pluginType: "dialog"
    width: 300
    height: 150

    // Reference octave: MIDI pitch of "do" with no octave dots
    // Default 60 = C4 (middle C)
    property int referenceOctave: 4

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
    function getOctave(note) {
        // Each octave is 12 semitones
        var pitch = note.pitch;
        var noteOctave = Math.floor(pitch / 12) - 1; // MIDI octave (C4 = octave 4)
        return noteOctave - referenceOctave;
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
    function formatDuration(jianpu, duration, dots, isRest) {
        var numerator = duration.numerator;
        var denominator = duration.denominator;

        // Calculate base note value (quarter = 1/4)
        var value = numerator / denominator;

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
                var quarters = Math.floor(value / (1/4));
                result = "0";
                for (var q = 1; q < quarters; q++) {
                    result += " 0";
                }
            } else {
                // Notes: add dashes
                var dashes = Math.floor(value / (1/4)) - 1;
                for (var d = 0; d < dashes; d++) {
                    result += " -";
                }
            }
        }

        // Add dots for dotted notes
        if (dots > 0) {
            // For repeated rests (0 0 0 0), don't add dots
            if (!(isRest && value >= 1/2)) {
                for (var i = 0; i < dots; i++) {
                    result += ".";
                }
            }
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

    // Check if text looks like jianpu notation
    function isJianpuLabel(text) {
        if (!text) return false;
        // Jianpu labels contain only: 0-7, #, b, /, -, ., ', ,, and spaces
        var jianpuPattern = /^[0-7#b\/\-\.\'\, ]+$/;
        return jianpuPattern.test(text);
    }

    // Remove existing jianpu labels from the selection
    function clearJianpuLabels(startTick, endTick) {
        var toRemove = [];
        
        // Iterate through all segments in range
        var segment = curScore.firstSegment();
        while (segment) {
            if (segment.tick >= startTick && segment.tick < endTick) {
                // Check all annotations on this segment
                var annotations = segment.annotations;
                for (var i = 0; i < annotations.length; i++) {
                    var ann = annotations[i];
                    if (ann.type === Element.STAFF_TEXT && isJianpuLabel(ann.text)) {
                        toRemove.push(ann);
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
        var startSegment = curScore.selection.startSegment;
        var endTick = curScore.selection.endSegment ? curScore.selection.endSegment.tick : curScore.lastSegment.tick + 1;

        if (!startSegment) {
            console.log("No range selection");
            Qt.quit();
            return;
        }

        var startTick = startSegment.tick;

        curScore.startCmd();

        // Clear existing jianpu labels in selection
        clearJianpuLabels(startTick, endTick);

        var cursor = curScore.newCursor();
        cursor.rewind(Cursor.SELECTION_START);

        while (cursor.segment && cursor.tick < endTick) {
            var element = cursor.element;
            
            if (element && element.type === Element.CHORD) {
                var chord = element;
                var notes = chord.notes;
                var tick = cursor.tick;
                var duration = chord.duration;
                var dots = chord.dots;

                var keySig = getKeySigAtTick(cursor);
                var keyTpc = keySigToTpc(keySig);

                for (var i = 0; i < notes.length; i++) {
                    var note = notes[i];
                    var diff = note.tpc - keyTpc;
                    var accidental = getAccidental(note, keyTpc);
                    var jianpu = accidental + intervalToJianpu(diff);
                    var octave = getOctave(note);
                    jianpu = addOctaveMarkers(jianpu, octave);
                    var label = formatDuration(jianpu, duration, dots, false);

                    var text = newElement(Element.STAFF_TEXT);
                    text.text = label;
                    text.fontFace = "Jianpu ASCII";
                    text.placement = Placement.ABOVE;

                    cursor.add(text);
                }
            }
            else if (element && element.type === Element.REST) {
                var rest = element;
                var duration = rest.duration;
                var dots = rest.dots;
                var label = formatDuration("0", duration, dots, true);

                var text = newElement(Element.STAFF_TEXT);
                text.text = label;
                text.fontFace = "Jianpu ASCII";
                text.placement = Placement.ABOVE;

                cursor.add(text);
            }
            cursor.next();
        }

        curScore.endCmd();
        Qt.quit();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        Label {
            text: "Reference Octave (octave where 1-7 have no dots)"
        }

        RowLayout {
            Label { text: "Octave:" }
            ComboBox {
                id: octaveSelect
                model: ["2 (C2-B2)", "3 (C3-B3)", "4 (C4-B4)", "5 (C5-B5)", "6 (C6-B6)"]
                currentIndex: 2  // Default to octave 4
                onCurrentIndexChanged: {
                    referenceOctave = currentIndex + 2;
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            
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
