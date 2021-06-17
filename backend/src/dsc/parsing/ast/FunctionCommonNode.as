package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class FunctionCommonNode extends Node {

        public var params:Array;

        public var optParams:Array;

        public var rest:RestParamNode;

        public var result:ExpressionNode;

        public var body:Node;

        public var flags:uint = 0;

        public function FunctionCommonNode
            ( params:Array, optParams:Array, rest:RestParamNode, result:ExpressionNode, body:Node)
        {
            super();
            this.params = params;
            this.optParams = optParams;
            this.rest = rest;
            this.result = result;
            this.body = body;
        }
    }
}