package dsc.semantics.constants {
    import dsc.semantics.*;
    import dsc.semantics.values.*;

    public final class ExplicitNamespaceConstant extends NamespaceConstant {
        private var _prefix:String;
        private var _uri:String;

    	/**
    	 * @private
    	 */
    	public function ExplicitNamespaceConstant(prefix:String, uri:String) {
            this._prefix = prefix;
            this._uri = uri;
        }

        override public function get prefix():String {
            return this._prefix;
        }

        override public function get uri():String {
            return this._uri;
        }

        override public function toString():String {
            return this._prefix;
        }
    }
}