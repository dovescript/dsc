package dsc.semantics {
    import dsc.semantics.frames.*;

    public final class ScopeChain {
        private var _nss:NamespaceSet;
        private var _frame:Symbol;

        public function ScopeChain(context:Context) {
            _nss = context.factory.namespaceSet();
        }

        /**
         * Open namespace list.
         */
        public function get nss():NamespaceSet {
            return _nss;
        }

        public function get currentFrame():Symbol {
            return _frame;
        }

        public function getLexicalReservedNamespace(type:String):Symbol {
            return _frame ? _frame.getLexicalReservedNamespace(type) : null;
        }

        public function resolveName(name:Symbol):Symbol {
            return _frame ? _frame.resolveName(name) : null;
        }

        public function resolveMultiName(nss:NamespaceSet, name:String):Symbol {
            return _frame ? _frame.resolveMultiName(nss, name) : null;
        }

        public function enterFrame(frame:Symbol):void {
            Frame(frame)._parentFrame ||= _frame;
            _frame = frame;
            var list:NamespaceSet = frame.openNamespaceList;
            if (list)
                for each (var q:Symbol in list)
                    nss.addItem(q);
        }

        public function exitFrame():void {
            var k:Symbol = _frame;
            _frame = k.parentFrame;
            var list:NamespaceSet = k.openNamespaceList;
            if (list)
                nss.popItems(list.length);
        }
    }
}