exports.GeneralCategory = {
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