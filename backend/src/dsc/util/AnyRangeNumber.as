package dsc.util {
    import com.hurlant.math.BigInteger;

    /**
     * Abstraction for Number, Char and BigInt (com.hurlant.math.BigInteger).
     */
    public final class AnyRangeNumber {
        private var _object:*;

        static public function numberOfClass(value:Number, classObject:Class):AnyRangeNumber {
            switch (classObject) {
                case Number: return new AnyRangeNumber(value);
                case BigInteger: return new AnyRangeNumber(new BigInteger(value));
                default: return new AnyRangeNumber(0);
            }
        }

        public function AnyRangeNumber(object:*) {
            _object = object;
        }

        public function valueOf():* {
            return this._object;
        }

        public function add(value:Number):AnyRangeNumber {
            if (_object is BigInteger)
                return new AnyRangeNumber(BigInteger(_object).add(new BigInteger(value)));
            return new AnyRangeNumber(_object + value);
        }

        public function multiply(value:Number):AnyRangeNumber {
            if (_object is BigInteger)
                return new AnyRangeNumber(BigInteger(_object).multiply(new BigInteger(value)));
            return new AnyRangeNumber(_object * value);
        }
    }
}