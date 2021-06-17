package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class BooleanLiteralNode extends ExpressionNode {

        public var value:Boolean;

        public function BooleanLiteralNode(value:Boolean) {
            super();
            this.value = value;
        }
    }
}