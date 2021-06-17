package dsc.semantics.types {

    import dsc.semantics.*;

    import dsc.semantics.constants.*;

    import dsc.semantics.frames.*;

    import dsc.semantics.values.*;

    public final class AnyType extends Type {

        /**
         * @private
         */
        public function AnyType() {}

        override public function get defaultValue():Symbol {
            return ownerContext.factory.undefinedConstant(this);
        }

        override public function get containsUndefined():Boolean {
            return true;
        }

        override public function get containsNull():Boolean {
            return true;
        }

        override public function toString():String {
            return '*';
        }
    }
}