package dsc.semantics {
    import flash.utils.Proxy;
    import flash.utils.flash_proxy;

    public final class NamesTree extends Proxy {
        private var _delegate:Symbol;
        private var _names:Names;
        private var _startIndex:int;

        public function NamesTree(delegate:Symbol) {
            _delegate = delegate;
            _names = delegate.names;
        }

        override flash_proxy function nextNameIndex(index:int):int {
            while (_names.length == 0 || index - _startIndex >= _names.length) {
                _delegate = _delegate.inheritsDelegate;
                if (!_delegate) return 0;
                _names = _delegate.names;
                _startIndex = index;
            }
            return index + 1;
        }

        override flash_proxy function nextValue(index:int):* {
            return new Property(_names.getNameAt(index - _startIndex - 1), _names[index - _startIndex - 1]);
        }
    }
}