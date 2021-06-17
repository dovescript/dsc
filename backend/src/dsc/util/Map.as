package dsc.util {
    public class Map {
        private const _array:Array = [];

        public function Map() {
        }

        public function get(key:*):* {
            var r:Array = _array.filter(function(v) { return key === v });
            return r[0];
        }
        public function set(key:*, value:*):Map {
            var insert:Boolean = true;
            for (var i:Number = 0; i != _array.length; ++i)
                if (_array[i].key === key)
                    _array[i] = new MapEntry(key, value),
                    insert = false;
            if (insert)
                _array.push(new MapEntry(key, value));
            return this;
        }
        public function remove(key:*):Boolean {
            for (var i:Number = 0; i != _array.length; ++i) {
                if (_array[i].key === key) {
                    _array.removeAt(i);
                    return true;
                }
            }
            return false;
        }
        public function has(key:*):Boolean {
            return _array.filter(function(key2) { return key === key2 }).length > 0;
        }
        public function clear():void {
            _array.length = 0;
        }
        public function length():Number {
            return _array.length;
        }
        public function keys():Array {
            return _array.map(function(p) { return p.key });
        }
        public function values():Array {
            return _array.map(function(p) { return p.value });
        }
        public function entries():Array {
            return _array.map(function(p) { return [p.key, p.value] });
        }
    }
}