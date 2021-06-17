package dsc.semantics {
    public final class VirtualSlot extends Slot {
        private var _name:Symbol;
        private var _type:Symbol;
        private var _getter:Symbol;
        private var _setter:Symbol;
        private var _definedIn:Symbol;

        /**
         * @private
         */
        public function VirtualSlot(name:Symbol, type:Symbol) {
            this._name = name;
            this._type = type;
        }

        override public function get name():Symbol {
            return _name;
        }

        override public function get getter():Symbol {
            return _getter;
        }

        override public function set getter(method:Symbol):void {
            _getter = method;
        }

        override public function get setter():Symbol {
            return _setter;
        }

        override public function set setter(method:Symbol):void {
            _setter = method;
        }

        override public function get readOnly():Boolean {
            return !_setter;
        }

        override public function get writeOnly():Boolean {
            return !_getter;
        }

        override public function get valueType():Symbol {
            return _type;
        }

        override public function set valueType(type:Symbol):void {
            _type = type;
        }

        override public function get definedIn():Symbol {
            return _definedIn;
        }

        override public function set definedIn(object:Symbol):void {
            _definedIn = object;
        }

        override public function toString():String {
            return '[object VirtualSlot]';
        }
    }
}