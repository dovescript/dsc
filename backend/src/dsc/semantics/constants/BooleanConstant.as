package dsc.semantics.constants {
    import dsc.semantics.*;

    public final class BooleanConstant extends Constant {
		private var _value:Boolean;

    	/**
    	 * @private
    	 */
    	public function BooleanConstant(value:Boolean) {
			this._value = value;
		}

		override public function valueOf():* {
			return this._value;
		}

		override public function toString():String {
			return '[object BooleanConstant]';
		}
    }
}