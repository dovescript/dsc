package dsc.semantics.values {
	import dsc.semantics.*;

    /**
     * Represents a runtime reference to a property.
     */
    public final class DynamicReferenceValue extends Value {
        private var _object:Symbol;

		/**
		 * @private
		 */
		public function DynamicReferenceValue(object:Symbol) {
            _object = object;
        }

        override public function get object():Symbol {
            return _object;
        }

        override public function get readOnly():Boolean {
            return false;
        }

        override public function get writeOnly():Boolean {
            return false;
        }

        override public function get isDeletable():Boolean {
            return true;
        }

        override public function toString():String {
            return '[object DynamicReferenceValue]';
        }
    }
}