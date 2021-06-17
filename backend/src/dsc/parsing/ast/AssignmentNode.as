package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class AssignmentNode extends ExpressionNode {

        public var compound:Operator;

        /**
         * Assignment left-hand side.
         *
         * <p>This is additionaly allowed to be an ArrayLiteralNode or ObjectLiteralNode as a destructuring pattern.
         * In this case the assignment shall not be compound.</p>
         *
         * <p><i>Special semantics:</i> when <code>left</code> is an Observable.&lt;T&gt; variable, the assignment operator assigns T directly to the Observable.</p>
         */
        public var left:ExpressionNode;

        public var right:ExpressionNode;

        public function AssignmentNode(compound:Operator, left:ExpressionNode, right:ExpressionNode) {
            super();
            this.compound = compound;
            this.left = left;
            this.right = right;
        }
    }
}