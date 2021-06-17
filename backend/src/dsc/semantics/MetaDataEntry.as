package dsc.semantics
{
	import dsc.*;

	public final class MetaDataEntry {
		public var name:String;

		public var value:*;

		public var location:SourceLocation;

		public function MetaDataEntry(name:String, value:*, location:SourceLocation = null) {
			this.name = name;
			this.value = value;
			this.location = location;
		}
	}
}