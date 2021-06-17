package dsc.targets.js.sourcemap {
    internal final class Util {
        public static function getArg(aArgs:*, aName:String, aDefaultValue:* = undefined):* {
            if (aName in aArgs)
                return aArgs[aName];
            else if (aDefaultValue !== undefined)
                return aDefaultValue;
            throw new Error('"' + aName + '" is a required argument.');
        }

        public static function compareByGeneratedPositionsInflated(mappingA:*, mappingB:*):Number {
            var cmp:Number = mappingA.generatedLine - mappingB.generatedLine;
            if (cmp !== 0)
                return cmp;

            cmp = mappingA.generatedColumn - mappingB.generatedColumn;
            if (cmp !== 0)
                return cmp;

            cmp = strcmp(mappingA.source, mappingB.source);
            if (cmp !== 0)
                return cmp;

            cmp = mappingA.originalLine - mappingB.originalLine;
            if (cmp !== 0)
                return cmp;

            cmp = mappingA.originalColumn - mappingB.originalColumn;
            if (cmp !== 0)
                return cmp;

            return strcmp(mappingA.name, mappingB.name);
        }

        public static function strcmp(aStr1:String, aStr2:String):Number {
            if (aStr1 === aStr2)
                return 0;

            if (aStr1 === null)
                return 1; // aStr2 !== null

            if (aStr2 === null)
                return -1; // aStr1 !== null

            if (aStr1 > aStr2)
                return 1;

            return -1;
        }

        private static const ABSOLUTE_SCHEME:RegExp = /^[A-Za-z0-9\+\-\.]+:/;

        private static function getURLType(url:String):String {
            if (url[0] === "/") {
                if (url[1] === "/") return "scheme-relative";
                return "path-absolute";
            }
            return ABSOLUTE_SCHEME.test(url) ? "absolute" : "path-relative";
        }

        private static function relativeIfPossible(rootURL:String, targetURL:String) {
            const urlType:String = getURLType(rootURL);
            if (urlType !== getURLType(targetURL)) {
                return null;
            }

            const base:String = buildSafeBase(rootURL + targetURL);
            const root:URL = new URL(rootURL, base);
            const target:URL = new URL(targetURL, base);

            try {
                new URL("", target.toString());
            } catch (err) {
                // Bail if the URL doesn't support things being relative to it.
                // For example, data: and blob: URLs.
                return null;
            }

            if (
                target.getProtocol() !== root.getProtocol() ||
                target.getDomain() !== root.getDomain() ||
                target.getPort() !== root.getPort()
            ) {
                return null;
            }

            return computeRelativeURL(root, target);
        }

        private static function buildUniqueSegment(prefix:String, str:String):String {
            var id:Number = 0;
            do {
                const ident:String = prefix + (id++).toString();
                if (str.indexOf(ident) === -1) return ident;
            } while (true);
            return '';
        }

        private static function buildSafeBase(str:String):String {
            const maxDotParts:Number = str.split("..").length - 1;
            const segment:String = buildUniqueSegment("p", str);

            const PROTOCOL:String = 'http:';
            const PROTOCOL_AND_HOST:String = PROTOCOL + '//host';

            var base:String = PROTOCOL_AND_HOST + '/';
            for (let i = 0; i < maxDotParts; i++) {
                base += `${segment}/`;
            }
            return base;
        }
    }
}