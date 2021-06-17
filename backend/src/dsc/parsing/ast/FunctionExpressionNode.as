package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class FunctionExpressionNode extends ExpressionNode {
        public var name:String;
        public var common:FunctionCommonNode;

        public function FunctionExpressionNode(name:String, common:FunctionCommonNode) {
            super();
            this.name = name;
            this.common = common;
        }
    }
}