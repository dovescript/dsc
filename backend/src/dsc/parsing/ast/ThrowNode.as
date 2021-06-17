package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class ThrowNode extends StatementNode {
        public var expression:ExpressionNode;

        public function ThrowNode(expression:ExpressionNode) {
            super();
            this.expression = expression;
        }
    }
}