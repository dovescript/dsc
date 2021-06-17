package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class AttributeIdNode extends QualifiedIdNode {

        public var id:QualifiedIdNode;

        public function AttributeIdNode(id:QualifiedIdNode) {
            super(null);
            this.id = id;
        }
    }
}