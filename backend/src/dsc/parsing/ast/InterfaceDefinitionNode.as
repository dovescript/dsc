package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class InterfaceDefinitionNode extends DefinitionNode {

        public var name:String;

        public var extendsList:Array;

        public var block:BlockNode;

        public function InterfaceDefinitionNode(name:String, extendsList:Array, block:BlockNode) {
            super();
            this.name = name;
            this.extendsList = extendsList;
            this.block = block;
        }
    }
}