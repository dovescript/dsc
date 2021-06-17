package dsc.semantics.constants {
    import dsc.semantics.*;
    import com.hurlant.math.BigInteger;

    public final class BigIntConstant extends Constant {
		private var _value:BigInteger;

    	/**
    	 * @private
    	 */
    	public function BigIntConstant(value:BigInteger) {
			this._value = value;
		}

		override public function valueOf():* {
			return this._value;
		}

		override public function toString():String {
			return '[object BigIntConstant]';
		}
    }
}