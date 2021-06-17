package dsc.targets.js.sourcemap {
    internal class MappingList {
        private static function generatedPositionAfter(mappingA:*, mappingB:*):Boolean {
            const lineA:Number = mappingA.generatedLine;
            const lineB:Number = mappingB.generatedLine;
            const columnA:Number = mappingA.generatedColumn;
            const columnB:Number = mappingB.generatedColumn;
            return (
                lineB > lineA ||
                (lineB == lineA && columnB >= columnA) ||
                Util.compareByGeneratedPositionsInflated(mappingA, mappingB) <= 0
            );
        }

        private const _array:Array = [];
        private var _sorted:Boolean = true;
        private var _last:* = { generatedLine: -1, generatedColumn: 0 };

        public function MappingList() {
        }

        public function unsortedForEach(eachFn:Function, aThisArg:* = null):void {
            _array.forEach(eachFn, aThisArg);
        }

        public function add(aMapping:*):void {
            if (generatedPositionAfter(this._last, aMapping)) {
                this._last = aMapping;
                this._array.push(aMapping);
            } else {
                this._sorted = false;
                this._array.push(aMapping);
            }
        }

        public function toArray():Array {
            if (!this._sorted) {
                this._array.sort(util.compareByGeneratedPositionsInflated);
                this._sorted = true;
            }
            return this._array;
        }
    }
}