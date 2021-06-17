package dsc.semantics.accessErrors {
    import dsc.semantics.Symbol;

    public final class IncompatibleArgumentType extends AccessError {
        private var _index:uint;
        private var _expected:Symbol;
        private var _got:Symbol;

        /**
         * @private
         */
        public function IncompatibleArgumentType(index:uint, expectedType:Symbol, gotType:Symbol) {
            _index = index;
            _expected = expectedType;
            _got = gotType;
        }

        override public function get argumentIndex():uint {
            return _index;
        }

        override public function get expectedArgumentType():Symbol {
            return _expected;
        }

        override public function get gotArgumentType():Symbol {
            return _got;
        }
    }
}