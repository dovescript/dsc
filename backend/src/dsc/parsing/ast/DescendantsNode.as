package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class DescendantsNode extends ExpressionNode {

        public var base:ExpressionNode;

        public var id:QualifiedIdNode;

        public function DescendantsNode(base:ExpressionNode, id:QualifiedIdNode) {
            super();
            this.base = base;
            this.id = id;
        }
    }
}