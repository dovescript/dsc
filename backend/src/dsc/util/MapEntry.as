package dsc.util {
    internal final class MapEntry {
        private var _key:*;
        private var _value:*;
        public function MapEntry(key:*, value:*) {
            _key = key;
            _value = value;
        }
        public function get key():* { return _key }
        public function get value():* { return _value }
    }
}