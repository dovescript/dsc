package dsc.semantics.accessErrors {
    import dsc.semantics.Symbol;
    import dsc.semantics.MethodSignature;

    public final class IncompatibleOverrideSignature extends AccessError {
    	private var _expected:MethodSignature;

    	public function IncompatibleOverrideSignature(expected:MethodSignature) {
    		_expected = expected;
    	}

    	override public function get expectedMethodSignature():MethodSignature {
    		return _expected;
    	}
    }
}