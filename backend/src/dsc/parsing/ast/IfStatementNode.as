package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class IfStatementNode extends StatementNode {

        public var expression:ExpressionNode;

        public var consequent:StatementNode;

        public var alternative:StatementNode;

        public function IfStatementNode(expression:ExpressionNode, consequent:StatementNode, alternative:StatementNode) {
            super();
            this.expression = expression;
            this.consequent = consequent;
            this.alternative = alternative;
        }
    }
}