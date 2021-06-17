package dsc.semantics {
    public final class VariableSlot extends Slot {
        private var _name:Symbol;
        private var _readOnly:Boolean;
        private var _initialValue:Symbol;
        private var _enumPairAssociation:Array;
        private var _definedIn:Symbol;

        /**
         * @private
         */
        public function VariableSlot(name:Symbol, readOnly:Boolean, type:Symbol) {
            this._name = name;
            this._readOnly = readOnly;
            this.valueType = type;
        }

        override public function get name():Symbol {
            return _name;
        }

        override public function get readOnly():Boolean {
            return _readOnly;
        }

        override public function set readOnly(value:Boolean):void {
            _readOnly = value;
        }

        override public function get writeOnly():Boolean {
            return false;
        }

        override public function get initialValue():Symbol {
            return _initialValue;
        }

        override public function set initialValue(value:Symbol):void {
            _initialValue = value;
        }

        override public function get enumPairAssociation():Array { return _enumPairAssociation }

        override public function set enumPairAssociation(array:Array):void { _enumPairAssociation = array }

        override public function get definedIn():Symbol {
            return _definedIn;
        }

        override public function set definedIn(object:Symbol):void {
            _definedIn = object;
        }

        override public function toString():String {
            return '[object VariableSlot]';
        }
    }
}