const {File,FileStream} = nodejs.filesystem

const BMP = new ByteArray
    , SP  = new ByteArray

var fileStream = new FileStream
fileStream.open(new File(__dirname).resolvePath('generatedBMP.bin'), 'read')
fileStream.readBytes(BMP)

fileStream.open(new File(__dirname).resolvePath('generatedSP.bin'), 'read')
fileStream.readBytes(SP)
fileStream.close()

const UnicodeCategory =
{
    CONTROL_OTHER             : 0x00, // Cc
    FORMAT_OTHER              : 0x01, // Cf
    PRIVATE_USE_OTHER         : 0x02, // Co
    SURROGATE_OTHER           : 0x03, // Cs
    NOT_ASSIGNED_OTHER        : 0x04, // Cn

    LOWERCASE_LETTER          : 0x10,     // Ll
    MODIFIER_LETTER           : 0x10 + 1, // Lm
    OTHER_LETTER              : 0x10 + 2, // Lo
    TITLECASE_LETTER          : 0x10 + 3, // Lt
    UPPERCASE_LETTER          : 0x10 + 4, // Lu

    COMBINING_SPACING_MARK    : 0x20,     // Mc
    ENCLOSING_MARK            : 0x20 + 1, // Me
    NON_SPACING_MARK          : 0x20 + 2, // Mn

    DECIMAL_NUMBER            : 0x40,      // Nd
    LETTER_NUMBER             : 0x40 + 1,  // Nl
    OTHER_NUMBER              : 0x40 + 2,  // No

    CONNECTOR_PUNCTUATION     : 0x40 + 3,  // Pc
    DASH_PUNCTUATION          : 0x40 + 4,  // Pd
    OPEN_PUNCTUATION          : 0x40 + 5,  // Ps
    CLOSE_PUNCTUATION         : 0x40 + 6,  // Pe
    INITIAL_QUOTE_PUNCTUATION : 0x40 + 7,  // Pi
    FINAL_QUOTE_PUNCTUATION   : 0x40 + 8,  // Pf
    OTHER_PUNCTUATION         : 0x40 + 9,  // Po

    CURRENCY_SYMBOL           : 0x40 + 10, // Sc
    MODIFIER_SYMBOL           : 0x40 + 11, // Sk
    MATH_SYMBOL               : 0x40 + 12, // Sm
    OTHER_SYMBOL              : 0x40 + 13, // So

    LINE_SEPARATOR            : 0x40 + 14, // Zl
    PARAGRAPH_SEPARATOR       : 0x40 + 15, // Zp
    SPACE_SEPARATOR           : 0x40 + 16, // Zs
}

UnicodeCategory.fromString = function(s)
{
    return this.from(s.codePointAt(0))
}

UnicodeCategory.from = function(cp)
{
    if (cp >> 16 !== 0)
        return this.SPAgainst(cp, 0)
    else
    {
        const start =
            ! ( cp >> 8 )                           ? 0   :
              ( cp < 0x376   && cp >= 0x100 )       ? 218 :
              ( cp < 0x800   && cp >= 0x376 )       ? 1219 :
              ( cp < 0x1000  && cp >= 0x800 )       ? 2323 :
              ( cp < 0x2016  && cp >= 0x1000 )      ? 3643 :
              ( cp < 0x3000  && cp >= 0x2016 )      ? 5688 :
              ( cp < 0x4E00  && cp >= 0x3000 )      ? 7166 :
              ( cp < 0xA000  && cp >= 0x4E00 )      ? 7452 :
              ( cp < 0xAC00  && cp >= 0xA000 )      ? 7458 :
              ( cp < 0xF900  && cp >= 0xAC00 )      ? 8790 : 8827

        return this.BMPAgainst(cp, start)
    }
}

UnicodeCategory.isLetter = function(gc)
{
    return gc >> 4 === 1
}

UnicodeCategory.BMPAgainst = function(cp, start)
{
    var i = 0
    var lead = 0
    while (i < BMP.length)
    {
        lead = BMP.readUInt8(i++)
        if (lead >> 7 === 1)
        {
            lead &= 0x7F
            if (cp === BMP.readUInt16LE(i))
                return lead
            i += 2
        }
        else
        {
            if (cp <  BMP.readUInt16LE(i))
                break
            i += 2
            if (cp <= BMP.readUInt16LE(i))
                return lead
            i += 2
        }
    }
    return this.NOT_ASSIGNED_OTHER
}

UnicodeCategory.SPAgainst = function(cp, start)
{
    var i = 0
    var lead = 0
    while (i < SP.length)
    {
        lead = SP.readUInt8(i++)
        if (lead >> 7 === 1)
        {
            lead &= 0x7F
            if (cp === this._readUint24(SP, i))
                return lead
            i += 3
        }
        else
        {
            if (cp <  this._readUint24(SP, i))
                break
            i += 3
            if (cp <= this._readUint24(SP, i))
                return lead
            i += 3
        }
    }
    return this.NOT_ASSIGNED_OTHER
}

UnicodeCategory._readUint24 = function(ba, i)
{
    return ba.readUInt16LE(i)
        | (ba.readUInt8(i) << 16)
}

global.UnicodeCategory = UnicodeCategory