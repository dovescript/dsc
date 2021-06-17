package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class SpreadOperatorNode extends ExpressionNode {

        public var expression:ExpressionNode;

        public function SpreadOperatorNode(expression:ExpressionNode) {
            super();
            this.expression = expression;
        }
    }
}