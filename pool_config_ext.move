module lend_config::pool_config_ext {

    use aptos_std::type_info::{type_name};
    use std::vector;
    use std::error;
    use std::signer;
    use std::string::String;

    const EALREADY_PUBLISHED_CONFIG: u64 = 1;
    const ENOT_FOUND_CONFIG: u64 = 2;
    const EFEES_WRONG_VALUE: u64 = 3;
    const ELTV_WRONG_VALUE: u64 = 4;
    const ENOT_FOUND_COIN_NAME: u64 = 5;
    const EWEIGHT_WRONG_VALUE: u64 = 6;
    const EALREADY_ADDED: u64 = 7;
    const ENOT_ALLOWED: u64 = 8;

    const ENOT_EXISTS_APN_REWARD: u64 = 2001;

    struct Store has copy, drop, store {
        // coin name
        coin_name: String,

        // x / 100
        max_portion_borrow: u64,

        reserve0: u64,     // max supplyed
        reserve1: u64,     // min borrow
        reserve2: u64,
    }

    struct Config has key {
        stores: vector<Store>,
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
            stores: vector::empty(),
        })
    }

    #[view]
    public fun get_config(account_addr: address): vector<Store> acquires Config {
        assert!(exists<Config>(account_addr), error::not_found(ENOT_FOUND_CONFIG));

        borrow_global<Config>(account_addr).stores
    }

    public entry fun add<C>(account: &signer, max_portion_borrow: u64) acquires Config {
        validate_account(account);

        let config = borrow_global_mut<Config>(@lend_config_admin);

        let type_name = type_name<C>();

        let (e, _i) = contains(&config.stores, &type_name);
        if (e) {
            abort EALREADY_ADDED
        };

        vector::push_back(&mut config.stores, Store { coin_name: type_name, max_portion_borrow, reserve0: 0, reserve1:0, reserve2:0});
    }

    public entry fun remove<C>(account: &signer) acquires Config {
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

    public entry fun set_max_portion_borrow<C>(account: &signer, max_portion_borrow: u64) acquires Config {
        validate_account(account);

        let config = borrow_global_mut<Config>(@lend_config_admin);

        let coin_name = type_name<C>();

        let store = borrow_mut(&mut config.stores, &coin_name);

        store.max_portion_borrow = max_portion_borrow
    }

    public entry fun set_max_supplyed_amount<C>(account: &signer, max_supplyed_amount: u64) acquires Config {
        validate_account(account);

        let config = borrow_global_mut<Config>(@lend_config_admin);

        let coin_name = type_name<C>();

        let store = borrow_mut(&mut config.stores, &coin_name);

        store.reserve0 = max_supplyed_amount
    }

    public entry fun set_min_borrow_amount<C>(account: &signer, min_borrow_amount: u64) acquires Config {
        validate_account(account);

        let config = borrow_global_mut<Config>(@lend_config_admin);

        let coin_name = type_name<C>();

        let store = borrow_mut(&mut config.stores, &coin_name);

        store.reserve1 = min_borrow_amount
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

    /// Return how many is the limit amount when deposit
    public fun max_portion_borrow_with_coin_name(cn: &String): u64 acquires Config {

        let store = borrow(cn);

        store.max_portion_borrow
    }

    public fun max_supplyed_amount_with_coin_name(cn: &String): u64 acquires Config {

        let store = borrow(cn);

        store.reserve0
    }

    public fun min_borrow_amount_with_coin_name(cn: &String): u64 acquires Config {

        let store = borrow(cn);

        store.reserve1
    }

}
