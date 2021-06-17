package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class EnumDefinitionNode extends DefinitionNode {

        public var name:String;

        public var type:ExpressionNode;

        public var block:BlockNode;

        public function EnumDefinitionNode(name:String, type:ExpressionNode, block:BlockNode) {
            super();
            this.name = name;
            this.type = type;
            this.block = block;
        }
    }
}