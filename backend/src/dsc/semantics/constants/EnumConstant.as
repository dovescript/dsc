package dsc.semantics.constants {
    import dsc.semantics.*;
	import dsc.util.AnyRangeNumber;

    public final class EnumConstant extends Constant {
		private var _value:AnyRangeNumber;

    	/**
    	 * @private
    	 */
    	public function EnumConstant(value:AnyRangeNumber) {
			this._value = value;
		}

        /**
         * Results into AnyRangeNumber.
         */
		override public function valueOf():* {
			return this._value;
		}

		override public function toString():String {
			return '[object EnumConstant]';
		}
    }
}