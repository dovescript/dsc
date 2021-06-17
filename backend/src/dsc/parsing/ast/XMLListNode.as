package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class XMLListNode extends ExpressionNode {

        public var nodes:Array;

        public function XMLListNode(nodes:Array) {
            super();
            this.nodes = nodes;
        }
    }
}