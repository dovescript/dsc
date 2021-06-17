package dsc.semantics.constants {
    import dsc.semantics.*;
    import dsc.semantics.values.*;

    public final class ReservedNamespaceConstant extends NamespaceConstant {
        private var _type:String;
        private var _package:Symbol;

    	/**
    	 * @private
    	 */
    	public function ReservedNamespaceConstant(type:String, ofPackage:Symbol) {
            this._type = type;
            this._package = ofPackage;
        }

        override public function get namespaceType():String {
            return this._type;
        }

        override public function get definedIn():Symbol {
            return this._package;
        }

        override public function toString():String {
            return this._type;
        }
    }
}