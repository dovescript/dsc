package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class BracketsNode extends ExpressionNode {

        public var base:ExpressionNode;

        public var key:ExpressionNode;

        public function BracketsNode(base:ExpressionNode, key:ExpressionNode) {
            super();
            this.base = base;
            this.key = key;
        }
    }
}