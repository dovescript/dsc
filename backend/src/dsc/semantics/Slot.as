package dsc.semantics {
    public class Slot extends Symbol {
    	private var _type:Symbol;

		override public function get valueType():Symbol {
			return _type;
		}

		override public function set valueType(type:Symbol):void {
			_type = type;
		}
    }
}