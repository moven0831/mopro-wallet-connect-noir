mod error;
pub use error::MoproError;

// Initializes the shared UniFFI scaffolding and defines the `MoproError` enum.
mopro_ffi::app!();

/// You can also customize the bindings by #[uniffi::export]
/// Reference: https://mozilla.github.io/uniffi-rs/latest/proc_macro/index.html
#[cfg_attr(feature = "uniffi", uniffi::export)]
pub fn mopro_hello_world() -> String {
    "Hello, World!".to_string()
}

/// Struct to hold split proof data
#[cfg_attr(feature = "uniffi", uniffi::Record, Debug, Clone)]
pub struct ProofWithPublicInputs {
    /// The proof without public inputs
    pub proof: Vec<u8>,
    /// The public inputs as an array of 32-byte values
    pub public_inputs: Vec<Vec<u8>>,
    /// The number of public inputs
    pub num_public_inputs: u32,
}

/// Get the number of public inputs for a given circuit
#[cfg_attr(feature = "uniffi", uniffi::export)]
pub fn get_num_public_inputs_from_circuit(circuit_path: String) -> u32 {
    // Read the JSON manifest of the circuit
    let circuit_txt = std::fs::read_to_string(circuit_path).unwrap();
    let circuit: serde_json::Value = serde_json::from_str(&circuit_txt).unwrap();
    let circuit_bytecode = circuit["bytecode"].as_str().unwrap().to_string();
    
    noir_rs::utils::get_num_public_inputs_from_circuit(&circuit_bytecode)
        .map(|size| size as u32)
        .unwrap_or(0)
}

/// Parse a proof into proof bytes and public inputs
#[cfg_attr(feature = "uniffi", uniffi::export)]
pub fn parse_proof_with_public_inputs(proof: Vec<u8>, num_public_inputs: u32) -> ProofWithPublicInputs {
    let parsed = noir_rs::utils::parse_proof_with_public_inputs(&proof, num_public_inputs as usize)
        .unwrap();

    ProofWithPublicInputs {
        proof: parsed.proof,
        public_inputs: parsed.public_inputs,
        num_public_inputs: parsed.num_public_inputs as u32,
    }
}

/// Combine proof and public inputs back into a single proof with public inputs
#[cfg_attr(feature = "uniffi", uniffi::export)]
pub fn combine_proof_and_public_inputs(proof: Vec<u8>, public_inputs: Vec<Vec<u8>>) -> Vec<u8> {
    noir_rs::utils::combine_proof_and_public_inputs(proof, public_inputs)
}

#[cfg(test)]
mod uniffi_tests {
    #[test]
    fn test_mopro_hello_world() {
        assert_eq!(super::mopro_hello_world(), "Hello, World!");
    }
}

// NOIR_TEMPLATE
// --- Noir Example of using Ultra Honk proving and verifying circuits ---

// Module containing the Noir circuit logic (Multiplier2)
mod noir;
pub use noir::{generate_noir_proof, get_noir_verification_key, verify_noir_proof,};

#[cfg(test)]
mod noir_tests {
    use super::noir::{generate_noir_proof, get_noir_verification_key, verify_noir_proof};
    use serial_test::serial;

    #[test]
    #[serial]
    fn test_noir_multiplier2() {
        let srs_path = "./test-vectors/noir/noir_multiplier2.srs".to_string();
        let circuit_path = "./test-vectors/noir/noir_multiplier2.json".to_string();
        let circuit_inputs = vec!["3".to_string(), "5".to_string()];
        let vk = get_noir_verification_key(
            circuit_path.clone(),
            Some(srs_path.clone()),
            true,  // on_chain (uses Keccak for Solidity compatibility)
            false, // low_memory_mode
        )
        .unwrap();

        let proof = generate_noir_proof(
            circuit_path.clone(),
            Some(srs_path.clone()),
            circuit_inputs.clone(),
            true, // on_chain (uses Keccak for Solidity compatibility)
            vk.clone(),
            false, // low_memory_mode
        )
        .unwrap();

        let valid = verify_noir_proof(
            circuit_path,
            proof,
            true, // on_chain (uses Keccak for Solidity compatibility)
            vk,
            false, // low_memory_mode
        )
        .unwrap();
        assert!(valid);
    }

    #[test]
    #[serial]
    fn test_noir_multiplier2_with_existing_vk() {
        let srs_path = "./test-vectors/noir/noir_multiplier2.srs".to_string();
        let circuit_path = "./test-vectors/noir/noir_multiplier2.json".to_string();
        let vk_path = "./test-vectors/noir/noir_multiplier2.vk".to_string();

        // read vk from file as Vec<u8>
        let vk = std::fs::read(vk_path).unwrap();

        let circuit_inputs = vec!["3".to_string(), "5".to_string()];

        let proof = generate_noir_proof(
            circuit_path.clone(),
            Some(srs_path),
            circuit_inputs,
            true, // on_chain (uses Keccak for Solidity compatibility)
            vk.clone(),
            false, // low_memory_mode
        )
        .unwrap();

        let valid = verify_noir_proof(
            circuit_path,
            proof,
            true, // on_chain (uses Keccak for Solidity compatibility)
            vk,
            false, // low_memory_mode
        )
        .unwrap();
        assert!(valid);
    }
}

