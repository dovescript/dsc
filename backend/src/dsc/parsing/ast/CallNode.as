package dsc.parsing.ast {

    import dsc.semantics.*;

    /**
     * Call operator node.
     * 
     * <p><i>Special semantics</i>: if <code>base</code> is a type with a static <code>Proxy::apply()</code> method,
     * then the result is a call to this method, overriding any default DoveScript type conversion.
     * The <code>Proxy::apply()</code> method is not supported to be a super method in <code>static</code> context.</p>
     */
    public final class CallNode extends ExpressionNode {

        public var base:ExpressionNode;

        public var arguments:Array;

        public function CallNode(base:ExpressionNode, arguments:Array) {
            super();
            this.base = base;
            this.arguments = arguments;
        }
    }
}