package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class EmbedExpressionNode extends ExpressionNode {
        public var src:String;

        public function EmbedExpressionNode(src:String) {
            super();
            this.src = src;
        }
    }
}