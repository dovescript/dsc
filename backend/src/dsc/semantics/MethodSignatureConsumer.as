package dsc.semantics {
	public final class MethodSignatureConsumer {
		private var _signature:MethodSignature;
		private var _minLength:uint;
		private var _maxLength:Number;
		private var _index:uint;

		public function MethodSignatureConsumer(signature:MethodSignature) {
			_signature = signature;
			var params:Array = _signature.params;
			_minLength = params ? params.length : 0;
			var optParams:Array = _signature.optParams;
			_maxLength = _minLength + (optParams ? optParams.length : 0);
		}

		public function get signature():MethodSignature {
			return _signature;
		}

		public function get minLength():uint {
			return _minLength;
		}

		public function get maxLength():Number {
			return _signature.hasRest ? Infinity : _maxLength;
		}

		public function get index():uint {
			return _index;
		}

		public function shift():MethodSignatureParam {
			if (_index >= _maxLength) {
				if (!_signature.hasRest)
					return undefined;
				else
					return ++_index, new MethodSignatureParam('rest', undefined);
			}
			else if (_index >= _minLength)
				return new MethodSignatureParam('optional', _signature.optParams[_index++ - _minLength]);
			else return new MethodSignatureParam('required', _signature.params[_index++]);
		}
	}
}