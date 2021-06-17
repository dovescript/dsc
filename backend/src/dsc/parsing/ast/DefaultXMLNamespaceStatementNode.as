package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class DefaultXMLNamespaceStatementNode extends StatementNode {
        public var expression:ExpressionNode;

        public function DefaultXMLNamespaceStatementNode(expression:ExpressionNode) {
            super();
            this.expression = expression;
        }
    }
}