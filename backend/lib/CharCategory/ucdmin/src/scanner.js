const {GeneralCategory} = require('./category')

const Row = exports.Row = class Row {
    constructor() {
        this.codePoint = 0x00
        this.kind = Row.SOLE
        this.category = GeneralCategory.NOT_ASSIGNED_OTHER
    }

    copy(dest) {
        dest.codePoint = this.codePoint
        dest.kind      = this.kind
        dest.category  = this.category
    }
}

Row.NONE = 0
Row.SOLE = 1
Row.BEGINS_RANGE = 2
Row.ENDS_RANGE = 3

const Character = {
    parseHexDigit(ch) {
        return (ch >> 6 === 1) ?
            ch - 55 : ch - 0x30
    },
}

exports.Scanner = class {
    constructor(input) {
        this.input = input
        this.index = 0
        this.length = input.length
        this.entry = new Row
    }

    next() {
        if (this.index === this.length) {
            this.entry.kind = Row.NONE
        } else {
            this.entry.codePoint = this._getCodePoint()
            this.entry.kind      = this._getKind()
            this.entry.category  = this._getCategory()

            // Skip \n
            this.index = this.input.indexOf('\n', this.index) + 1
        }
    }

    _getCodePoint() {
        let len = (this.input.charCodeAt(this.index + 4) === 0x3B) ? 4
                : (this.input.charCodeAt(this.index + 5) === 0x3B) ? 5 : 6

        let bits = len * 4
        let val = 0
        let j = 0
        for (let i = bits; bits !== 0; bits -= 4, ++j) {
            const ch = Character.parseHexDigit(
                this.input.charCodeAt(this.index + j))
            val |= ch << (bits - 4)
        }

        this.index += len + 1
        return val
    }

    _getKind() {
        if (this.input.charCodeAt(this.index) === 0x3C) {
            for (let ch = 0;;) {
                ch = this.input.charCodeAt(++this.index)
                if (ch === 0x3B)
                    break
                else if (ch === 0x2C) {
                    this.index += 2
                    ch = this.input.charCodeAt(this.index)
                    if (ch === 0x46)
                        this.entry.kind = Row.BEGINS_RANGE
                    else if (ch === 0x4C)
                        this.entry.kind = Row.ENDS_RANGE
                    this.index = this.input.indexOf(';', this.index)
                }
            }
            ++this.index
        } else
            this.index = this.input.indexOf(';', this.index) + 1
        return Row.SOLE
    }

    _getCategory() {
        const s = this.input.slice(this.index, this.index + 2)
        this.index += 3
        switch (s) {
            // Lo, Ll, Lu (large)
            case 'Lo': return GeneralCategory.OTHER_LETTER
            case 'Ll': return GeneralCategory.LOWERCASE_LETTER
            case 'Lu': return GeneralCategory.UPPERCASE_LETTER

            // Mn (large)
            case 'Mn': return GeneralCategory.NON_SPACING_MARK

            // Sm (large)
            case 'Sm': return GeneralCategory.MATH_SYMBOL

            // Lt, Lm
            case 'Lt': return GeneralCategory.TITLECASE_LETTER
            case 'Mt': return GeneralCategory.MODIFIER_LETTER

            case 'Mc': return GeneralCategory.COMBINING_SPACING_MARK
            case 'Me': return GeneralCategory.ENCLOSING_MARK

            case 'Nd': return GeneralCategory.DECIMAL_NUMBER
            case 'Nl': return GeneralCategory.LETTER_NUMBER
            case 'No': return GeneralCategory.OTHER_NUMBER

            case 'Pc': return GeneralCategory.CONNECTOR_PUNCTUATION
            case 'Pd': return GeneralCategory.DASH_PUNCTUATION
            case 'Ps': return GeneralCategory.OPEN_PUNCTUATION
            case 'Pe': return GeneralCategory.CLOSE_PUNCTUATION
            case 'Pi': return GeneralCategory.INITIAL_QUOTE_PUNCTUATION
            case 'Pf': return GeneralCategory.FINAL_QUOTE_PUNCTUATION
            case 'Po': return GeneralCategory.OTHER_PUNCTUATION

            case 'Sc': return GeneralCategory.CURRENCY_SYMBOL
            case 'Sk': return GeneralCategory.MODIFIER_SYMBOL
            case 'So': return GeneralCategory.OTHER_SYMBOL

            case 'Zl': return GeneralCategory.LINE_SEPARATOR
            case 'Zp': return GeneralCategory.PARAGRAPH_SEPARATOR
            case 'Zs': return GeneralCategory.SPACE_SEPARATOR

            case 'Cc': return GeneralCategory.CONTROL_OTHER
            case 'Cf': return GeneralCategory.FORMAT_OTHER
            case 'Co': return GeneralCategory.PRIVATE_USE_OTHER
            case 'Cs': return GeneralCategory.SURROGATE_OTHER
            case 'Cn': return GeneralCategory.NOT_ASSIGNED_OTHER
        }
        return GeneralCategory.NOT_ASSIGNED_OTHER
    }
}