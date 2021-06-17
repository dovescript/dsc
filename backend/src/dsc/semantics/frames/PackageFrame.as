package dsc.semantics.frames {
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.types.*;
    import dsc.semantics.values.*;

    public final class PackageFrame extends Frame {
        private var _symbol:Symbol;

        /**
         * @private
         */
        public function PackageFrame(symbol:Symbol) {
            _symbol = symbol;
            internalNs = symbol.internalNs;
        }

        override public function get symbol():Symbol {
            return _symbol;
        }

        override public function toString():String {
            return '[object PackageFrame]';
        }
    }
}