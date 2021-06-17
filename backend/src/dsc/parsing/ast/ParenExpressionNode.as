package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class ParenExpressionNode extends ExpressionNode {

        public var expression:ExpressionNode;

        public function ParenExpressionNode(expression:ExpressionNode) {
            super();
            this.expression = expression;
        }
    }
}