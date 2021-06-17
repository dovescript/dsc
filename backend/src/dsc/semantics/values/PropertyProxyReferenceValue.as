package dsc.semantics.values {
	import dsc.semantics.*;

    public final class PropertyProxyReferenceValue extends Value {
        private var _object:Symbol;
        private var _propertyProxy:PropertyProxy;

		/**
		 * @private
		 */
		public function PropertyProxyReferenceValue(object:Symbol, propertyProxy:PropertyProxy) {
            _object = object;
            _propertyProxy = propertyProxy;
        }

        override public function get object():Symbol {
            return _object;
        }

        override public function get propertyProxy():PropertyProxy {
            return _propertyProxy;
        }

        override public function get readOnly():Boolean {
            return !_propertyProxy.includeMethod;
        }

        override public function get writeOnly():Boolean {
            return !_propertyProxy.getMethod;
        }

        override public function get isDeletable():Boolean {
            return !!_propertyProxy.deleteMethod;
        }

        override public function toString():String {
            return '[object PropertyProxyReferenceValue]';
        }
    }
}