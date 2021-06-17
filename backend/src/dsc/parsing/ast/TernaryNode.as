package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class TernaryNode extends ExpressionNode {

        public var expression1:ExpressionNode;

        public var expression2:ExpressionNode;

        public var expression3:ExpressionNode;

        /**
         * Optional condition frame.
         */

        public function TernaryNode(expression1:ExpressionNode, expression2:ExpressionNode, expression3:ExpressionNode) {
            super();
            this.expression1 = expression1;
            this.expression2 = expression2;
            this.expression3 = expression3;
        }
    }
}