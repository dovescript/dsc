package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class NullableTypeNode extends ExpressionNode {

        public var type:ExpressionNode;

        public function NullableTypeNode(type:ExpressionNode) {
            super();
            this.type = type;
        }
    }
}