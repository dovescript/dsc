package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class NewOperatorNode extends ExpressionNode {

        public var base:ExpressionNode;

        public var arguments:Array;

        public function NewOperatorNode(base:ExpressionNode, arguments:Array) {
            super();
            this.base = base;
            this.arguments = arguments;
        }
    }
}