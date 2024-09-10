use cairo_verifier::{
    stark::{StarkProof, StarkProofTrait},
    tests::{stone_proof_fibonacci, stone_proof_fibonacci_keccak}
};

#[cfg(feature: 'blake2s')]
#[test]
#[available_gas(99999999999)]
fn test_stark_proof_fibonacci_verify() {
    let SECURITY_BITS: felt252 = 50;

    let stark_proof = StarkProof {
        config: stone_proof_fibonacci::stark::config::get(),
        public_input: stone_proof_fibonacci::public_input::get(),
        unsent_commitment: stone_proof_fibonacci::stark::unsent_commitment::get(),
        witness: stone_proof_fibonacci::stark::witness::get(),
    };

    let security_bits = stark_proof.verify_full(security_bits, 0.try_into().unwrap(), 0.try_into().unwrap());
    assert(security_bits >= SECURITY_BITS, 'Security bits too low');
}

#[cfg(feature: 'keccak')]
#[test]
#[available_gas(9999999999)]
fn test_stark_proof_fibonacci_verify() {
    let SECURITY_BITS: u32 = 50;

    let stark_proof = StarkProof {
        config: stone_proof_fibonacci_keccak::stark::config::get(),
        public_input: stone_proof_fibonacci_keccak::public_input::get(),
        unsent_commitment: stone_proof_fibonacci_keccak::stark::unsent_commitment::get(),
        witness: stone_proof_fibonacci_keccak::stark::witness::get(),
    };

    let security_bits = stark_proof.verify_full(0.try_into().unwrap(), 0.try_into().unwrap());
    assert(security_bits >= SECURITY_BITS, 'Security bits too low');
}
