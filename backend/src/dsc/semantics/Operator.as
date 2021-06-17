package dsc.semantics {
    import flash.utils.Dictionary;

    public final class Operator {
        static public const TYPEOF:Operator = new Operator("typeof");
        static public const IN:Operator = new Operator("in");
        static public const INCREMENT:Operator = new Operator("++");
        static public const DECREMENT:Operator = new Operator("--");
        static public const POST_INCREMENT:Operator = new Operator("++");
        static public const POST_DECREMENT:Operator = new Operator("--");
        static public const DELETE:Operator = new Operator("delete");
        static public const VOID:Operator = new Operator("void");
        static public const YIELD:Operator = new Operator("yield");
        static public const AWAIT:Operator = new Operator("await");
        static public const AS_IS:Operator = new Operator("as is");
        static public const POSITIVE:Operator = new Operator("+");
        static public const NEGATE:Operator = new Operator("-");
        static public const BITWISE_NOT:Operator = new Operator("~");
        static public const LOGICAL_NOT:Operator = new Operator("!");
        static public const ADD:Operator = new Operator("+");
        static public const SUBTRACT:Operator = new Operator("-");
        static public const MULTIPLY:Operator = new Operator("*");
        static public const DIVIDE:Operator = new Operator("/");
        static public const REMAINDER:Operator = new Operator("%");
        static public const BITWISE_AND:Operator = new Operator("&");
        static public const BITWISE_XOR:Operator = new Operator("^");
        static public const BITWISE_OR:Operator = new Operator("|");
        static public const LEFT_SHIFT:Operator = new Operator("<<");
        static public const RIGHT_SHIFT:Operator = new Operator(">>");
        static public const UNSIGNED_RIGHT_SHIFT:Operator = new Operator(">>>");
        static public const LT:Operator = new Operator("<");
        static public const GT:Operator = new Operator(">");
        static public const LE:Operator = new Operator("<=");
        static public const GE:Operator = new Operator(">=");
        static public const EQUALS:Operator = new Operator("==");
        static public const STRICT_EQUALS:Operator = new Operator("===");
        static public const NOT_EQUALS:Operator = new Operator("!=");
        static public const STRICT_NOT_EQUALS:Operator = new Operator("!==");
        static public const LOGICAL_AND:Operator = new Operator("&&");
        static public const LOGICAL_XOR:Operator = new Operator("^^");
        static public const LOGICAL_OR:Operator = new Operator("||");

        static private const _unary:Dictionary = new Dictionary;
        _unary[INCREMENT] = true;
        _unary[DECREMENT] = true;
        _unary[POST_INCREMENT] = true;
        _unary[POST_DECREMENT] = true;
        _unary[VOID] = true;
        _unary[AWAIT] = true;
        _unary[AS_IS] = true;
        _unary[POSITIVE] = true;
        _unary[BITWISE_NOT] = true;
        _unary[NEGATE] = true;
        _unary[DELETE] = true;
        _unary[LOGICAL_NOT] = true;
        _unary[TYPEOF] = true;
        _unary[YIELD] = true;

        static private const _resultsBoolean:Dictionary = new Dictionary;
        _resultsBoolean[EQUALS] = true;
        _resultsBoolean[NOT_EQUALS] = true;
        _resultsBoolean[STRICT_EQUALS] = true;
        _resultsBoolean[STRICT_NOT_EQUALS] = true;
        _resultsBoolean[LT] = true;
        _resultsBoolean[GT] = true;
        _resultsBoolean[LE] = true;
        _resultsBoolean[GE] = true;
        _resultsBoolean[DELETE] = true;
        _resultsBoolean[LOGICAL_NOT] = true;
        _resultsBoolean[IN] = true;

        private var _name:String;

        /**
         * @private
         */
        public function Operator(name:String) {
            _name = name;
        }

        static public function fromProxyName(context:Context, name:Symbol):Operator {
            switch (name) {
                case (context.statics.proxyNegate): return NEGATE;

                case (context.statics.proxyEquals): return STRICT_EQUALS;

                case (context.statics.proxyNotEquals): return STRICT_NOT_EQUALS;

                case (context.statics.proxyLessThan): return LT;

                case (context.statics.proxyGreaterThan): return GT;

                case (context.statics.proxyLessThanOrEquals): return LE;

                case (context.statics.proxyGreaterThanOrEquals): return GE;

                case (context.statics.proxyAdd): return ADD;

                case (context.statics.proxySubtract): return SUBTRACT;

                case (context.statics.proxyMultiply): return MULTIPLY;

                case (context.statics.proxyDivide): return DIVIDE;

                case (context.statics.proxyRemainder): return REMAINDER;

                default: return null;
            }
        }

        public function get isUnary():Boolean {
            return !!_unary[this];
        }

        public function get resultsBoolean():Boolean {
            return !!_resultsBoolean[this];
        }

        public function toString():String {
            return _name;
        }
    }
}