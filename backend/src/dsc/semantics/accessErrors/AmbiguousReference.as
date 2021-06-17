package dsc.semantics.accessErrors {
    import dsc.semantics.Symbol;

    public final class AmbiguousReference extends AccessError {
        private var _name:String;
        private var _betweenPackages:Array;

        /**
         * @private
         */
        public function AmbiguousReference(name:String, betweenPackages:Array = null) {
            _name = name;
            _betweenPackages = betweenPackages;
        }

        override public function get localName():String {
            return _name;
        }

        override public function get betweenPackages():Array {
            return betweenPackages;
        }
    }
}