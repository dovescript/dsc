package dsc.parsing.ast {

    import dsc.semantics.*;

    /**
     * Simple qualified identifier.
     *
     * <p><i>Special semantics:</i> if the expression resolves to an Observable.&lt;T&gt; variable, then the result is a T value.</p>
     */
    public final class SimpleIdNode extends QualifiedIdNode {

        public var name:String;

        public function SimpleIdNode(qualifier:ExpressionNode, name:String) {
            super(qualifier);
            this.name = name;
        }
    }
}