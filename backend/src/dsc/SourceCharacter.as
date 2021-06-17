package dsc {
    import com.recoyx.util.CharCategory;

    /**
     * Defines character validation methods used by tokenizers.
     */
    public final class SourceCharacter {
        static public function isWhiteSpace(cv:uint):Boolean {
            if (cv == 0x20 || cv == 0x09 || cv == 0x0b || cv == 0x0c) return true;

            return !!(cv >> 7) && CharCategory.fromCharCode(cv) == CharCategory.SPACE_SEPARATOR;
        }

        static public function isLineTerminator(cv:uint):Boolean {
            return cv == 0x0a || cv == 0x0d || cv == 0x2048 || cv == 0x2049;
        }

        static public function isDecimalDigit(cv:uint):Boolean {
            return cv >= 0x30 && cv <= 0x39;
        }

        static public function isHexDigit(cv:uint):Boolean {
            return isDecimalDigit(cv) || isHexUpperCaseLetter(cv) || isHexLowerCaseLetter(cv);
        }

        static public function isHexUpperCaseLetter(cv:uint):Boolean {
            return cv >= 0x41 && cv <= 0x46;
        }

        static public function isHexLowerCaseLetter(cv:uint):Boolean {
            return cv >= 0x61 && cv <= 0x66;
        }

        static public function hexDigitMV(cv:uint):int {
            return isHexLowerCaseLetter(cv) ? cv - 87 : isDecimalDigit(cv) ? cv - 48 : isHexUpperCaseLetter(cv) ? cv - 55 : -1;
        }

        static public function isIdentifierStart(cv:uint):Boolean {
            if ((cv >> 7) == 0) return (cv >= 0x61 && cv <= 0x7a) || (cv >= 0x41 && cv <= 0x5a) || cv == 0x5f || cv == 0x24;

            return CharCategory.fromCharCode(cv).isLetter;
        }

        static public function isIdentifierPart(cv:uint):Boolean {
            if ((cv >> 7) == 0) return (cv >= 0x61 && cv <= 0x7a) || (cv >= 0x41 && cv <= 0x5a) || isDecimalDigit(cv) || cv == 0x5f || cv == 0x24;

            var category:CharCategory = CharCategory.fromCharCode(cv);
            return category.isLetter
                || category == CharCategory.LETTER_NUMBER
                || category == CharCategory.DECIMAL_NUMBER
                || category == CharCategory.CONNECTOR_PUNCTUATION
                || category == CharCategory.COMBINING_SPACING_MARK
                || category == CharCategory.NON_SPACING_MARK;
        }

        static public function isXMLNameStart(cv:uint):Boolean {
            if ((cv >> 7) == 0) return (cv >= 0x61 && cv <= 0x7a) || (cv >= 0x41 && cv <= 0x5a) || cv == 0x5f || cv == 0x3a;

            var category:CharCategory = CharCategory.fromCharCode(cv);
            return category.isLetter || category == CharCategory.LETTER_NUMBER;
        }

        static public function isXMLNamePart(cv:uint):Boolean {
            if ((cv >> 7) == 0) return (cv >= 0x61 && cv <= 0x7a) || (cv >= 0x41 && cv <= 0x5a) || isDecimalDigit(cv) || cv == 0x5f || cv == 0x3a || cv == 0x2e || cv == 0x2d;

            var category:CharCategory = CharCategory.fromCharCode(cv);
            return category.isLetter || category == CharCategory.LETTER_NUMBER || category == CharCategory.DECIMAL_NUMBER;
        }
    }
}