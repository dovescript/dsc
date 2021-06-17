package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class CatchNode extends Node {

        public var pattern:Node;

        public var block:BlockNode;

        public function CatchNode(pattern:Node, block:BlockNode) {
            super();
            this.pattern = pattern;
            this.block = block;
        }
    }
}