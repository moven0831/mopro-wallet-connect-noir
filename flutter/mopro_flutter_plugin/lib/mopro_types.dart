import 'dart:typed_data';

// Keep only the basic types that might be needed for Noir if required
// For now, keeping it minimal since Noir only uses Uint8List

/// Represents a proof with public inputs containing proof bytes and public inputs
class ProofWithPublicInputs {
  final Uint8List proof;
  final List<Uint8List> publicInputs;
  final int numPublicInputs;

  ProofWithPublicInputs({
    required this.proof,
    required this.publicInputs,
    required this.numPublicInputs,
  });

  /// Create ProofWithPublicInputs from a Map (for method channel deserialization)
  factory ProofWithPublicInputs.fromMap(Map<String, dynamic> map) {
    return ProofWithPublicInputs(
      proof: Uint8List.fromList(List<int>.from(map['proof'])),
      publicInputs: (map['publicInputs'] as List)
          .map((item) => Uint8List.fromList(List<int>.from(item)))
          .toList(),
      numPublicInputs: map['numPublicInputs'],
    );
  }

  /// Convert to Map (for method channel serialization)
  Map<String, dynamic> toMap() {
    return {
      'proof': proof.toList(),
      'publicInputs': publicInputs.map((item) => item.toList()).toList(),
      'numPublicInputs': numPublicInputs,
    };
  }
}
