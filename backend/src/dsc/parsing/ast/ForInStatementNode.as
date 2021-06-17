package dsc.parsing.ast {
    import dsc.semantics.*;

    /**
     * For..in statement.
     *
     * <p>The iteration is verified as valid if <code>right</code> is &#x2a; typed or if <code>right</code> is Generator typed or if <code>right</code> is Range typed or if type of <code>right</code> defines iteration proxies.</p>
     *
     * <p>If <code>left</code> is a reference, it is verified as valid if <code>right</code> converts implicitly to its static type.</p>
     */
    public final class ForInStatementNode extends StatementNode {
        public var isEach:Boolean;
        public var left:Node;
        public var right:ExpressionNode;
        public var substatement:StatementNode;

        public function ForInStatementNode(isEach:Boolean, left:Node, right:ExpressionNode, substatement:StatementNode) {
            super();
            this.isEach = isEach;
            this.left = left;
            this.right = right;
            this.substatement = substatement;
        }

        override public function get isIterationStatement():Boolean {
            return true;
        }
    }
}