package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class DoStatementNode extends StatementNode {

        public var substatement:StatementNode;

        public var expression:ExpressionNode;

        public function DoStatementNode(substatement:StatementNode, expression:ExpressionNode) {
            super();
            this.substatement = substatement;
            this.expression = expression;
        }

        override public function get isIterationStatement():Boolean {
            return true;
        }
    }
}