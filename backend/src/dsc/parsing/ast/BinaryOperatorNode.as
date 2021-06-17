package dsc.parsing.ast {

    import dsc.semantics.*;

    /**
     * Binary operation.
     *
     * <p>If this is a + operation where one of the operands is a String object, then the result is a string concatenation.</p>
     */
    public final class BinaryOperatorNode extends ExpressionNode {

        public var type:Operator;

        public var left:ExpressionNode;

        public var right:ExpressionNode;

        public function BinaryOperatorNode(type:Operator, left:ExpressionNode, right:ExpressionNode) {
            super();
            this.type = type;
            this.left = left;
            this.right = right;
        }
    }
}