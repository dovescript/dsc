package dsc.semantics.values {
	import dsc.semantics.*;
    import dsc.semantics.constants.*;

    public class ObjectValue extends Constant {
    	private const _names:Names = new Names;
		private var _definedIn:Symbol;

		/**
		 * @private
		 */
		public function ObjectValue(definedIn:ObjectValue = null) {
			_definedIn = definedIn;
		}

        override public function get definedIn():Symbol {
        	return _definedIn;
        }

		override public function set definedIn(object:Symbol):void {
			_definedIn = object;
		}

        override public function get names():Names {
            return _names;
        }

		override public function resolveName(name:Symbol):Symbol {
			return _names.resolveName(name);
		}

		override public function resolveMultiName(nss:NamespaceSet, name:String):Symbol {
			return _names.resolveMultiName(nss, name);
		}

        override public function toString():String {
            return '[object ObjectValue]';
        }
    }
}