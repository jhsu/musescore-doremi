import QtQuick 2.9
import MuseScore 3.0

MuseScore {
    menuPath: "Plugins.Solfege Labels"
    description: "Label selected notes with solfege syllables"
    version: "1.0"

    // Map TPC difference to solfege (movable do, diatonic only)
    function intervalToSolfege(diff) {
        // TPC difference of 0 = unison (do), +1 = fifth, -1 = fourth, etc.
        // We convert TPC circle-of-fifths to scale degrees
        var map = {
            0: "do",
            2: "re",
            4: "mi",
            "-1": "fa",
            1: "sol",
            3: "la",
            5: "ti"
        };
        var normalized = ((diff % 7) + 7) % 7; // normalize to 0-6
        // Convert from fifths to scale order
        var fifthsToDegree = [0, 2, 4, -1, 1, 3, 5];
        for (var key in map) {
            if (((parseInt(key) % 7) + 7) % 7 === normalized) {
                return map[key];
            }
        }
        return "?";
    }

    function getKeySigAtTick(tick) {
        var cursor = curScore.newCursor();
        cursor.rewind(Cursor.SCORE_START);
        var keySig = 0; // C major default
        
        while (cursor.segment && cursor.tick <= tick) {
            var seg = cursor.segment;
            var keySigEl = seg.elementAt(0); // check for key sig
            if (seg.elementAt(0) && seg.elementAt(0).type === Element.KEYSIG) {
                keySig = seg.elementAt(0).key;
            }
            cursor.next();
        }
        return keySig; // returns -7 to +7 (flats to sharps)
    }

    function keySigToTpc(keySig) {
        // keySig: -7 (Cb) to +7 (C#), 0 = C
        // TPC of the tonic: C=14, G=21, D=16, etc.
        return 14 + keySig; // This gives tonic TPC
    }

    onRun: {
        if (!curScore.selection.elements.length) {
            console.log("No selection");
            Qt.quit();
            return;
        }

        curScore.startCmd();

        var selection = curScore.selection.elements;
        for (var i = 0; i < selection.length; i++) {
            var el = selection[i];
            if (el.type !== Element.NOTE) continue;

            var note = el;
            var chord = note.parent;
            var segment = chord.parent;
            var tick = segment.tick;

            var keySig = getKeySigAtTick(tick);
            var keyTpc = keySigToTpc(keySig);
            var diff = note.tpc - keyTpc;
            var solfege = intervalToSolfege(diff);

            var text = newElement(Element.STAFF_TEXT);
            text.text = solfege;
            text.placement = Placement.BELOW;

            var cursor = curScore.newCursor();
            cursor.rewindToTick(tick);
            cursor.add(text);
        }

        curScore.endCmd();
        Qt.quit();
    }
}
