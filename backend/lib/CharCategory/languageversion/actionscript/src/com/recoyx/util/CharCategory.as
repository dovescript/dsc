package com.recoyx.util
{
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.Endian;

    public final class CharCategory
    {
        [Embed(
            source = '../../../../../../ucdmin/output/generatedBMP.bin',
            mimeType = 'application/octet-stream'
        )]
        static private const bmpPlaneClass:Class;
        static private const bmpPlane:ByteArray = new bmpPlaneClass as ByteArray;
        bmpPlane.endian = Endian.LITTLE_ENDIAN;

        [Embed(
            source = '../../../../../../ucdmin/output/generatedSP.bin',
            mimeType = 'application/octet-stream'
        )]
        static private const smpPlaneClass:Class;
        static private const smpPlane:ByteArray = new smpPlaneClass as ByteArray;
        smpPlane.endian = Endian.LITTLE_ENDIAN;

        private var _value:uint;
        static private var _categories:Dictionary = new Dictionary;

        static public const CONTROL_OTHER:CharCategory = new CharCategory(0x00); // Cc
        static public const FORMAT_OTHER:CharCategory = new CharCategory(0x01); // Cf
        static public const PRIVATE_USE_OTHER:CharCategory = new CharCategory(0x02); // Co
        static public const SURROGATE_OTHER:CharCategory = new CharCategory(0x03); // Cs
        static public const NOT_ASSIGNED_OTHER:CharCategory = new CharCategory(0x04); // Cn

        static public const LOWERCASE_LETTER:CharCategory = new CharCategory(0x10);     // Ll
        static public const MODIFIER_LETTER:CharCategory = new CharCategory(0x10 + 1); // Lm
        static public const OTHER_LETTER:CharCategory = new CharCategory(0x10 + 2); // Lo
        static public const TITLECASE_LETTER:CharCategory = new CharCategory(0x10 + 3); // Lt
        static public const UPPERCASE_LETTER:CharCategory = new CharCategory(0x10 + 4);  // Lu

        static public const COMBINING_SPACING_MARK:CharCategory = new CharCategory(0x20); // Mc
        static public const ENCLOSING_MARK:CharCategory = new CharCategory(0x20 + 1); // Me
        static public const NON_SPACING_MARK:CharCategory = new CharCategory(0x20 + 2); // Mn

        static public const DECIMAL_NUMBER:CharCategory = new CharCategory(0x40); // Nd
        static public const LETTER_NUMBER:CharCategory = new CharCategory(0x40 + 1); // Nl
        static public const OTHER_NUMBER:CharCategory = new CharCategory(0x40 + 2); // No
        static public const CONNECTOR_PUNCTUATION:CharCategory = new CharCategory(0x40 + 3); // Pc
        static public const DASH_PUNCTUATION:CharCategory = new CharCategory(0x40 + 4); // Pd
        static public const OPEN_PUNCTUATION:CharCategory = new CharCategory(0x40 + 5); // Ps
        static public const CLOSE_PUNCTUATION:CharCategory = new CharCategory(0x40 + 6); // Pe
        static public const INITIAL_QUOTE_PUNCTUATION:CharCategory = new CharCategory(0x40 + 7); // Pi
        static public const FINAL_QUOTE_PUNCTUATION:CharCategory = new CharCategory(0x40 + 8); // Pf
        static public const OTHER_PUNCTUATION:CharCategory = new CharCategory(0x40 + 9); // Po
        static public const CURRENCY_SYMBOL:CharCategory = new CharCategory(0x40 + 10); // Sc
        static public const MODIFIER_SYMBOL:CharCategory = new CharCategory(0x40 + 11); // Sk
        static public const MATH_SYMBOL:CharCategory = new CharCategory(0x40 + 12); // Sm
        static public const OTHER_SYMBOL:CharCategory = new CharCategory(0x40 + 13); // So
        static public const LINE_SEPARATOR:CharCategory = new CharCategory(0x40 + 14); // Zl
        static public const PARAGRAPH_SEPARATOR:CharCategory = new CharCategory(0x40 + 15); // Zp
        static public const SPACE_SEPARATOR:CharCategory = new CharCategory(0x40 + 16); // Zs

        static public function fromCharCode(ch:uint):CharCategory {
            var cp:uint = ch;
            if (cp >> 16 !== 0)
                return smpPlaneAgainst(cp, 0);
            else {
                const start:uint =
                    ! ( cp >> 8 )                           ? 0   :
                      ( cp < 0x376   && cp >= 0x100 )       ? 218 :
                      ( cp < 0x800   && cp >= 0x376 )       ? 1219 :
                      ( cp < 0x1000  && cp >= 0x800 )       ? 2323 :
                      ( cp < 0x2016  && cp >= 0x1000 )      ? 3643 :
                      ( cp < 0x3000  && cp >= 0x2016 )      ? 5688 :
                      ( cp < 0x4E00  && cp >= 0x3000 )      ? 7166 :
                      ( cp < 0xA000  && cp >= 0x4E00 )      ? 7452 :
                      ( cp < 0xAC00  && cp >= 0xA000 )      ? 7458 :
                      ( cp < 0xF900  && cp >= 0xAC00 )      ? 8790 : 8827;

                return bmpPlaneAgainst(cp, start);
            }
        }

        public function CharCategory(value:uint)
        {
            this._value = value;
            _categories[value] = this;
        }

        public function valueOf():uint
        {
            return this._value;
        }

        public function get isOther():Boolean
        {
            return !(this.valueOf() >> 4)
        }

        public function isLetter():Boolean
        {
            return this.valueOf() >> 4 === 1
        }

        public function isMark():Boolean
        {
            return this.valueOf() >> 5 === 1
        }

        public function isNumber():Boolean
        {
            return this.valueOf() >> 6 === 1 && this.valueOf() < CONNECTOR_PUNCTUATION.valueOf();
        }

        public function isPunctuation():Boolean
        {
            return this.valueOf() >> 6 === 1 && this.valueOf() > OTHER_NUMBER.valueOf() && this.valueOf() < CURRENCY_SYMBOL.valueOf();
        }

        public function isSymbol():Boolean
        {
            return this.valueOf() >> 6 === 1 && this.valueOf() > OTHER_PUNCTUATION.valueOf() && this.valueOf() < LINE_SEPARATOR.valueOf();
        }

        public function isSeparator():Boolean
        {
            return this.valueOf() >> 6 === 1 && this.valueOf() > OTHER_SYMBOL.valueOf();
        }

        static private function bmpPlaneAgainst(cp:uint, start:uint):CharCategory
        {
            bmpPlane.position = start
            var lead:uint
            while (bmpPlane.position !== bmpPlane.length)
            {
                lead = bmpPlane.readUnsignedByte()
                if (lead >> 7 === 1)
                {
                    lead &= 0x7F
                    if (cp === bmpPlane.readUnsignedShort()) return _categories[lead]
                }
                else
                {
                    if (cp <  bmpPlane.readUnsignedShort()) break 
                    if (cp <= bmpPlane.readUnsignedShort()) return _categories[lead]
                }
            }
            return NOT_ASSIGNED_OTHER
        }

        static private function smpPlaneAgainst(cp:uint, start:uint):CharCategory {
            smpPlane.position = start
            var lead:uint
            while (smpPlane.position !== smpPlane.length) {
                lead = smpPlane.readUnsignedByte()
                if (lead >> 7 === 1) {
                    lead &= 0x7F
                    if (cp === readUint24(smpPlane)) return _categories[lead]
                } else {
                    if (cp <  readUint24(smpPlane)) break
                    if (cp <= readUint24(smpPlane)) return _categories[lead]
                }
            }
            return NOT_ASSIGNED_OTHER
        }

        static private function readUint24(ba:ByteArray):uint {
            return ba.readUnsignedShort()
                 | (ba.readUnsignedByte() << 16)
        }
    }
}