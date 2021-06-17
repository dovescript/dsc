package dsc.util {
    public final class PathHelpers {
        public static function join(a:String, b:String, ...other):String {
            var r:String = a.replace(/\/$/, '') + '/' + b.replace(/^\//, '');
            if (other.length > 0) {
                var args2:Array = [r];
                for each (var arg2:String in other) args2.push(arg2);
                return join.apply(null, args2);
            }
            return r;
        }
    }
}