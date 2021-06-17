package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class WithStatementNode extends StatementNode {

        public var expression:ExpressionNode;

        public var substatement:StatementNode;

        public function WithStatementNode(expression:ExpressionNode, substatement:StatementNode) {
            super();
            this.expression = expression;
            this.substatement = substatement;
        }
    }
}