module lend_config::pool_config {

    use aptos_std::type_info::{type_name};
    use std::vector;
    use std::error;
    use std::signer;
    use std::string::String;
    // use lend_multisig::multisig;

    const EALREADY_PUBLISHED_CONFIG: u64 = 1;
    const ENOT_FOUND_CONFIG: u64 = 2;
    const EFEES_WRONG_VALUE: u64 = 3;
    const ELTV_WRONG_VALUE: u64 = 4;
    const ENOT_FOUND_COIN_NAME: u64 = 5;
    const EWEIGHT_WRONG_VALUE: u64 = 6;
    const EALREADY_ADDED: u64 = 7;
    const ENOT_ALLOWED: u64 = 8;

    const ENOT_EXISTS_APN_REWARD: u64 = 2001;

    /// annualized apn reward
    const DEFAULT_REWARD_POOL: u64 = 6000000000000;
    const DEFAULT_REWARD_STAKE: u64 = 3650000000000;
    const SECS_OF_YEAR: u64 = 365 * 24 * 60 * 60;

    const MIN_LTV: u8 = 30;
    const MAX_LTV: u8 = 80;

    const MIN_FEES: u8 = 1;
    const MAX_FEES: u8 = 10;

    const MIN_WEIGHT: u8 = 1;
    const MAX_WEIGHT: u8 = 40;

    struct Store has copy, drop, store {
        // coin name
        coin_name: String,
        // decimal 2
        ltv: u8,
        // service fee, decimal 2
        fees: u8,
        // use for apn reward on each pool
        weight: u8,
        max_deposit_limit: u64,
        min_deposit_limit: u64,
    }

    struct Config has key {
        apn_rewards_pool: u64,
        apn_rewards_stake: u64,
        stores: vector<Store>,
    }

    fun sum(stores: &vector<Store>): u64 {
        let len = vector::length(stores);
        let i = 0;
        let sum: u64 = 0;
        while (i < len) {
            let store = vector::borrow(stores, i);
            sum = sum + (store.weight as u64);
            i = i + 1;
        };

        sum
    }

    fun contains(stores: &vector<Store>, ct: &String): (bool, u64) {
        let i = 0;
        let len = vector::length(stores);
        while (i < len) {
            let store = vector::borrow(stores, i);
            if (store.coin_name == *ct) {
                return (true, i)
            };
            i = i + 1;
        };
        (false, 0)
    }

    fun validate_account(account: &signer) {
        let account_addr = signer::address_of(account);

        assert!(account_addr == @lend_config_admin, error::permission_denied(ENOT_ALLOWED));

        assert!(exists<Config>(account_addr), error::not_found(ENOT_FOUND_CONFIG));
    }

    public entry fun initialize(account: &signer) {
        // multisig::validate_multisig();

        let account_addr = signer::address_of(account);

        assert!(account_addr == @lend_config_admin, error::permission_denied(ENOT_ALLOWED));

        assert!(!exists<Config>(account_addr), error::not_found(EALREADY_PUBLISHED_CONFIG));

        move_to(account, Config {
            apn_rewards_pool: DEFAULT_REWARD_POOL,
            apn_rewards_stake: DEFAULT_REWARD_STAKE,
            stores: vector::empty(),
        })
    }

    fun validate_fees(fees: u8) {
        if(!(fees >= MIN_FEES && fees <= MAX_FEES)) {
            abort EFEES_WRONG_VALUE
        }
    }

    fun validate_ltv(ltv: u8) {
        if (!(ltv >= MIN_LTV && ltv <= MAX_LTV)) {
            abort ELTV_WRONG_VALUE
        }
    }

    fun validate_weight(weight: u8) {
        if (!(weight >= MIN_WEIGHT && weight <= MAX_WEIGHT)) {
            abort EWEIGHT_WRONG_VALUE
        }
    }

    #[view]
    public fun get_config(account_addr: address): vector<Store> acquires Config {
        assert!(exists<Config>(account_addr), error::not_found(ENOT_FOUND_CONFIG));

        borrow_global<Config>(account_addr).stores
    }

    public fun add<C>(account: &signer, ltv: u8, fees: u8, weight: u8, max_deposit_limit: u64, min_deposit_limit: u64) acquires Config {

        validate_fees(fees);

        validate_ltv(ltv);

        validate_weight(weight);


        validate_account(account);

        let config = borrow_global_mut<Config>(@lend_config_admin);

        let type_name = type_name<C>();

        let (e, _i) = contains(&config.stores, &type_name);
        if (e) {
            abort EALREADY_ADDED
        };

        vector::push_back(&mut config.stores, Store { coin_name: type_name, ltv, fees, weight, max_deposit_limit, min_deposit_limit});
    }

    public fun remove<C>(account: &signer) acquires Config {
        validate_account(account);

        let config = borrow_global_mut<Config>(@lend_config_admin);

        let type_name = type_name<C>();

        let (e, i) = contains(&config.stores, &type_name);
        if (e) {
            vector::remove(&mut config.stores, i)
        } else {
            abort ENOT_FOUND_COIN_NAME
        };
    }

    fun borrow_mut(stores: &mut vector<Store>, cn: &String): &mut Store {

        let (e, i) = contains(stores, cn);
        if (e) {
            vector::borrow_mut(stores, i)
        } else {
            abort ENOT_FOUND_COIN_NAME
        }
    }

    public fun set_weight<C>(account: &signer, weight: u8) acquires Config {
        validate_weight(weight);

        validate_account(account);

        let config = borrow_global_mut<Config>(@lend_config_admin);

        let coin_name = type_name<C>();

        let store = borrow_mut(&mut config.stores, &coin_name);

        store.weight = weight
    }

    public entry fun set_ltv<C>(account: &signer, new_ltv: u8) acquires Config {
        // multisig::validate_multisig();

        validate_ltv(new_ltv);

        validate_account(account);

        let config = borrow_global_mut<Config>(@lend_config_admin);

        let coin_name = type_name<C>();

        let store = borrow_mut(&mut config.stores, &coin_name);

        store.ltv = new_ltv
    }

    public entry fun set_fees<C>(account: &signer, new_fees: u8) acquires Config {
        // multisig::validate_multisig();

        validate_fees(new_fees);

        validate_account(account);

        let config = borrow_global_mut<Config>(@lend_config_admin);

        let coin_name = type_name<C>();

        let store = borrow_mut(&mut config.stores, &coin_name);

        store.fees = new_fees
    }

    public fun set_apn_reward_stake(account: &signer, new_reward: u64) acquires Config {

        validate_account(account);

        let config = borrow_global_mut<Config>(@lend_config_admin);

        config.apn_rewards_stake = new_reward
    }

    public fun set_apn_reward_pool(account: &signer, new_reward: u64) acquires Config {
        validate_account(account);

        let config = borrow_global_mut<Config>(@lend_config_admin);

        config.apn_rewards_pool = new_reward
    }

    public entry fun set_max_deposit_limit<C>(account: &signer, new_deposit_limit: u64) acquires Config {
        // multisig::validate_multisig();

        validate_account(account);
        let config = borrow_global_mut<Config>(@lend_config_admin);

        let coin_name = type_name<C>();

        // todo: check value

        let store = borrow_mut(&mut config.stores, &coin_name);

        store.max_deposit_limit = new_deposit_limit;
    }

    public entry fun set_min_deposit_limit<C>(account: &signer, new_deposit_limit: u64) acquires Config {
        // multisig::validate_multisig();

        validate_account(account);

        // todo: check value

        let config = borrow_global_mut<Config>(@lend_config_admin);

        let coin_name = type_name<C>();

        let store = borrow_mut(&mut config.stores, &coin_name);

        store.min_deposit_limit = new_deposit_limit;
    }

    /// Return APN reward for each coin
    public fun apn_reward_per_pool(coin_name: &String): u64 acquires Config {
        assert!(exists<Config>(@lend_config_admin), error::not_found(ENOT_FOUND_CONFIG));

        let config = borrow_global<Config>(@lend_config_admin);

        let (e, i) = contains(&config.stores, coin_name);

        if (e) {
            let sum_of_weight = sum(&config.stores);
            let store = vector::borrow(&config.stores, i);

            // supply pool and borrow pool of each coin share the apn reward, so divided by 2
            let r = (config.apn_rewards_pool as u128) * (store.weight as u128) / (SECS_OF_YEAR * sum_of_weight * 2 as u128);
            (r as u64)
        } else {
            abort ENOT_EXISTS_APN_REWARD
        }
    }

    /// Return APN reward for stake
    public fun apn_reward_stake(): u64 acquires Config {
        assert!(exists<Config>(@lend_config_admin), error::not_found(ENOT_FOUND_CONFIG));

        let config = borrow_global<Config>(@lend_config_admin);

        config.apn_rewards_stake / SECS_OF_YEAR
    }

    fun borrow(ct: &String): Store acquires Config {
        assert!(exists<Config>(@lend_config_admin), error::not_found(ENOT_FOUND_CONFIG));
        let config = borrow_global<Config>(@lend_config_admin);

        let (e, i) = contains(&config.stores, ct);

        if (e) {
            *vector::borrow(&config.stores, i)
        } else {
            abort ENOT_FOUND_COIN_NAME
        }
    }

    /// Return service fees, the result is extended 100 times
    public fun fees<C>(): u8 acquires Config {
        let cn = type_name<C>();
        fees_with_coin_name(&cn)
    }

    /// Return service fees, the result is extended 100 times
    public fun fees_with_coin_name(cn: &String): u8 acquires Config {
        let store = borrow(cn);
        store.fees
    }

    /// Return LTV, the result is extended 100 times
    public fun ltv<C>(): u8 acquires Config {
        let cn = type_name<C>();
        ltv_with_coin_name(&cn)
    }

    /// Return LTV, the result is extended 100 times
    public fun ltv_with_coin_name(cn: &String): u8 acquires Config {
        let store = borrow(cn);
        store.ltv
    }

    /// Return how many is the limit amount when deposit
    public fun max_deposit_limit<C>(): u64 acquires Config {
        let cn = type_name<C>();
        max_deposit_limit_with_coin_name(&cn)
    }

    /// Return how many is the limit amount when deposit
    public fun max_deposit_limit_with_coin_name(cn: &String): u64 acquires Config {

        let store = borrow(cn);

        store.max_deposit_limit
    }

    /// Return how many is the limit amount when deposit
    public fun min_deposit_limit<C>(): u64 acquires Config {
        let cn = type_name<C>();

        min_deposit_limit_with_coin_name(&cn)
    }

    /// Return how many is the limit amount when deposit
    public fun min_deposit_limit_with_coin_name(cn: &String): u64 acquires Config {

        let store = borrow(cn);

        store.min_deposit_limit
    }

}
