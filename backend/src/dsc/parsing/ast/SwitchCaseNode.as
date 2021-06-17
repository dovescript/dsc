package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class SwitchCaseNode extends Node {

        public var expression:ExpressionNode;

        public var directives:Array;

        public function SwitchCaseNode(expression:ExpressionNode, directives:Array) {
            super();
            this.expression = expression;
            this.directives = directives;
        }
    }
}