package dsc.verification {
	import dsc.semantics.*;

	public final class VerificationContext {
		public var flags:uint;
		public var phase:VerificationPhase;
		public var expectedType:Symbol;
		public var reportConstantExpressionErrors:Boolean = true;
		public var turnObservables:Boolean;

		static public function withFlags(flags:uint):VerificationContext {
			var r:VerificationContext = new VerificationContext;
			return r.flags = flags, r;
		}

		static public function withExpectedType(type:Symbol):VerificationContext {
			var r:VerificationContext = new VerificationContext;
			return r.expectedType = type, r;
		}

		static public function withPhase(phase:VerificationPhase):VerificationContext {
			var r:VerificationContext = new VerificationContext;
			return r.phase = phase, r;
		}

		public function clone():VerificationContext {
			var context:VerificationContext = new VerificationContext;
			context.phase = phase;
			context.reportConstantExpressionErrors = reportConstantExpressionErrors;
			return context;
		}
	}
}