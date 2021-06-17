package dsc.semantics.types {
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.values.*;

    public final class TypeParameter extends Type {
        private var _name:Symbol;

        /**
         * @private
         */
        public function TypeParameter(name:Symbol, definedIn:Symbol) {
            _name = name;
            this.definedIn = definedIn;
        }

        override public function get name():Symbol {
            return _name;
        }

        override public function get defaultValue():Symbol {
            return null;
        }

        override public function get containsUndefined():Boolean {
            return false;
        }

        override public function get containsNull():Boolean {
            return false;
        }

        override public function toString():String {
            return _name.toString();
        }
    }
}