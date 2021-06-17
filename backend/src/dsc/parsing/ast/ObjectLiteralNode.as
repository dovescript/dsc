package dsc.parsing.ast {
    import dsc.semantics.*;

    /**
     * Object literal. May be used to initialize Object, Dictionary and classes with the configuration <code>dynamicInit=true</code>.
     */
    public final class ObjectLiteralNode extends ExpressionNode {
        /**
         * Collection of ObjectFieldNode and SpreadOperatorNode.
         */
        public var fields:Array;

        public var type:ExpressionNode;

        public function ObjectLiteralNode(fields:Array, type:ExpressionNode) {
            super();
            this.fields = fields;
            this.type = type;
        }
    }
}