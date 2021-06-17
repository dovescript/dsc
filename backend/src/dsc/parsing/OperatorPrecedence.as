package dsc.parsing {

    import flash.utils.Dictionary;

    public final class OperatorPrecedence {

        static private const _byValue:Dictionary = new Dictionary;

        static public const POSTFIX_OPERATOR:OperatorPrecedence = new OperatorPrecedence(15);

        static public const UNARY_OPERATOR:OperatorPrecedence = new OperatorPrecedence(14);

        static public const MULTIPLICATIVE_OPERATOR:OperatorPrecedence = new OperatorPrecedence(13);

        static public const ADDITIVE_OPERATOR:OperatorPrecedence = new OperatorPrecedence(12);

        static public const SHIFT_OPERATOR:OperatorPrecedence = new OperatorPrecedence(11);

        static public const RELATIONAL_OPERATOR:OperatorPrecedence = new OperatorPrecedence(10);

        static public const EQUALITY_OPERATOR:OperatorPrecedence = new OperatorPrecedence(9);

        static public const BIT_AND_OPERATOR:OperatorPrecedence = new OperatorPrecedence(8);

        static public const BIT_XOR_OPERATOR:OperatorPrecedence = new OperatorPrecedence(7);

        static public const BIT_OR_OPERATOR:OperatorPrecedence = new OperatorPrecedence(6);

        static public const LOGICAL_AND_OPERATOR:OperatorPrecedence = new OperatorPrecedence(5);

        static public const LOGICAL_OR_OPERATOR:OperatorPrecedence = new OperatorPrecedence(4);

        static public const TERNARY_OPERATOR:OperatorPrecedence = new OperatorPrecedence(3);

        static public const ASSIGNMENT_OPERATOR:OperatorPrecedence = new OperatorPrecedence(2);

        static public const LIST_OPERATOR:OperatorPrecedence = new OperatorPrecedence(1);

        private var _value:uint;

        static public function valueOf(value:uint):OperatorPrecedence {
            return _byValue[value];
        }

        public function OperatorPrecedence(value:uint) {
            this._value = value;
            _byValue[value] = this;
        }

        public function valueOf():uint {
            return this._value;
        }
    }
}