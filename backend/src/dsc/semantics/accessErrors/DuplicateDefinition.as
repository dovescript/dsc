package dsc.semantics.accessErrors {
    import dsc.semantics.Symbol;

    public final class DuplicateDefinition extends AccessError {
        private var _name:Symbol;
        private var _definition:Symbol;

        /**
         * @private
         */
        public function DuplicateDefinition(name:Symbol, definition:Symbol) {
            _name = name;
            _definition = definition;
        }

        override public function get name():Symbol {
            return _name;
        }

        override public function get duplicateDefinition():Symbol {
            return _definition;
        }
    }
}