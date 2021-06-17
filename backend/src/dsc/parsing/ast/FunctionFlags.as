package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class FunctionFlags {
        static public const GETTER:uint = 1;
        static public const SETTER:uint = 2;
        static public const CONSTRUCTOR:uint = 4;
        static public const YIELD:uint = 8;
        static public const AWAIT:uint = 16;
    }
}