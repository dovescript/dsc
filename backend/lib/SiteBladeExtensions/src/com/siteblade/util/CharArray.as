package com.siteblade.util {

    import flash.utils.ByteArray;

    import flash.utils.Proxy;

    import flash.utils.flash_proxy;

    public final class CharArray extends Proxy {

        public var position:uint;

        private const _vector:Vector.<uint> = new Vector.<uint>;

        private var _sliceStart:*;

        public function CharArray(...arguments) {
            for each (var arg:* in arguments) {
                if (arg is ByteArray)
                    this.pushUTFBytes(arg);
                else {
                    var s:String = String(arg);
                    var l:uint = s.length;
                    for (var i:uint = 0; i != l; ++i)
                        _vector.push(s.charCodeAt(i));
                }
            }
        }

        public function pushUTFBytes(ba:ByteArray):void {
            while (ba.position != ba.length) {
                var lead:uint = ba.readUnsignedByte();
                if (lead >> 7 == 0)
                    _vector.push(lead);
                else if (lead >> 5 === 6) {
                    _vector.push(((lead & 0x1f) << 6)
                        | (ba.readUnsignedByte() & 0x3f));
                }
                else if (lead >> 4 === 14) {
                    _vector.push(((lead & 0x0f) << 12)
                        | ((ba.readUnsignedByte() & 0x3f) << 6)
                        | (ba.readUnsignedByte() & 0x3f));
                }
                else {
                    _vector.push(((lead & 0x07) << 18)
                        | ((ba.readUnsignedByte() & 0x3f) << 12)
                        | ((ba.readUnsignedByte() & 0x3f) << 6)
                        | (ba.readUnsignedByte() & 0x3f));
                }
            }
        }

        public function get length():uint {
            return this._vector.length;
        }

        public function get hasRemaining():Boolean {
            return this.position != this._vector.length;
        }

        override flash_proxy function getProperty(index:*):* { var p:uint = this.position + uint(index); return p < _vector.length ? _vector[p] : undefined }

        override flash_proxy function setProperty(index:*, value:*):void { _vector[this.position + uint(index)] = uint(value) }

        public function shift():uint {
            var r:uint = this._vector[this.position];
            ++this.position;
            return r;
        }

        public function slice(from:uint = 0, to:uint = uint.MAX_VALUE, absolute:Boolean = false):String {
            if (!absolute)
                from += this.position,
                to += this.position;
            from = from >= this.length ? this.length : from;
            to = to >= this.length ? this.length : to;
            if (from > to) { var k:uint = from; from = to, to = k }

            var array:Array = [];
            for (var i:uint = from; i != to; ++i) array.push(_vector[i]);
            return String.fromCharCode.apply(null, array);
        }

        public function beginSlice():void { _sliceStart = this.position }

        public function endSlice():String {
            if (_sliceStart === undefined) return "";

            var p:uint = _sliceStart;

            if (p > this.position) return "";

            _sliceStart = undefined;
            var array:Array = [];

            for (var i:uint = p; i != this.position; ++i) array.push(_vector[i]);

            return String.fromCharCode.apply(null, array);
        }

        public function toString():String {
            return slice();
        }
    }
}