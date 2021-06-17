package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class FunctionDefinitionNode extends DefinitionNode {

        public var name:String;

        public var common:FunctionCommonNode;

        public function FunctionDefinitionNode(name:String, common:FunctionCommonNode) {
            super();
            this.name = name;
            this.common = common;
        }

        public function get flags():uint {
            return this.common.flags;
        }
    }
}