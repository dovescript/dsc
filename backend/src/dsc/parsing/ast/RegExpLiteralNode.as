package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class RegExpLiteralNode extends ExpressionNode {
        public var body:String;
        public var flags:String;

        public function RegExpLiteralNode(body:String, flags:String) {
            super();
            this.body = body;
            this.flags = flags;
        }
    }
}