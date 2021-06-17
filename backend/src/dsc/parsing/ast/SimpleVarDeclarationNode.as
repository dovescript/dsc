package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class SimpleVarDeclarationNode extends Node {
        public var readOnly:Boolean;
        public var bindings:Array;

        public function SimpleVarDeclarationNode(readOnly:Boolean, bindings:Array) {
            super();
            this.readOnly = readOnly;
            this.bindings = bindings;
        }
    }
}