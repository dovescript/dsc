package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class VarBindingNode extends Node {

        public var pattern:Node;

        public var initialiser:ExpressionNode;

        public function VarBindingNode(pattern:Node, initialiser:ExpressionNode) {
            super();
            this.pattern = pattern;
            this.initialiser = initialiser;
        }
    }
}