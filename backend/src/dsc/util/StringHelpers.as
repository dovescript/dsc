package dsc.util {
    import com.siteblade.util.StringHelpers;

    public final class StringHelpers {
        public static function trim(str:String):String {
            var m:* = str.match(/^[ \t]+/),
                m2:* = str.match(/[ \t]+$/);
            return str.slice(m ? m[0].length : 0, str.length - (m2 ? m2[0].length : 0));
        }

        public static function apply(str:String, ...argumentsList):String {
            var argumentsList2:Array = [str];
            for each (var arg:* in argumentsList) argumentsList2.push(arg);
            return com.siteblade.util.StringHelpers.apply.apply(null, argumentsList2);
        }
    }
}