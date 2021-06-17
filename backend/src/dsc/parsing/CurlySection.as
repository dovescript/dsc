package dsc.parsing {

    import dsc.*;

    /**
     * @private
     */
    internal final class CurlySection {

        public var wordId:String;

        public var span:Span;

        public function CurlySection(wordId:String, span:Span) {
            this.wordId = wordId, this.span = span;
        }
    }
}