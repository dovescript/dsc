package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class CommentNode extends Node {
        public var content:String;
        public var multiline:Boolean;

        public function CommentNode(content:String, multiline:Boolean) {
            super();
            this.content = content;
            this.multiline = multiline;
        }
    }
}