package dsc.semantics {

    public final class TargetAndValue extends Symbol {

    	private var _target:Symbol;

    	private var _value:Symbol;

    	/**
    	 * @private
    	 */
    	public function TargetAndValue(target:Symbol, value:Symbol) {
    		super();
    		_target = target;
    		_value = value;
    	}

        /**
         * Target variable slot or reference value. This may be <code>null</code>.
         */
    	override public function get target():Symbol {
            return _target;
        }

    	override public function get value():Symbol {
            return _value;
        }

        override public function set value(value:Symbol):void {
            _value = value;
        }

        override public function toString():String {
            return '[object TargetAndValue]';
        }
    }
}