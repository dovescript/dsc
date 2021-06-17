package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class ExpressionStatementNode extends StatementNode {
        public var expression:ExpressionNode;

        public function ExpressionStatementNode(expression:ExpressionNode) {
            super();
            this.expression = expression;
        }
    }
}