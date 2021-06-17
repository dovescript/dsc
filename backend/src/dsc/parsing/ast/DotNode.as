package dsc.parsing.ast {

    import dsc.semantics.*;

    /**
     * Dot operator node.
     *
     * <p><i>Special semantics:</i> if the operator resolves to an Observable.&lt;T&gt; variable, then the result is a T value.</p>
     */
    public final class DotNode extends ExpressionNode {

        public var base:ExpressionNode;

        public var id:QualifiedIdNode;

        public function DotNode(base:ExpressionNode, id:QualifiedIdNode) {
            super();
            this.base = base;
            this.id = id;
        }
    }
}