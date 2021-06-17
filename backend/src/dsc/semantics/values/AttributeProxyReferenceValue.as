package dsc.semantics.values {
	import dsc.semantics.*;

    public final class AttributeProxyReferenceValue extends Value {
        private var _object:Symbol;
        private var _attributeProxy:PropertyProxy;

		/**
		 * @private
		 */
		public function AttributeProxyReferenceValue(object:Symbol, attributeProxy:PropertyProxy) {
            _object = object;
            _attributeProxy = attributeProxy;
        }

        override public function get object():Symbol {
            return _object;
        }

        override public function get attributeProxy():PropertyProxy {
            return _attributeProxy;
        }

        override public function get readOnly():Boolean {
            return !_attributeProxy.includeMethod;
        }

        override public function get writeOnly():Boolean {
            return !_attributeProxy.getMethod;
        }

        override public function get isDeletable():Boolean {
            return !!_attributeProxy.deleteMethod;
        }

        override public function toString():String {
            return '[object AttributeProxyReferenceValue]';
        }
    }
}