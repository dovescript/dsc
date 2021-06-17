package com.siteblade.util {

    public final class StringHelpers {

        static public function apply(str:String, ...rest):String {
            while (rest[0] is Array) rest = rest[0];
            var variables:* = undefined;
            if (rest.length == 1 && !(rest[0] is Array)) variables = rest[0];

            return str.replace(/\$([a-zA-Z0-9]+|\$|\d+)/g, function(_, argument) {
                if (argument == "$") return "$";
                if (!variables) {
                    var i:uint = parseInt(argument);
                    return i <= rest.length ? rest[i - 1] : "undefined";
                }
                else return variables[argument];
            });
        }
    }
}