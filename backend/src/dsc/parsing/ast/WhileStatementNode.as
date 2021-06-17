package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class WhileStatementNode extends StatementNode {

        public var expression:ExpressionNode;

        public var substatement:StatementNode;

        public function WhileStatementNode(expression:ExpressionNode, substatement:StatementNode) {
            super();
            this.expression = expression;
            this.substatement = substatement;
        }

        override public function get isIterationStatement():Boolean {
            return true;
        }
    }
}