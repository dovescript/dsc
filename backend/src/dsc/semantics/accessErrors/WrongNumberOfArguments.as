package dsc.semantics.accessErrors {
    import dsc.semantics.Symbol;

    public final class WrongNumberOfArguments extends AccessError {
        private var _expected:Number;

        public function WrongNumberOfArguments(expectedArgumentsNumber:Number) {
            _expected = expectedArgumentsNumber;
        }

        override public function get expectedArgumentsNumber():Number {
            return _expected;
        }
    }
}