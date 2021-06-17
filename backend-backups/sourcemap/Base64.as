package dsc.targets.js.sourcemap {
    public final class Base64 {
        private static const intToCharMap:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.split('');

        public static function encode(number:Number):String {
            if (0 <= number && number < intToCharMap.length)
                return intToCharMap.charAt(number);
            throw new TypeError('Must be between 0 and 63: ' + number);
            return '';
        }
    }
}