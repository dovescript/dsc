package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class ReturnNode extends StatementNode {
        public var expression:ExpressionNode;

        public function ReturnNode(expression:ExpressionNode) {
            super();
            this.expression = expression;
        }
    }
}