package dsc.semantics.values {
	import dsc.semantics.*;

    /**
     * ReferenceValue.
     *
     * <p><i>Special case</i>: If <code>property</code> is a Observable.&lt;T&gt; variable and the value type of this ReferenceValue is T, then
     * this ReferenceValue should correspond to the Observable.value property.</p>
     */
    public final class ReferenceValue extends Value {
        private var _object:Symbol;

        private var _property:Symbol;

		/**
		 * @private
		 */
		public function ReferenceValue(object:Symbol, property:Symbol) {
            _object = object;
            _property = property;
        }

        override public function get object():Symbol {
            return _object;
        }

        override public function get property():Symbol {
            return _property;
        }

        override public function get isObservableVariable():Boolean {
            return property is VariableSlot && property.valueType.equalsOrInstantiationOf(ownerContext.statics.observableType);
        }

        override public function get readOnly():Boolean {
            return _property.readOnly;
        }

        override public function get writeOnly():Boolean {
            return _property.writeOnly;
        }

        override public function toString():String {
            return '[object ReferenceValue]';
        }
    }
}