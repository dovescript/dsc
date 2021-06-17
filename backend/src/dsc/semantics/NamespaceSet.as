package dsc.semantics {
    import flash.utils.flash_proxy;
    import dsc.semantics.constants.Constant;

    /**
     * A descending-order namespace set.
     */
    public final class NamespaceSet extends Constant {
        /**
         * @private
         */
        public const _array:Array = [];

        private var _prefix:String;

        public function NamespaceSet(prefix:String = undefined) {
            _prefix = prefix;
        }

        override public function get prefix():String { return _prefix }

        override public function get length():Number {
            return _array.length;
        }

        override public function addItem(item:Symbol):void {
            _array.push(item);
        }

        override public function popItem():Symbol {
            return _array.pop();
        }

        override public function popItems(length:uint):Array {
            return _array.splice(this.length - length, length);
        }

        override flash_proxy function nextNameIndex(index:int):int {
            return _array.length - index > 0 ? index + 1 : 0;
        }

        override flash_proxy function nextValue(index:int):* {
            return _array[_array.length - index];
        }

        override public function get namespaces():Array {
            return _array.slice();
        }

        override public function toString():String {
            return '[object NamespaceSet]';
        }
    }
}