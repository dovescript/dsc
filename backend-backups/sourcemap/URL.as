// Code modified from Markus D.:
// https://stackoverflow.com/users/2538349/markus-d

package dsc.targets.js.sourcemap
{
    import flash.net.URLVariables;

    public class URL
    {
        protected var protocol:String = "";
        protected var domain:String = "";
        protected var port:int = 0;
        protected var path:String = "";
        protected var parameters:URLVariables;
        protected var bookmark:String = "";

        public function URL(url:String, base:String = null)
        {
            this.init(url);
        }

        protected function splitSingle(value:String, c:String):Object
        {
            var temp:Object = {first: value, second: ""};

            var pos:int = value.indexOf(c);
            if (pos > 0)
            {
                temp.first = value.substring(0, pos);
                temp.second = value.substring(pos + 1);
            }

            return temp;
        }

        protected function rtrim(value:String, c:String):String
        {
            while (value.substr(-1, 1) == c)
            {
                value = value.substr(0, -1);
            }

            return value;
        }

        protected function init(url:String):void
        {
            var o:Object;

            var urlExp:RegExp = /([a-z]+):\/\/(.+)/
            var urlPart:Array = urlExp.exec(url);
            var temp:Array;
            var rest:String;

            if (urlPart.length <= 1)
            {
                throw new Error("invalid url");
            }

            this.protocol = urlPart[1];
            rest = urlPart[2];

            o = this.splitSingle(rest, "#");
            this.bookmark = o.second;
            rest = o.first;

            o = this.splitSingle(rest, "?");
            o.second = this.rtrim(o.second, "&");

            this.parameters = new URLVariables();
            if (o.second != "")
            {
                try
                {
                    this.parameters.decode(o.second);
                }
                catch (e:Error)
                {
                    trace("Warning: cannot decode URL parameters. " + e.message + " " + o.second);
                }
            }
            rest = o.first

            o = this.splitSingle(rest, "/");
            if (o.second != "")
            {
                this.path = "/" + o.second;
            }
            rest = o.first;

            o = this.splitSingle(rest, ":");
            if (o.second != "")
            {
                this.port = parseInt(o.second);
            }
            else
            {
                switch (this.protocol)
                {
                case "https": 
                    this.port = 443;
                    break;
                case "http": 
                    this.port = 80;
                    break;
                case "ssh": 
                    this.port = 22;
                    break;
                case "ftp": 
                    this.port = 21;
                    break;
                default: 
                    this.port = 0;
                }
            }
            this.domain = o.first;
        }

        public function getDomain():String
        {
            return this.domain;
        }

        public function getProtocol():String
        {
            return this.protocol;
        }

        public function getPath():String
        {
            return this.path;
        }

        public function getPort():int
        {
            return this.port;
        }

        public function getBookmark():String
        {
            return this.bookmark;
        }

        public function getParameters():URLVariables
        {
            return this.parameters;
        }
    }
}