package dsc.semantics.values {
	import dsc.semantics.*;

    /**
     * Descendants operation.
     *
     * <p>The <code>descendantsProxy</code> property may be <code>null</code> if Descendants is untyped.</p>
     */
    public final class Descendants extends Value {
        private var _object:Symbol;
        private var _descendantsProxy:Symbol;

		/**
		 * @private
		 */
		public function Descendants(object:Symbol, descendantsProxy:Symbol) {
            _object = object;
            _descendantsProxy = descendantsProxy;
            this.valueType = _descendantsProxy ? _descendantsProxy.methodSignature.result : undefined;
        }

        override public function get object():Symbol {
            return _object;
        }

        override public function get descendantsProxy():Symbol {
            return _descendantsProxy;
        }

        override public function toString():String {
            return '[object Descendants]';
        }
    }
}