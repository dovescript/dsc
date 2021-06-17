package dsc.semantics.types {
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.values.*;

    public final class NullType extends Type {
        /**
         * @private
         */
        public function NullType() {}

        override public function get containsUndefined():Boolean {
            return false;
        }

        override public function get containsNull():Boolean {
            return true;
        }

        override public function toString():String {
            return 'null';
        }
    }
}