package dsc.targets.js.sourcemap {
    import dsc.util.Map;

    internal class ArraySet {
        private const _array:Array = [];
        private const _set:Map = new Map;

        public static function fromArray(aArray:Array, aAllowDuplicates:Boolean = false):ArraySet {
            var set:ArraySet = new ArraySet;
            for (var i:Number = 0, len:Number = aArray.length; i < len; ++i)
                set.add(aArray[i], aAllowDuplicates);
            return set;
        }

        public function get length():Number {
            return _set.length;
        }

        public function add(aStr:String, aAllowDuplicates:Boolean = false):void {
            const isDuplicate:Boolean = this.has(aStr);
            const idx:Number = this._array.length;
            if (!isDuplicate || aAllowDuplicates)
                this._array.push(aStr);
            if (!isDuplicate)
                this._set.set(aStr, idx);
        }

        public function has(aStr:String):Boolean {
            return _set.has(aStr);
        }

        public function indexOf(aStr:String):Number {
            const idx:Number = _set.get(aStr);
            if (idx >= 0)
                return idx;
            throw new Error('"' + aStr + '" is not in the set.');
            return 0;
        }

        public function at(aIdx:Number):String {
            if (aIdx >= 0 && aIdx < _array.length)
                return _array[aIdx];
            throw new Error('No element indexed by ' + aIdx);
        }

        public function toArray():Array {
            return _array.slice();
        }
    }
}