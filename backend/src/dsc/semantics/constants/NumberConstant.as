package dsc.semantics.constants {
    import dsc.semantics.*;

    public final class NumberConstant extends Constant {
		private var _value:Number;

    	/**
    	 * @private
    	 */
    	public function NumberConstant(value:Number) {
			this._value = value;
		}

		override public function valueOf():* {
			return this._value;
		}

		override public function toString():String {
			return '[object NumberConstant]';
		}
    }
}