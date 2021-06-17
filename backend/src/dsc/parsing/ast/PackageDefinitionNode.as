package dsc.parsing.ast {
    import dsc.*;
    import dsc.semantics.*;

    public final class PackageDefinitionNode extends Node {
        public var id:String;

        public var block:BlockNode;

        public var script:Script;

        public function PackageDefinitionNode(id:String, block:BlockNode) {
            super();
            this.id = id;
            this.block = block;
        }
    }
}