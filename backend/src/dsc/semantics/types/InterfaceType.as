package dsc.semantics.types {
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.values.*;

    public final class InterfaceType extends Type {
        private var _name:Symbol;
        private var _foreignName:String;
        private var _superInterfaces:Array;
        private var _subInterfaces:Array;

        /**
         * @private
         */
        internal const _implementors:Array = [];

        /**
         * @private
         */
        public function InterfaceType(name:Symbol) {
            _name = name;
        }

        override public function get name():Symbol {
            return _name;
        }

        override public function get implementors():Array {
            return _implementors;
        }

        override public function get superInterfaces():Array {
            return _superInterfaces;
        }

        override public function get subInterfaces():Array {
            return _subInterfaces;
        }

        override public function get foreignName():String {
            return _foreignName;
        }

        override public function set foreignName(name:String):void {
            _foreignName = name;
        }

        override public function extendType(type:Symbol):Array {
            if (type.isSubtypeOf(this) || this.isSubtypeOf(type) || !(type is InterfaceType))
                return [];
            var errors:Array = [];
            for each (var property:Property in type.delegate.namesTree)
                this.delegate.names[property.key] = property.value;
            return errors;
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
            return fullyQualifiedName;
        }
    }
}