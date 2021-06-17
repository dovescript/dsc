package dsc.semantics.types {
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.values.*;

    public final class VoidType extends Type {
        /**
         * @private
         */
        public function VoidType() {}

        override public function get containsUndefined():Boolean {
            return true;
        }

        override public function get containsNull():Boolean {
            return false;
        }

        override public function toString():String {
            return 'void';
        }
    }
}