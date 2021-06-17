package dsc.parsing.ast {
    import dsc.semantics.*;

    public class QualifiedIdNode extends ExpressionNode {
        public var qualifier:ExpressionNode;

        public function QualifiedIdNode(qualifier:ExpressionNode) {
            this.qualifier = qualifier;
        }
    }
}