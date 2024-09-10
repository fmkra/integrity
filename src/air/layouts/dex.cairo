mod autogenerated;
mod constants;
mod global_values;
mod public_input;
mod traces;
#[cfg(feature: 'split')]
mod contract;

use cairo_verifier::{
    air::{
        constants::{SHIFT_POINT_X, SHIFT_POINT_Y, StarkCurve},
        layouts::dex::{
            global_values::{GlobalValues, InteractionElements, EcPoint, EcdsaSigConfig},
            public_input::DexPublicInputImpl,
            constants::{
                PUBLIC_MEMORY_STEP, PEDERSEN_BUILTIN_RATIO, ECDSA_BUILTIN_RATIO,
                ECDSA_BUILTIN_REPETITIONS, PEDERSEN_BUILTIN_REPETITIONS, segments,
            },
        },
        air::{AIRComposition, AIROods}, diluted::get_diluted_product,
        periodic_columns::{eval_pedersen_x, eval_pedersen_y, eval_ecdsa_x, eval_ecdsa_y},
        public_input::{PublicInput, get_public_memory_product_ratio}
    },
    common::{math::{Felt252Div, Felt252PartialOrd, pow}, asserts::assert_range_u128}
};
use starknet::ContractAddress;

#[cfg(feature: 'monolith')]
use cairo_verifier::air::layouts::dex::autogenerated::{
    eval_composition_polynomial_inner as eval_composition_polynomial_inner_,
    eval_oods_polynomial_inner as eval_oods_polynomial_inner_,
};

#[cfg(feature: 'monolith')]
fn eval_composition_polynomial_inner(
    mask_values: Span<felt252>,
    constraint_coefficients: Span<felt252>,
    point: felt252,
    trace_generator: felt252,
    global_values: GlobalValues,
    contract_address: ContractAddress,
) -> felt252 {
    eval_composition_polynomial_inner_(
        mask_values, constraint_coefficients, point, trace_generator, global_values
    )
}

#[cfg(feature: 'monolith')]
fn eval_oods_polynomial_inner(
    column_values: Span<felt252>,
    oods_values: Span<felt252>,
    constraint_coefficients: Span<felt252>,
    point: felt252,
    oods_point: felt252,
    trace_generator: felt252,
    contract_address: ContractAddress,
) -> felt252 {
    eval_oods_polynomial_inner_(
        column_values, oods_values, constraint_coefficients, point, oods_point, trace_generator,
    )
}

#[cfg(feature: 'split')]
use cairo_verifier::air::layouts::dex::contract::{
    ILayoutCompositionContractDispatcher, ILayoutCompositionContractDispatcherTrait,
    ILayoutOodsContractDispatcher, ILayoutOodsContractDispatcherTrait,
};

#[cfg(feature: 'split')]
fn eval_composition_polynomial_inner(
    mask_values: Span<felt252>,
    constraint_coefficients: Span<felt252>,
    point: felt252,
    trace_generator: felt252,
    global_values: GlobalValues,
    contract_address: ContractAddress,
) -> felt252 {
    ILayoutCompositionContractDispatcher { contract_address }
        .eval_composition_polynomial_inner(
            mask_values, constraint_coefficients, point, trace_generator, global_values
        )
}

#[cfg(feature: 'split')]
fn eval_oods_polynomial_inner(
    column_values: Span<felt252>,
    oods_values: Span<felt252>,
    constraint_coefficients: Span<felt252>,
    point: felt252,
    oods_point: felt252,
    trace_generator: felt252,
    contract_address: ContractAddress,
) -> felt252 {
    ILayoutOodsContractDispatcher { contract_address }
        .eval_oods_polynomial_inner(
            column_values, oods_values, constraint_coefficients, point, oods_point, trace_generator,
        )
}

impl DexAIRCompositionImpl of AIRComposition<InteractionElements, PublicInput> {
    fn eval_composition_polynomial(
        interaction_elements: InteractionElements,
        public_input: @PublicInput,
        mask_values: Span<felt252>,
        constraint_coefficients: Span<felt252>,
        point: felt252,
        trace_domain_size: felt252,
        trace_generator: felt252,
        contract_address: ContractAddress,
    ) -> felt252 {
        let memory_z = interaction_elements.memory_multi_column_perm_perm_interaction_elm;
        let memory_alpha = interaction_elements.memory_multi_column_perm_hash_interaction_elm0;

        // Public memory
        let public_memory_column_size = trace_domain_size / PUBLIC_MEMORY_STEP;
        assert_range_u128(public_memory_column_size);
        let public_memory_prod_ratio = get_public_memory_product_ratio(
            public_input, memory_z, memory_alpha, public_memory_column_size
        );

        // Periodic columns
        let n_steps = pow(2, *public_input.log_n_steps);
        let n_pedersen_hash_copies = n_steps
            / (PEDERSEN_BUILTIN_RATIO * PEDERSEN_BUILTIN_REPETITIONS);
        assert_range_u128(n_pedersen_hash_copies);
        let pedersen_point = pow(point, n_pedersen_hash_copies);
        let pedersen_points_x = eval_pedersen_x(pedersen_point);
        let pedersen_points_y = eval_pedersen_y(pedersen_point);

        let n_ecdsa_signature_copies = n_steps / (ECDSA_BUILTIN_RATIO * ECDSA_BUILTIN_REPETITIONS);
        assert_range_u128(n_ecdsa_signature_copies);
        let ecdsa_point = pow(point, n_ecdsa_signature_copies);
        let ecdsa_generator_points_x = eval_ecdsa_x(ecdsa_point);
        let ecdsa_generator_points_y = eval_ecdsa_y(ecdsa_point);

        let global_values = GlobalValues {
            trace_length: trace_domain_size,
            initial_pc: *public_input.segments.at(segments::PROGRAM).begin_addr,
            final_pc: *public_input.segments.at(segments::PROGRAM).stop_ptr,
            initial_ap: *public_input.segments.at(segments::EXECUTION).begin_addr,
            final_ap: *public_input.segments.at(segments::EXECUTION).stop_ptr,
            initial_pedersen_addr: *public_input.segments.at(segments::PEDERSEN).begin_addr,
            initial_range_check_addr: *public_input.segments.at(segments::RANGE_CHECK).begin_addr,
            initial_ecdsa_addr: *public_input.segments.at(segments::ECDSA).begin_addr,
            range_check_min: *public_input.range_check_min,
            range_check_max: *public_input.range_check_max,
            offset_size: 0x10000, // 2**16
            half_offset_size: 0x8000, // 2**15
            pedersen_shift_point: EcPoint { x: SHIFT_POINT_X, y: SHIFT_POINT_Y },
            ecdsa_sig_config: EcdsaSigConfig {
                alpha: StarkCurve::ALPHA,
                beta: StarkCurve::BETA,
                shift_point: EcPoint { x: SHIFT_POINT_X, y: SHIFT_POINT_Y },
            },
            pedersen_points_x,
            pedersen_points_y,
            ecdsa_generator_points_x,
            ecdsa_generator_points_y,
            memory_multi_column_perm_perm_interaction_elm: memory_z,
            memory_multi_column_perm_hash_interaction_elm0: memory_alpha,
            range_check16_perm_interaction_elm: interaction_elements
                .range_check16_perm_interaction_elm,
            memory_multi_column_perm_perm_public_memory_prod: public_memory_prod_ratio,
            range_check16_perm_public_memory_prod: 1,
        };

        eval_composition_polynomial_inner(
            mask_values,
            constraint_coefficients,
            point,
            trace_generator,
            global_values,
            contract_address,
        )
    }
}

impl DexAIROodsImpl of AIROods {
    fn eval_oods_polynomial(
        column_values: Span<felt252>,
        oods_values: Span<felt252>,
        constraint_coefficients: Span<felt252>,
        point: felt252,
        oods_point: felt252,
        trace_generator: felt252,
        contract_address: ContractAddress,
    ) -> felt252 {
        eval_oods_polynomial_inner(
            column_values,
            oods_values,
            constraint_coefficients,
            point,
            oods_point,
            trace_generator,
            contract_address,
        )
    }
}
