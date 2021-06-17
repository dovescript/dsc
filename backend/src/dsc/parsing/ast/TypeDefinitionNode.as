package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class TypeDefinitionNode extends DefinitionNode {

        public var name:String;

        public var type:ExpressionNode;

        public function TypeDefinitionNode(name:String, type:ExpressionNode) {
            super();
            this.name = name;
            this.type = type;
        }
    }
}