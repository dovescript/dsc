package dsc.semantics {
    public final class PropertyProxy {
        public var getMethod:Symbol;
        public var includeMethod:Symbol;
        public var deleteMethod:Symbol;

        private var _keyType:Symbol;
        private var _valueType:Symbol;

        public function PropertyProxy(keyType:Symbol, valueType:Symbol) {
            _keyType = keyType;
            _valueType = valueType;
        }

        public function get keyType():Symbol { return _keyType }
        public function get valueType():Symbol { return _valueType }
    }
}