package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class ReservedNamespaceNode extends ExpressionNode {
        public var type:String;

        public function ReservedNamespaceNode(type:String) {
            super();
            this.type = type;
        }
    }
}