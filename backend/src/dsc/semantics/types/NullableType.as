package dsc.semantics.types {
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.values.*;

    public final class NullableType extends Type {
        private var _wrapsType:Symbol;

        /**
         * @private
         */
        public function NullableType(wrapsType:Symbol) {
            _wrapsType = wrapsType;
        }

        override public function get wrapsType():Symbol {
            return _wrapsType;
        }

        override public function get superType():Symbol {
            return _wrapsType.superType;
        }

        override public function get defaultValue():Symbol {
            return ownerContext.factory.undefinedConstant(this);
        }

        override public function get originalDefinition():Symbol {
            return _wrapsType.originalDefinition;
        }

        override public function get classFlags():uint {
            return _wrapsType.classFlags;
        }

        override public function get enumFlags():uint {
            return _wrapsType.enumFlags;
        }

        override public function get containsUndefined():Boolean {
            return true;
        }

        override public function get containsNull():Boolean {
            return true;
        }

        override public function toString():String {
            return wrapsType.toString() + '?';
        }
    }
}