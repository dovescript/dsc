package dsc.parsing.ast {
    import dsc.*;
    import dsc.semantics.*;

    public class Node {
        public var span:Span;

        public function getPatternTypeExpression():ExpressionNode {
            if (this is TypedIdNode)
                return TypedIdNode(this).type;
            if (this is ObjectLiteralNode)
                return ObjectLiteralNode(this).type;
            if (this is ArrayLiteralNode)
                return ArrayLiteralNode(this).type;
            return null;
        }
    }
}