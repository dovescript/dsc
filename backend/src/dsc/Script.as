package dsc {
    import com.siteblade.util.CharArray;
    import flash.utils.ByteArray;

    /**
     * Represents a DoveScript program.
     */
    public final class Script {
        public const comments:Array = [];

        /**
         * @private
         */
        public const _lineStarts:Vector.<int> = new <int> [0, 0];

        private var _url:String;
        private var _text:CharArray;
        private var _problems:Array;

        /**
         * @private
         */
        public var _includesScripts:Array;

        private var _valid:Boolean = true;

        public function Script(url:String, text:*) {
            this._url = url;
            this._text = text is ByteArray || text is String ? new CharArray(text) : CharArray(text);
        }

        /**
         * Returns the source URL.
         */
        public function get url():String {
            return _url;
        }

        /**
         * Returns the source text of the Script.
         */
        public function get text():CharArray {
            return _text;
        }

        /**
         * Returns any problem within the Script.
         */
        public function get problems():Array {
            return _problems ? _problems.slice() : [];
        }

        /**
         * Indicates whether the script contains any error.
         */
        public function get isValid():Boolean {
            return _valid;
        }

        /**
         * Returns which scripts have been included with
         * the <code>include</code> directive.
         */
        public function get includesScripts():Array {
            return _includesScripts ? _includesScripts.slice() : [];
        }

        public function getLineStart(line:uint):uint {
            return line < _lineStarts.length ? _lineStarts[line] : _text.length;
        }

        public function getLineIndent(line:uint):uint {
            var ls1:uint = getLineStart(line),
                ls2:uint = getLineStart(line + 1),
                i:uint,
                s:String = text.slice(ls1, ls2, true);

            while (i != s.length && SourceCharacter.isWhiteSpace(s.charCodeAt(i))) ++i;

            return i;
        }

        public function collect(problem:Problem):Problem {
            _valid = !problem.isWarning ? false : _valid;
            return _problems ||= [], _problems.push(problem), problem;
        }

        public function sortProblemCollection():void {
            if (_problems) _problems.sort(function(a:Problem, b:Problem):int { return a.location.span.compareTo(b.location.span) });
        }
    }
}