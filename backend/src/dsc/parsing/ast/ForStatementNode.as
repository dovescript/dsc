package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class ForStatementNode extends StatementNode {

        public var expression1:Node;

        public var expression2:ExpressionNode;

        public var expression3:ExpressionNode;

        public var substatement:StatementNode;

        public function ForStatementNode(expression1:Node, expression2:ExpressionNode, expression3:ExpressionNode, substatement:StatementNode) {
            super();
            this.expression1 = expression1;
            this.expression2 = expression2;
            this.expression3 = expression3;
        }

        override public function get isIterationStatement():Boolean {
            return true;
        }
    }
}