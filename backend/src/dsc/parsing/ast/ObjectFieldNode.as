package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class ObjectFieldNode extends Node {

        /**
         * If the key appeared as a non-brackets-enclosed Identifier, this property
         * should be a SimpleIdNode and computed should be false.
         */
        public var key:ExpressionNode;

        public var computed:Boolean;

        /**
         * If this property is null, the ObjectFieldNode is a shorthand field.
         */
        public var value:ExpressionNode;

        public function ObjectFieldNode(computed:Boolean, key:ExpressionNode, value:ExpressionNode) {
            super();
            this.computed = computed;
            this.key = key;
            this.value = value;
        }
    }
}