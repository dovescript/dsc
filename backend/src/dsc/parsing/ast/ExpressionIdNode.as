package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class ExpressionIdNode extends QualifiedIdNode {
        public var key:ExpressionNode;

        public function ExpressionIdNode(qualifier:ExpressionNode, key:ExpressionNode) {
            super(qualifier);
            this.key = key;
        }
    }
}