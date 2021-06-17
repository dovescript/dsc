package dsc.targets.js.sourcemap {
    public final class Base64VLQ {
        private static const VLQ_BASE_SHIFT:Number = 5;
        private static const VLQ_BASE:Number = 1 << VLQ_BASE_SHIFT;
        private static const VLQ_BASE_MASK:Number = VLQ_BASE - 1;
        private static const VLQ_CONTINUATION_BIT:Number = VLQ_BASE;

        private static function toVLQSigned(aValue:Number):Number {
            return aValue < 0 ? (-aValue << 1) + 1 : (aValue << 1) + 0;
        }

        public static function encode(aValue:Number):String {
            var encoded:String = '';
            var digit:Number;
            var vlq:Number = toVLQSigned(aValue);

            do {
                digit = vlq & VLQ_BASE_MASK;
                vlq >>>= VLQ_BASE_SHIFT;
                if (vlq > 0)
                    digit |= VLQ_CONTINUATION_BIT;
                encoded += Base64.encode(digit);
            } while (vlq > 0);

            return encoded;
        };
    }
}