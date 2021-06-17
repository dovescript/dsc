package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class RestParamNode extends ExpressionNode {

        public var name:String;

        public function RestParamNode(name:String) {
            super();
            this.name = name;
        }
    }
}