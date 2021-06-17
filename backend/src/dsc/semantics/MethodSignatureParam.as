package dsc.semantics {
	public final class MethodSignatureParam {
		private var _position:String;
		private var _type:Symbol;

		public function MethodSignatureParam(position:String, type:Symbol) {
			_position = position;
			_type = type;
		}

		/**
		 * One of the strings <code>required</code>, <code>optional</code> and <code>rest</code>.
		 */
		public function get position():String {
			return _position;
		}

		/**
		 * Parameter type. If <code>position</code> is <code>rest</code>, <code>type</code> is <code>null</code>
		 */
		public function get type():Symbol {
			return _type;
		}
	}
}