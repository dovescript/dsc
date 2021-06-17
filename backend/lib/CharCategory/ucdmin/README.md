# UnicodeData.txt shrinker

This tool shrinks `UnicodeData.txt` (`in-xxx.txt` here) into a patterns binary for the `unicode-gc` library.

IN:
* `in-bmp.txt`: contains all Basic Multilingual Plane rows followed by a _last_ new line.
* `in-smp.txt`: contains all Supplementary Plane rows also followed by a _last_ new line.

OUT:
* `out-bmp-checks.txt`; skip points for `out-bmp.bin`.
* `out-bmp.bin`; sequence containing intervals and sole values; it follows the format: `00 u16 u16 01 u16 00 u16`, where values are in ascending order, like `#x00 <Cf> U+00-U+1F #x01 <Zs> U+20 etc.`.
* `out-smp.bin`; supplementary-plane version of `out-smp.bin`; uses `uint24` for everything.

It doesn't download/update `UnicodeData.txt` automatically. Find it [here](http://unicode.org/Public/).