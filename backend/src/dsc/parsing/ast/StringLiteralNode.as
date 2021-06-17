package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class StringLiteralNode extends ExpressionNode {
        public var value:String;

        public function StringLiteralNode(value:String) {
            super();
            this.value = value;
        }
    }
}