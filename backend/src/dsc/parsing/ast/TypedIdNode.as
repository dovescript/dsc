package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class TypedIdNode extends Node {

        public var name:String;

        public var type:ExpressionNode;

        public function TypedIdNode(name:String, type:ExpressionNode) {
            super();
            this.name = name;
            this.type = type;
        }
    }
}