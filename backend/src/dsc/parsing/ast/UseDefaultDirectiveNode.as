package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class UseDefaultDirectiveNode extends DirectiveNode {

        public var expression:ExpressionNode;

        public function UseDefaultDirectiveNode(expression:ExpressionNode) {
            super();
            this.expression = expression;
        }
    }
}