package dsc.parsing {

    import dsc.*;

    public final class TokenState {

        public var type:Token = Token.EOF;

        public var string:String;

        public var number:Number;

        public var boolean:Boolean;

        public var regExpFlags:String;

        public var start:uint;

        public var end:uint;

        public var firstLine:uint = 1;

        public var lastLine:uint = 1;

        public function get span():Span { return new Span(firstLine, start, lastLine, end) }

        public function copyTo(state:TokenState):void {
            state.type = type;
            state.string = string;
            state.number = number;
            state.boolean = boolean;
            state.regExpFlags = regExpFlags;
            state.start = start;
            state.end = end;
            state.firstLine = firstLine;
            state.lastLine = lastLine;
        }
    }
}