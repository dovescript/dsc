package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class ClassDefinitionNode extends DefinitionNode {

        public var name:String;

        public var extendsElement:ExpressionNode;

        public var implementsList:Array;

        public var block:BlockNode;

        public function ClassDefinitionNode(name:String, extendsElement:ExpressionNode, implementsList:Array, block:BlockNode) {
            super();
            this.name = name;
            this.extendsElement = extendsElement;
            this.implementsList = implementsList;
            this.block = block;
        }
    }
}