package dsc.semantics {

	import dsc.*;

	import flash.utils.Proxy;

	import flash.utils.flash_proxy;

	public final class MetaData extends Proxy {

		public var name:String;

		public const entries:Array = [];

		private var _location:SourceLocation;

		public function MetaData(name:String, location:SourceLocation) {
			this.name = name;
			_location = location;
		}

		public function get location():SourceLocation {
			return _location;
		}

		public function findEntry(name:String):MetaDataEntry {
			for each (var e:MetaDataEntry in entries)
				if (e.name == name)
					return e;
			return null;
		}

		override flash_proxy function getProperty(name:*):* { return findEntry(name) }
	}
}