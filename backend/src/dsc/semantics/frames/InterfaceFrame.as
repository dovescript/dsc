package dsc.semantics.frames {
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.types.*;
    import dsc.semantics.values.*;

    public final class InterfaceFrame extends Frame {
        private var _symbol:Symbol;

        /**
         * @private
         */
        public function InterfaceFrame(symbol:Symbol) {
            _symbol = symbol;
        }

        override public function get symbol():Symbol {
            return _symbol;
        }

        override public function toString():String {
            return '[object InterfaceFrame]';
        }
    }
}