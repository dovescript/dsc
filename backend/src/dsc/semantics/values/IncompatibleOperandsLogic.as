package dsc.semantics.values {

	import dsc.semantics.*;

    public final class IncompatibleOperandsLogic extends Value {

		/**
		 * @private
		 */
		public function IncompatibleOperandsLogic(anyType:Symbol) {
            this.valueType = anyType;
        }

        override public function toString():String {
            return '[object IncompatibleOperandsLogic]';
        }
    }
}