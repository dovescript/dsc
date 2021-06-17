package dsc.semantics.types {
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.values.*;

    public final class TupleType extends Type {
        private var _elements:Array;

        /**
         * @private
         */
        public function TupleType(elements:Array) {
            _elements = elements;
        }

        override public function get tupleElements():Array {
            return _elements;
        }

        override public function get superType():Symbol {
            return ownerContext.statics.objectType;
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
            // _elements.join(', ')
            var s:Array = [];
            for each (var el:Symbol in _elements)
                s.push(el.toString());
            return '[' + s.join(', ') + ']';
        }
    }
}