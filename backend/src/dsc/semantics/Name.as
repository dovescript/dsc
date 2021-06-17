package dsc.semantics {
    import dsc.semantics.constants.*;

    public class Name extends Symbol {
        private var _qualifier:Symbol;
        private var _localName:String;

        public function Name(qualifier:Symbol, localName:String) {
            _qualifier = qualifier;
            _localName = localName;
        }

        override public function get qualifier():Symbol {
            return _qualifier;
        }

        override public function get localName():String {
            return _localName;
        }

        override public function toString():String {
            if (_qualifier is ReservedNamespaceConstant)
                return _localName;
            return _qualifier.toString() + '::' + _localName;
        }
    }
}