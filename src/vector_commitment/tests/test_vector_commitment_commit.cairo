use integrity::{
    channel::channel::{Channel, ChannelTrait},
    vector_commitment::vector_commitment::{VectorCommitmentConfig, vector_commit, VectorCommitment}
};

#[test]
#[available_gas(9999999999)]
fn test_vector_commit() {
    let mut channel = ChannelTrait::new_with_counter(
        0x1b9182dce9dc1169fcd00c1f8c0b6acd6baad99ce578370ead5ca230b8fb8c6, 0x1
    );

    let unsent_commitment = 0x1e9b0fa29ebe52b9c9a43a1d44e555ce42da3199370134d758735bfe9f40269;

    let config = VectorCommitmentConfig {
        height: 0x9, n_verifier_friendly_commitment_layers: 0x64,
    };

    assert(
        vector_commit(
            ref channel, unsent_commitment, config
        ) == VectorCommitment { config: config, commitment_hash: unsent_commitment },
        'Invalid value'
    );

    assert(
        channel.digest == 0x1abd607dab09dede570ed131d9df0a1997e33735b11933c45dc84353df84259,
        'Invalid value'
    );
    assert(channel.counter == 0x0, 'Invalid value');
}
