package com.siteblade.intl {
    import com.siteblade.util.Promise;
    import com.siteblade.util.StringHelpers;
    import flash.errors.IOError;
    import flash.filesystem.*;
    import flash.utils.Dictionary;

    public final class Translator {
        private var _assetPath:String = '';
        private var _assetRoots:Array = [];
        private var _assetLoaderType:String = '';
        private var _cleanAssets:Boolean;
        private var _language:Language;
        private var _assets:Dictionary = new Dictionary;

        public function Translator(options:* = undefined) {
            this.config(options);
        }

        public function config(options:*) {
            options ||= {};
            _assetPath = options.assets.path || '';
            _assetRoots = options.assets.roots || [];
            _assetLoaderType = options.assets.loaderType || 'fileSystem';
            _cleanAssets = !!options.assets.clean;
        }

        public function getLanguage():Language {
            return _language;
        }

        public function setLanguage(language:Language):Promise {
            this._language = language;
            if (_cleanAssets) {
                var k:Array = [];
                var l:Language;
                if (language)
                    for (l = language; l; l = l.fallback)
                        k.push(l);
                for (l in _assets)
                    if (k.indexOf(l) == -1)
                        delete _assets[l];
            }
            var translator:Translator = this;
            return new Promise(function(resolve, reject) {
                translator.loadAssets()
                    .done(function(data) { resolve(data); })
                    .fail(function(error) { reject(error); });
            });
        }

        public function loadAssets():Promise {
            if (!_language)
                return new Promise(function(resolve, reject) { resolve(undefined); });
            return new Promise(function(resolve, reject) {
                loadLanguage(_language);
                function loadLanguage(l) {
                    _runAssetLoader(l)
                        .done(function(_) {
                            var nextL:Language = l.fallback;
                            if (nextL)
                                loadLanguage(nextL);
                            else resolve();
                        })
                        .fail(function(error) { resolve(error) });
                }
            });
        }

        private function _runAssetLoader(language:Language):Promise {
            if (_assetLoaderType == 'fileSystem')
                return _runFileSystemAssetLoader(language);
            else throw new Error('Unimplemented loader type');
        }

        private function _runFileSystemAssetLoader(language:Language):Promise {
            var rootDirectory:File = File.applicationDirectory.resolvePath(_assetPath);
            var roots:Array = _assetRoots;
            var translator:Translator = this;
            return new Promise(function(resolve, reject) {
                function loadRoot(index:uint):void {
                    if (index >= roots.length) {
                        resolve();
                        return;
                    }
                    var root:String = roots[index];
                    var file:File = rootDirectory.resolvePath(language.toString() + "/" + root + ".json");
                    var stream:FileStream = new FileStream;
                    try {
                        stream.open(file, "read");
                        var data:* = JSON.parse(stream.readUTFBytes(file.size));
                        translator._assignAssets(language, root, data);
                        loadRoot(index + 1);
                    }
                    catch (error:IOError) {
                        reject(error);
                    }
                }
                loadRoot(0);
            });
        }

        public function t(id:String, variables:* = undefined, option:* = undefined):String {
            if (!_language)
                return id;

            if (typeof option == 'number')
                id += option > 0 ? 'Plural' : option == 0 ? 'Empty' : 'Single';
            else if (option is Gender)
                id += option == Gender.MALE ? 'Male' : 'Female';

            var splitId:Array = id.split('.');
            for (var l:Language = _language; l; l = l.fallback) {
                var message:String = this._resolveId(_assets[l], splitId);
                if (message)
                    return this._applyMessage(message, variables, option);
            }
            return id;
        }

        /**
         * Returns a clone of the Translator, which shares the same
         * resources.
         */
        public function clone():Translator {
            var t:Translator = new Translator({
                assets: {
                    path: _assetPath,
                    roots: _assetRoots,
                    loaderType: _assetLoaderType,
                    clean: false
                }
            });
            t._language = _language;
            t._assets = _assets;
            return t;
        }

        private function _resolveId(object:*, splitId:Array):String {
            const l:uint = splitId.length;
            if (!object)
                return null;
            for (var i:uint = 0; i != l; ++i) {
                object = object[splitId[i]];
                if (object === undefined)
                    return null;
            }
            return typeof object == 'string' ? object : null;
        }

        private function _applyMessage(message:String, variables:*, option:*):String {
            if (typeof option == 'number') {
                variables ||= {};
                variables.amount = option;
            }
            var r:String = message;
            if (variables) r = StringHelpers.apply(r, variables);
            return r;
        }

        private function _assignAssets(language:Language, root:String, data:*):void {
            var r:* = _assets[language] ||= {};
            var idSplit:Array = root.split('.');
            for (var i:uint = 0; i != idSplit.length - 1; ++i)
                r[idSplit[i]] ||= {};
            r[idSplit[idSplit.length - 1]] = data;
        }
    }
}