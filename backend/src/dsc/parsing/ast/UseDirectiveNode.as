package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class UseDirectiveNode extends DirectiveNode {

        public var expression:ExpressionNode;

        public function UseDirectiveNode(expression:ExpressionNode) {
            super();
            this.expression = expression;
        }
    }
}