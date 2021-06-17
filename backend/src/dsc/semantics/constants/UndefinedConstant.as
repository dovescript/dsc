package dsc.semantics.constants {
    import dsc.semantics.*;

    public final class UndefinedConstant extends Constant {
    	/**
    	 * @private
    	 */
    	public function UndefinedConstant() {}

		override public function toString():String {
			return '[object UndefinedConstant]';
		}
    }
}