package com.siteblade.util {
    public class Promise {
        private const _listeners:Array = [];
        private var _state:String = 'unresolved';
        private var _data:*;

        public function Promise(handler:Function) {
            handler(_resolve, _reject);
        }

        public function done(listener:Function):Promise {
            if (_state == 'resolved')
                listener(this._data);
            else if (_state == 'unresolved')
                _listeners.push(['done', listener]);
            return this;
        }

        public function fail(listener:Function):Promise {
            if (_state == 'rejected')
                listener(this._data);
            else if (_state == 'unresolved')
                _listeners.push(['fail', listener]);
            return this;
        }

        public function always(listener:Function):Promise {
            if (_state == 'unresolved')
                _listeners.push(['always', listener]);
            else listener();
            return this;
        }

        private function _resolve(data:* = undefined):void {
            if (_state != 'unresolved')
                throw new Error('Cannot invoke resolve() anymore.');
            _state = 'resolved';
            _data = data;
            for (var listener:Array in _listeners)
                if (listener[0] == 'done' || listener[0] == 'always')
                    listener[1](data);
        }

        private function _reject(error:* = undefined):void {
            if (_state != 'unresolved')
                throw new Error('Cannot invoke reject() anymore.');
            _state = 'rejected';
            _data = error;
            for (var listener:Array in _listeners)
                if (listener[0] == 'fail' || listener[0] == 'always')
                    listener[1](error);
        }
    }
}