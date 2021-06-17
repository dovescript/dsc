package dsc.parsing.ast {
    import dsc.*;
    import dsc.semantics.*;

    public final class ObjectDefinitionNode extends DefinitionNode {
        public var name:String;

        public var block:BlockNode;

        public function ObjectDefinitionNode(name:String, block:BlockNode) {
            super();
            this.name = name;
            this.block = block;
        }
    }
}