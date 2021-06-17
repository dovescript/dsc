package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class NumericLiteralNode extends ExpressionNode {
        public var value:Number;

        public function NumericLiteralNode(value:Number) {
            super();
            this.value = value;
        }
    }
}