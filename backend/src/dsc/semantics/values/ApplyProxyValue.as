package dsc.semantics.values {
	import dsc.semantics.*;

    public final class ApplyProxyValue extends Value {
    	private var _object:Symbol;
    	private var _proxy:Symbol;

    	public function ApplyProxyValue(object:Symbol, proxy:Symbol) {
    		_object = object;
    		_proxy = proxy;
            this.valueType = proxy.methodSignature.result;
    	}

    	override public function get object():Symbol {
    		return _object;
    	}

    	override public function get applyProxy():Symbol {
    		return _proxy;
    	}

        override public function toString():String {
            return '[object ApplyProxyValue]';
        }
    }
}