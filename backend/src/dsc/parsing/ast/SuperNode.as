package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class SuperNode extends ExpressionNode {

        public var arguments:Array;

        public function SuperNode(arguments:Array) {
            super();
            this.arguments = arguments;
        }
    }
}