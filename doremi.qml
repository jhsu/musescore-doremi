import QtQuick 2.9
import MuseScore 3.0

MuseScore {
    menuPath: "Plugins.Jianpu Labels"
    description: "Label selected notes with jianpu notation (for use with JianpuASCII font)"
    version: "1.0"

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
    // octave: 0 = middle octave (C4-B4), positive = higher, negative = lower
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

    // Calculate octave relative to middle octave (C4 = middle C = octave 0)
    function getOctave(note) {
        // MIDI pitch 60 = C4 (middle C)
        // Each octave is 12 semitones
        var pitch = note.pitch;
        var octave = Math.floor(pitch / 12) - 5; // C4 (pitch 60) -> octave 0
        return octave;
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

    function getKeySigAtTick(tick) {
        var cursor = curScore.newCursor();
        cursor.rewind(Cursor.SCORE_START);
        var keySig = 0; // C major default
        
        while (cursor.segment && cursor.tick <= tick) {
            var seg = cursor.segment;
            if (seg.elementAt(0) && seg.elementAt(0).type === Element.KEYSIG) {
                keySig = seg.elementAt(0).key;
            }
            cursor.next();
        }
        return keySig;
    }

    function keySigToTpc(keySig) {
        // keySig: -7 (Cb) to +7 (C#), 0 = C
        // TPC of the tonic: C=14, G=21, D=16, etc.
        return 14 + keySig;
    }

    onRun: {
        var startSegment = curScore.selection.startSegment;
        var endTick = curScore.selection.endSegment ? curScore.selection.endSegment.tick : curScore.lastSegment.tick + 1;

        if (!startSegment) {
            console.log("No range selection");
            Qt.quit();
            return;
        }

        curScore.startCmd();

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

                var keySig = getKeySigAtTick(tick);
                var keyTpc = keySigToTpc(keySig);

                for (var i = 0; i < notes.length; i++) {
                    var note = notes[i];
                    var diff = note.tpc - keyTpc;
                    var jianpu = intervalToJianpu(diff);
                    var octave = getOctave(note);
                    jianpu = addOctaveMarkers(jianpu, octave);
                    var label = formatDuration(jianpu, duration, dots, false);

                    var text = newElement(Element.STAFF_TEXT);
                    text.text = label;
                    text.placement = Placement.BELOW;

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
                text.placement = Placement.BELOW;

                cursor.add(text);
            }
            cursor.next();
        }

        curScore.endCmd();
        Qt.quit();
    }
}
