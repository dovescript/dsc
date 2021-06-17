package dsc.semantics {
    import dsc.semantics.accessErrors.*;

    import flash.utils.Proxy;
    import flash.utils.flash_proxy;

    public final class Names extends Proxy {
        private var _array:Array = [];
        private var _length:uint;

        public function Names() {}

        public function get length():uint {
            return _length;
        }

        /**
         * Resolves name.
         */
        public function resolveName(name:Symbol):Symbol {
            for (var index:uint = 0; index != _array.length; index += 2) if (_array[index] === name) return _array[index + 1];

            return null;
        }

        /**
         * Resolves multi-name.
         * @return If property is undefined, results into null.
         * * If there is namespace conflict, results into an dsc.semantics.accessErrors.AmbiguousReference symbol.
         */
        public function resolveMultiName(nss:NamespaceSet, name:String):Symbol {
            var i:int;
            var r:int = -1;
            var found:Boolean;
            var leadingNs:Symbol;

            if (!nss) {
                for (i = 0; i != _array.length; i += 2)
                    if (_array[i].localName === name)
                        return _array[i + 1];
                return null;
            }

			var nssArray:Array = nss._array;

            for (var j:int = nssArray.length - 1; j != -1; --j) {
                var ns:Symbol = nssArray[j];

                for (i = 0; i != _array.length; i += 2) {
                    var qname:Symbol = _array[i];

                    if (qname.localName === name) {
                        found = true;
                        if (qname.qualifier === ns && leadingNs !== ns) {
                            if (r == -1)
                                r = i, leadingNs = ns;
                            else return new AmbiguousReference(name, []);
                        }
                        continue;
                    }
                }
                if (!found)
                    break;
            }

            return r == -1 ? null : _array[r + 1];
        }

        public function getNameAt(index:uint):Symbol {
            return index < _length ? _array[index * 2] : null;
        }

        public function numberOf(name:Symbol):int {
            var j:int;
            for (var i:uint = 0; i != _array.length; i += 2, ++j)
                if (_array[i] === name)
                    return j;
            return -1;
        }

        public function hasName(name:Symbol):Boolean {
            for (var i:uint = 0; i != _array.length; i += 2) if (_array[i] === name) return true;

            return false;
        }

        public function defineName(name:Symbol, symbol:Symbol):void {
            if (!hasName(name))
                _array.push(name, symbol),
                ++_length;
        }

        override flash_proxy function nextNameIndex(index:int):int {
            return index < _length ? index + 1 : 0;
        }

        override flash_proxy function nextName(index:int):String {
            return _array[index * 2].localName;
        }

        override flash_proxy function nextValue(index:int):* {
            var i:uint = (index - 1) * 2;
            return new Property(_array[i], _array[i + 1]);
        }

        override flash_proxy function getProperty(name:*):* {
            var index:uint = uint(name);
            return index < _length ? _array[index * 2 + 1] : null;
        }

        override flash_proxy function deleteProperty(name:*):Boolean {
            for (var i:uint = 0; i != _array.length; i += 2) {
                if (_array[i] === name) {
                    _array.splice(i, 2);
                    --_length;
                    return true;
                }
            }

            return false;
        }
    }
}