package dsc.semantics.constants {
    import dsc.semantics.*;

    public final class StringConstant extends Constant {
		private var _value:String;

    	/**
    	 * @private
    	 */
    	public function StringConstant(value:String) {
			this._value = value;
		}

		override public function valueOf():* {
			return this._value;
		}

		override public function toString():String {
			return '[object StringConstant]';
		}
    }
}