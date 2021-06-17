package dsc.semantics.constants {
    import dsc.semantics.*;

    public final class CharConstant extends Constant {
		private var _value:uint;

    	/**
    	 * @private
    	 */
    	public function CharConstant(value:uint) {
			this._value = value;
		}

		override public function valueOf():* {
			return this._value;
		}

		override public function toString():String {
			return '[object CharConstant]';
		}
    }
}