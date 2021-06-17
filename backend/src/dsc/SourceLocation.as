package dsc {
    public final class SourceLocation {
        private var _script:Script;
        private var _span:Span;

        public function SourceLocation(script:Script, span:Span) {
            _script = script;
            _span = span;
        }

        public function get script():Script {
            return _script;
        }

        public function get span():Span {
            return _span;
        }
    }
}