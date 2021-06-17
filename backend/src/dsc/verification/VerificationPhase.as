package dsc.verification {

	import flash.utils.Dictionary;

	public final class VerificationPhase {

		private static const byValue:Dictionary = new Dictionary;

		public static const DECLARATION_1:VerificationPhase = new VerificationPhase(0);
		public static const DECLARATION_2:VerificationPhase = new VerificationPhase(1);
		public static const DECLARATION_3:VerificationPhase = new VerificationPhase(2);
		public static const DECLARATION_4:VerificationPhase = new VerificationPhase(3);
		public static const INTERFACES:VerificationPhase = new VerificationPhase(4);
		public static const DECLARATION_5:VerificationPhase = new VerificationPhase(5);
		public static const INTERFACE_OPERATORS:VerificationPhase = new VerificationPhase(6);
		public static const OMEGA:VerificationPhase = new VerificationPhase(7);

		private var _value:uint;

		public function VerificationPhase(value:uint) {
			_value = value;
			byValue[value] = this;
		}

		public static function valueOf(value:uint):VerificationPhase {
			return byValue[value];
		}

		public function valueOf():uint {
			return _value;
		}
	}
}