package dsc.semantics.constants {
    import dsc.semantics.*;

    public final class NullConstant extends Constant {
    	/**
    	 * @private
    	 */
    	public function NullConstant() {}

		override public function toString():String {
			return '[object NullConstant]';
		}
    }
}