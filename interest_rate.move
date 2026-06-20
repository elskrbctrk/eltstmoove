module lend_config::interest_rate{

    use std::signer;
    use std::error;
    use lend_lib::math;
    use aptos_std::type_info::{type_name};
    use std::vector;
    use lend_lib::math::sqrt;
    // use lend_multisig::multisig;

    const EALREADY_PUBLISHED_FORMULAPARAM: u64 = 1;
    const ENOT_PUBLISHED_FORMULAPARAM: u64 = 2;
    const ENOT_ALLOWED: u64 = 3;
    const EALREADY_ADDED: u64 = 4;
    const ENOT_FOUND_FORMULA: u64 = 5;
    const ED_IS_A_WRONG_VALUE: u64 = 6;

    const SECS_OF_YEAR: u64 = 365 * 24 * 60 * 60;
    const EXTEND_INDEX: u128 = 10000000000;
    const DEFAULT_C: u64 = 8000;

    struct FormulaParam has copy, drop, store {
        ct: String,
        k: u64, // decimal: 2
        b: u64,  // decimal: 5

        a: u64,   // interest rate growth factor
        c: u64,   // decimal: 4
        d: u64,   // decimal: 5
        // todo: reserves
        reserves: u64  // reserves, extend 1000 times
    }

    struct Params has key, store {
        vals: vector<FormulaParam>
    }

    public entry fun initialize(account: &signer, ) {
        // multisig::validate_multisig();

        let account_addr = signer::address_of(account);
        assert!(account_addr == @lend_config_admin, error::permission_denied(ENOT_ALLOWED));
        assert!(!exists<Params>(account_addr), EALREADY_PUBLISHED_FORMULAPARAM);

        move_to(account, Params {
            vals: vector::empty()
        })
    }

    fun contains(params: &vector<FormulaParam>, ct: &String): (bool, u64) {
        let len = vector::length(params);
        let i = 0;
        while (i < len) {
            let param = vector::borrow(params, i);
            if (param.ct == *ct) {
                return (true, i)
            };
            i = i + 1
        };
        (false, 0)
    }

    fun validate_account(account: &signer) {
        let account_addr = signer::address_of(account);

        assert!(account_addr == @lend_config_admin, error::permission_denied(ENOT_ALLOWED));

        assert!(exists<Params>(account_addr), error::not_found(ENOT_PUBLISHED_FORMULAPARAM));
    }

    #[view]
    public fun get_params(account_addr: address): vector<FormulaParam> acquires Params {
        assert!(exists<Params>(account_addr), error::not_found(ENOT_PUBLISHED_FORMULAPARAM));

        borrow_global<Params>(account_addr).vals
    }

    public entry fun add<C>(account: &signer, k: u64, b: u64, a: u64, d: u64 ) acquires Params {
        // multisig::validate_multisig();

        validate_account(account);

        let params = borrow_global_mut<Params>(@lend_config_admin);

        let ty_name = type_name<C>();

        let (e, _i) = contains(&params.vals, &ty_name);

        if (e) {
            abort EALREADY_ADDED
        } else {
            assert_c_d(k, b, DEFAULT_C, d);

            vector::push_back(&mut params.vals, FormulaParam {
                ct: ty_name,
                k, // decimal: 2
                b, // decimal: 6

                a,
                c: DEFAULT_C,
                d, // decimal: 6
                reserves: 0
            })
        }
    }

    fun assert_c_d(k: u64, b: u64, c: u64, d: u64) {
        let r = k * c + b ;

        assert!(r <= d, ED_IS_A_WRONG_VALUE);
    }

    public entry fun set_k_b<C>(account: &signer, k: u64, b: u64, d: u64) acquires Params {
        // multisig::validate_multisig();

        validate_account(account);

        let params = borrow_global_mut<Params>(@lend_config_admin);

        let ty_name = type_name<C>();

        let (e, i) = contains(&params.vals, &ty_name);
        if (e) {
            let formula = vector::borrow_mut(&mut params.vals, i);
            assert_c_d(k, b, formula.c, d);
            formula.k = k;
            formula.d = d;
            formula.b = b;
        } else {
            abort ENOT_FOUND_FORMULA
        }
    }

    public entry fun set_k<C>(account: &signer, k: u64, d: u64) acquires Params {
        // multisig::validate_multisig();

        validate_account(account);

        let params = borrow_global_mut<Params>(@lend_config_admin);

        let ty_name = type_name<C>();

        let (e, i) = contains(&params.vals, &ty_name);
        if (e) {
            let formula = vector::borrow_mut(&mut params.vals, i);
            assert_c_d(k, formula.b, formula.c, d);
            formula.k = k;
            formula.d = d;
        } else {
            abort ENOT_FOUND_FORMULA
        }
    }

    public entry fun set_b<C>(account: &signer, b: u64, d: u64) acquires Params {
        // multisig::validate_multisig();

        validate_account(account);

        let params = borrow_global_mut<Params>(@lend_config_admin);

        let ty_name = type_name<C>();

        let (e, i) = contains(&params.vals, &ty_name);
        if (e) {
            let formula = vector::borrow_mut(&mut params.vals, i);
            assert_c_d(formula.k, b, formula.c, d);

            formula.b = b;
            formula.d = d
        } else {
            abort ENOT_FOUND_FORMULA
        }
    }

    public entry fun set_a<C>(account: &signer, a: u64) acquires Params {
        // multisig::validate_multisig();

        validate_account(account);

        let params = borrow_global_mut<Params>(@lend_config_admin);

        let ty_name = type_name<C>();

        let (e, i) = contains(&params.vals, &ty_name);
        if (e) {
            let formula = vector::borrow_mut(&mut params.vals, i);
            formula.a = a
        } else {
            abort ENOT_FOUND_FORMULA
        }
    }

    public entry fun set_reserves<C>(account: &signer, reserves: u64) acquires Params {
        // multisig::validate_multisig();

        validate_account(account);

        let params = borrow_global_mut<Params>(@lend_config_admin);

        let ty_name = type_name<C>();
        let (e, i) = contains(&params.vals, &ty_name);
        if (e) {
            let formula = vector::borrow_mut(&mut params.vals, i);
            formula.reserves = reserves
        } else {
            abort ENOT_FOUND_FORMULA
        }
    }

    // result extend 100000 times
    fun calc_borrow_rate<C>(u: u64): u64 acquires Params {

        let coin_name = type_name<C>();

        calc_borrow_rate_with_coin_name(u, &coin_name)
    }

    fun calc_borrow_rate_with_coin_name(u: u64, coin_name: &String): u64 acquires Params {

        let params = borrow_global<Params>(@lend_config_admin);

        let (e, i) = contains(&params.vals, coin_name);
        if (e) {
            let formula = vector::borrow(&params.vals, i);
            if (u < formula.c) {
                // y = kx + b
                // (formula.k * u + 10 * formula.b) / 10
                // 1e+6
                (formula.k * u + formula.b)
            } else {
                // y = a (u - c)^3/2 + d
                // (formula.a * (u - formula.c) * sqrt(((u - formula.c) as u128)) + 10 * formula.d) / 10
                // 1e+6     1e4*1e2
                formula.a * (u - formula.c) * sqrt(((u - formula.c) as u128)) + formula.d
            }
        } else {
            abort ENOT_FOUND_FORMULA
        }
    }

    fun calc_borrow_rate_with_diff_time<C>(u: u64, diff_time: u64): u64 acquires Params {
        let coin_name = type_name<C>();
        // 1e+6 * 1e+4 = 1e+10
        calc_borrow_rate_with_diff_time_coin_name(u, diff_time, &coin_name)
    }

    fun calc_borrow_rate_with_diff_time_coin_name(u: u64, diff_time: u64, coin_name: &String): u64 acquires Params {
        // 1e+6 * 1e+4 = 1e+10
        ((calc_borrow_rate_with_coin_name(u, coin_name) as u128) * (diff_time as u128) * 10000  / (SECS_OF_YEAR as u128) as u64)
    }

    fun calc_supply_interest_rate(borrow_interest_rate: u64, u: u64, diff_time: u64): u64 {
        // 1e+6 * 1e+4 = 1e+10
        ((borrow_interest_rate as u128) * (diff_time as u128) * (u as u128) / (SECS_OF_YEAR as u128) as u64)
    }

    // 1e+4
    public fun calc_utilization(borrow: u128, supply: u128): u64 {
        if (supply == 0) {
            return 0
        };
        math::mul_div_u128(borrow, 10000, supply)
    }

    // index: 1e+10  rate: 1e+10
    public fun calc_index(old_index: u128, interest_rate: u64): u128 {
        old_index * (EXTEND_INDEX  + (interest_rate as u128)) / EXTEND_INDEX
    }

    public fun calc_supply_index(utilization: u64, diff_time: u64, old_index: u128, coin_name: &String): u128 acquires Params {
        // borrow interest rate
        let borrow_interest_rate = calc_borrow_rate_with_coin_name(utilization, coin_name);

        // supply interest rate
        let supply_interest_rate = calc_supply_interest_rate(
            borrow_interest_rate,
            utilization,
            diff_time
        );

        let index = calc_index(old_index, supply_interest_rate);

        index
    }

    public fun calc_borrow_index(utilization: u64, diff_time: u64, old_index: u128, coin_name: &String): u128 acquires Params {
        let borrow_interest_rate = calc_borrow_rate_with_diff_time_coin_name(
            utilization,
            diff_time,
            coin_name
        );

        let index = calc_index(old_index, borrow_interest_rate);

        index
    }

    public fun index_extends_times(): u128 {
        EXTEND_INDEX
    }

    public entry fun zero_all_params(account: &signer) acquires Params {
        let account_addr = signer::address_of(account);
        assert!(account_addr == @lend_config_admin, error::permission_denied(ENOT_ALLOWED));
        assert!(exists<Params>(account_addr), error::not_found(ENOT_PUBLISHED_FORMULAPARAM));

        let params = borrow_global_mut<Params>(@lend_config_admin);
        let i = 0;
        let len = vector::length(&params.vals);
        while (i < len) {
            let f = vector::borrow_mut(&mut params.vals, i);
            f.k = 0;
            f.b = 0;
            f.a = 0;
            f.d = 0;
            i += 1;
        }
    }

    #[test_only]
    struct FMK {}

    #[test_only]
    use aptos_std::debug::print;
    use std::string::String;

    #[test(config = @lend_config_admin)]
    fun test_index_calcs(config: &signer) acquires Params {
        initialize(config);

        // 100% borrow interest rate
        let k = 29; // 2 decimals
        let b = 2530; // 5 decimals
        let a = 0; // 2 decimals
        let d = 257300; // 5 decimals

        add<FMK>(config, k, b, a, d);

        // 50% utilization rate so profit rate will be 50%
        let u = 0; // 4 decimals
        let diff_time = 24 * 60 * 60;

        let borrow_rate = calc_borrow_rate<FMK>(u);
        let supply_rate = calc_supply_interest_rate(borrow_rate, u, diff_time);

        let borrow_index = calc_index(
            EXTEND_INDEX,
            calc_borrow_rate_with_diff_time<FMK>(u, diff_time));
        let supply_index = calc_index(EXTEND_INDEX, supply_rate);

        print(&borrow_index);
        print(&supply_index);
    }

    #[test(config = @lend_config_admin)]
    fun test_zero_all_params_freezes_indices(config: &signer) acquires Params {
        initialize(config);

        // baseline non-zero parameters
        let k = 29; // 2 decimals
        let b = 2530; // 5 decimals
        let a = 0; // 2 decimals
        let d = 257300; // 5 decimals

        add<FMK>(config, k, b, a, d);

        // utilization and time window
        let u = 1000; // 10% utilization (1e4 scale)
        let diff_time = 24 * 60 * 60; // 1 day

        let old_index = EXTEND_INDEX;

        // before zeroing: rates should be positive and indices should advance
        let borrow_rate0 = calc_borrow_rate<FMK>(u);
        assert!(borrow_rate0 > 0, ED_IS_A_WRONG_VALUE);

        let supply_rate0 = calc_supply_interest_rate(borrow_rate0, u, diff_time);
        assert!(supply_rate0 > 0, ED_IS_A_WRONG_VALUE);

        let borrow_index0 = calc_index(old_index, calc_borrow_rate_with_diff_time<FMK>(u, diff_time));
        assert!(borrow_index0 > old_index, ED_IS_A_WRONG_VALUE);

        let supply_index0 = calc_index(old_index, supply_rate0);
        assert!(supply_index0 > old_index, ED_IS_A_WRONG_VALUE);

        // zero all params: rates should drop to zero and indices should freeze
        zero_all_params(config);

        let borrow_rate1 = calc_borrow_rate<FMK>(u);
        assert!(borrow_rate1 == 0, ED_IS_A_WRONG_VALUE);

        let supply_rate1 = calc_supply_interest_rate(borrow_rate1, u, diff_time);
        assert!(supply_rate1 == 0, ED_IS_A_WRONG_VALUE);

        let borrow_index1 = calc_index(old_index, calc_borrow_rate_with_diff_time<FMK>(u, diff_time));
        assert!(borrow_index1 == old_index, ED_IS_A_WRONG_VALUE);

        let supply_index1 = calc_index(old_index, supply_rate1);
        assert!(supply_index1 == old_index, ED_IS_A_WRONG_VALUE);

        // verify the per-coin functions freeze with zeroed params
        let coin_name = type_name<FMK>();
        let borrow_idx_func1 = calc_borrow_index(u, diff_time, old_index, &coin_name);
        let supply_idx_func1 = calc_supply_index(u, diff_time, old_index, &coin_name);

        assert!(borrow_idx_func1 == old_index, ED_IS_A_WRONG_VALUE);
        assert!(supply_idx_func1 == old_index, ED_IS_A_WRONG_VALUE);
    }
}
