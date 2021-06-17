package dsc.parsing.ast {
    import dsc.semantics.*;

    /**
     * Type operation.
     *
     * <p>The <code>right</code> operand is allowed to be a runtime Class besides a compile-time type constant.</p>
     */
    public final class TypeOperatorNode extends ExpressionNode {
        public var operator:String;
        public var left:ExpressionNode;
        public var right:ExpressionNode;

        public function TypeOperatorNode(operator:String, left:ExpressionNode, right:ExpressionNode) {
            super();
            this.operator = operator;
            this.left = left;
            this.right = right;
        }
    }
}