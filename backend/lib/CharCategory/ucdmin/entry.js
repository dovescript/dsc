const path = require('path')
    , fs   = require('fs')

const {GeneralCategory} = require('./src/category')
    , {Scanner, Row}    = require('./src/scanner')

const BMP_CHECKPOINTS = [
    0x100,
    0x376,
    0x800,
    0x1000,
    0x2016,
    0x3000,
    0x4E00,
    0xA000,
    0xAC00,
    0xF900,
    0,        // Null
]

function bmpToBin() {
    const out = Buffer.allocUnsafe(20000)
    let i = 0

    const checks = []
    let checkIndex = 0
      , checkCode = BMP_CHECKPOINTS[0]

    const scanner = new Scanner(fs.readFileSync(path.join(__dirname, 'inputBMP.txt'), 'binary'))
    const {entry: row} = scanner
        , prev = new Row
    scanner.next()

    for (;;) {
        if (row.kind === Row.SOLE) {
            // If congruent with next, that's an interval.
            const cat = row.category
            const ii = row.codePoint
            let ij = ii

            for (;;) {
                row.copy(prev)
                scanner.next()
                if (areCongruent(cat, prev, row)) ++ij
                else break
            }

            // Add to `generatedBMPCheckpoints.txt`
            if (ii === checkCode) {
                checks.push(i)
                checkCode = BMP_CHECKPOINTS[++checkIndex]
            }

            if (ii === ij) {
                out.writeUInt8(cat | 0x80, i++)
                out.writeUInt16LE(ii, i)
                i += 2
            } else {
                out.writeUInt8(cat, i++)
                out.writeUInt16LE(ii, i)
                out.writeUInt16LE(ij, i += 2)
                i += 2
            }
        } else if (row.kind === Row.BEGINS_RANGE) {
            row.copy(prev)
            scanner.next()

            out.writeUInt8(prev.category, i++)
            out.writeUInt16LE(prev.codePoint, i)
            out.writeUInt16LE(row.codePoint, i += 2)
            i += 2
            scanner.next()
        } else break
    }

    fs.writeFileSync(path.join(__dirname, 'output/generatedBMP.bin'), out.slice(0, i))

    // generatedBMPCheckpoints.txt

    const readableChecks = []
    let j = 0

    for (let addr of checks)
        readableChecks.push(`U+${BMP_CHECKPOINTS[j++].toString(16).toUpperCase()} = addr ${addr}`)

    fs.writeFileSync(path.join(__dirname, 'output/generatedBMPCheckpoints.txt'), readableChecks.join('\n'))
}

function smpToBin() {
    const out = Buffer.alloc(20000)
    let i = 0

    const scanner = new Scanner(fs.readFileSync(path.join(__dirname, 'inputSP.txt'), 'binary'))
    const {entry: row} = scanner
        , prev = new Row
    scanner.next()

    for (;;) {
        if (row.kind === Row.SOLE) {
            // If congruent with next, that's an interval.

            const cat = row.category
            const ii = row.codePoint
            let ij = ii

            for (;;) {
                row.copy(prev)
                scanner.next()
                if (areCongruent(cat, prev, row)) ++ij
                else break
            }

            if (ii === ij) {
                out.writeUInt8(cat | 0x80, i++)
                writeUInt24LE(out, ii, i)
                i += 3
            } else {
                out.writeUInt8(cat, i++)
                writeUInt24LE(out, ii, i)
                writeUInt24LE(out, ij, i += 3)
                i += 3
            }
        } else if (row.kind === Row.BEGINS_RANGE) {
            row.copy(prev)
            scanner.next()

            out.writeUInt8(prev.category, i++)
            writeUInt24LE(out, prev.codePoint, i)
            writeUInt24LE(out, row.codePoint, i += 3)
            i += 3
            scanner.next()
        } else break
    }

    fs.writeFileSync(path.join(__dirname, 'output/generatedSP.bin'), out.slice(0, i))
}

function writeUInt24LE(buf, value, index) {
    buf.writeUInt16LE(value & 0xFFFF, index)
    buf.writeUInt8(value >> 16, index + 2)
}

function areCongruent(cat, prev, row) {
    return row.kind      === Row.SOLE
        && row.category  === cat
        && row.codePoint === prev.codePoint + 1
}

bmpToBin()
smpToBin()