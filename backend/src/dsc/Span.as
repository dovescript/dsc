package dsc {
    public final class Span {
        private var _start:uint;
        private var _end:uint;
        private var _firstLine:uint;
        private var _lastLine:uint;

        public static function point(line:uint, index:uint):Span {
            return new Span(line, index, line, index);
        }

        public static function inline(line:uint, start:uint, end:uint):Span {
            return new Span(line, start, line, end);
        }

        public function Span(firstLine:uint, start:uint, lastLine:uint, end:uint) {
            _start = start;
            _end = end;
            _firstLine = firstLine;
            _lastLine = lastLine;
        }

        public function get start():uint { return _start }
        public function get end():uint { return _end }
        public function get firstLine():uint { return _firstLine }
        public function get lastLine():uint { return _lastLine }

        public function compareTo(span:Span):int {
            return _firstLine < span._firstLine ? -1 :
                _start < span._start ? -1 :
                _start > span._start ? 1 : 0;
        }
    }
}