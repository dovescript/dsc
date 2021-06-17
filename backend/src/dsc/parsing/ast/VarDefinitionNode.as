package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class VarDefinitionNode extends DefinitionNode {
        public var readOnly:Boolean;
        public var bindings:Array;

        public function VarDefinitionNode(readOnly:Boolean, bindings:Array) {
            super();
            this.readOnly = readOnly;
            this.bindings = bindings;
        }
    }
}