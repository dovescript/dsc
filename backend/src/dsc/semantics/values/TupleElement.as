package dsc.semantics.values {
	import dsc.semantics.*;

    public final class TupleElement extends Value {
        private var _object:Symbol;
        private var _index:Number;

		/**
		 * @private
		 */
		public function TupleElement(object:Symbol, index:Number) {
            _object = object;
            _index = index;
            valueType = object.valueType.escapeType().tupleElements[index];
        }

        override public function get object():Symbol {
            return _object;
        }

        override public function get index():Number {
            return _index;
        }

        override public function toString():String {
            return '[object TupleElement]';
        }
    }
}