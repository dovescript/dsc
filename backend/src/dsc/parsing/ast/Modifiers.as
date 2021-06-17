package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class Modifiers {
        static public const STATIC:uint = 1;
        static public const FINAL:uint = 2;
        static public const NATIVE:uint = 4;
        static public const OVERRIDE:uint = 8;
        static public const DYNAMIC:uint = 16;
    }
}