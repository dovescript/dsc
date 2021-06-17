package dsc.parsing.ast {
    import dsc.semantics.*;

    /**
     * Array literal. May be used to initialize *, Array, tuple or flag enumeration, be it nullable or not.
     * The returned value is of non-nullable type.
     */
    public final class ArrayLiteralNode extends ExpressionNode {
        public var elements:Array;
        public var type:ExpressionNode;

        public function ArrayLiteralNode(elements:Array, type:ExpressionNode) {
            super();
            this.elements = elements;
            this.type = type;
        }
    }
}