package dsc.semantics {

    public final class Property {

        private var _key:Symbol;

        private var _value:Symbol;

        public function Property(key:Symbol, value:Symbol) {
            this._key = key;
            this._value = value;
        }

        public function get key():Symbol {
            return this._key;
        }

        public function get value():Symbol {
            return this._value;
        }
    }
}