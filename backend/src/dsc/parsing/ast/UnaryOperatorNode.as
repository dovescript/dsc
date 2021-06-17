package dsc.parsing.ast {
    import dsc.semantics.*;

    /**
     * Unary operation.
     *
     * <p>Verification of <code>await</code> operation limits the operand to be a Promise instantiation and it may be given untyped (\* or Object). The <code>await</code> will return value of the type argument of the Promise type.</p>
     *
     * <p><i>Special semantics</i>: if the operator is + and <code>argument</code> is an Observable typed variable, the result is
     * the given single argument, not Observable.value.</p>
     */
    public final class UnaryOperatorNode extends ExpressionNode {
        public var type:Operator;
        public var argument:ExpressionNode;

        public function UnaryOperatorNode(type:Operator, argument:ExpressionNode) {
            super();
            this.type = type;
            this.argument = argument;
        }
    }
}