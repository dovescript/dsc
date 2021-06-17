package dsc.verification {
	/**
	 * @private
	 */
	internal final class PhaseDistributor {
		private var verifier:Verifier;
		private var phase:VerificationPhase = VerificationPhase.DECLARATION_1;

		public function PhaseDistributor(verifier:Verifier) {
			this.verifier = verifier;
		}

		public function get hasRemaining():Boolean {
			return !!phase
		}

		public function nextPhase():void { phase = VerificationPhase.valueOf(phase.valueOf() + 1) }

		public function verify(directives:Array):void {
			verifier.verifyDirectives(directives, VerificationContext.withPhase(phase));
		}
	}
}