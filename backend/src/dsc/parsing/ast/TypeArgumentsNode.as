package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class TypeArgumentsNode extends ExpressionNode {

        public var base:ExpressionNode;

        public var arguments:Array;

        public function TypeArgumentsNode(base:ExpressionNode, arguments:Array) {
            super();
            this.base = base;
            this.arguments = arguments;
        }
    }
}