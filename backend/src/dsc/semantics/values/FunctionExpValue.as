package dsc.semantics.values {
	import dsc.semantics.*;

    public final class FunctionExpValue extends Value {
    	private var _slot:Symbol;

    	public function FunctionExpValue(slot:Symbol) {
    		_slot = slot;
    	}

    	override public function get ofMethodSlot():Symbol {
    		return _slot;
    	}

        override public function toString():String {
            return '[object FunctionExpValue]';
        }
    }
}