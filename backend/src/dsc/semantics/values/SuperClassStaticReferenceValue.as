package dsc.semantics.values {
	import dsc.semantics.*;

    public final class SuperClassStaticReferenceValue extends Value {
        private var _subclass:Symbol;
        private var _superClass:Symbol;
        private var _property:Symbol;

		/**
		 * @private
		 */
		public function SuperClassStaticReferenceValue(subclass:Symbol, superClass:Symbol, property:Symbol) {
            _subclass = subclass;
            _superClass = superClass;
            _property = property;
        }

        override public function get subclass():Symbol {
            return _subclass;
        }

        override public function get superType():Symbol {
            return _superClass;
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
            return '[object SuperClassStaticReferenceValue]';
        }
    }
}