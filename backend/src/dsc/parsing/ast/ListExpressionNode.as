package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class ListExpressionNode extends ExpressionNode {

        public var expressions:Array;

        public function ListExpressionNode(expressions:Array) {
            super();
            this.expressions = expressions;
        }
    }
}