module lend_config::reward_config {
    use std::string::{String, utf8};
    use aptos_std::table::{Self, Table};
    use std::signer;
    use std::error;
    use aptos_std::type_info::type_name;
    use std::vector;

    const ENOT_ALLOWED: u64 = 1;
    const EALREADY_INITIALIZED_REWARDS_CONFIG: u64 = 2;
    const ENOT_INITIALIZED_REWARDS_CONFIG_STORE: u64 = 3;
    const ENOT_FOUND: u64 = 4;
    const ESTART_TIME_DELAY_TO_END_TIME: u64 = 5;
    const EMORE_THAN_TWO_REWARDS: u64 = 6;
    const ENOT_ALLOWED_UPDATE_IN_ACTIVITY: u64 = 7;
    const EONE_MORE_ACTIVITY_ACTIVE: u64 = 8;
    const EINVALID_END_TIME: u64 = 9;
    const EDEPRECATED: u64 = 10;

    // const APN_TYPE_NAME: String = utf8(b"@lend_coin::coin::APU");

    struct RewardsConfig has store, copy, drop {
        reward_coin_name: String,
        decimals: u8,
        pause: bool,
        supply_reward_rate: u64,
        borrow_reward_rate: u64,
        start_time: u64,
        end_time: u64,
        amount_supply: u64,
        amount_borrow: u64,
    }

    struct RewardsConfigStore has key, store {
        config: Table<String, vector<RewardsConfig>>,
    }

    public entry fun initialize(account: &signer) {
        assert!(false, EDEPRECATED);
        let account_addr = signer::address_of(account);

        assert!(account_addr == @lend_config_admin, error::permission_denied(ENOT_ALLOWED));

        assert!(!exists<RewardsConfigStore>(account_addr), error::not_found(EALREADY_INITIALIZED_REWARDS_CONFIG));

        move_to(account, RewardsConfigStore {
            config: table::new()
        })
    }

    public fun supply_reward_rate(rewards_config: &RewardsConfig): u64 {
        rewards_config.supply_reward_rate
    }

    public fun borrow_reward_rate(rewards_config: &RewardsConfig): u64 {
        rewards_config.borrow_reward_rate
    }

    public fun pause(rewards_config: &RewardsConfig): bool {
        rewards_config.pause
    }

    public fun start_time(rewards_config: &RewardsConfig): u64 {
        rewards_config.start_time
    }

    public fun end_time(rewards_config: &RewardsConfig): u64 {
        rewards_config.end_time
    }

    public fun decimals(rewards_config: &RewardsConfig): u8 {
        rewards_config.decimals
    }

    #[view]
    public fun amounts<C, R>(): (u64, u64) acquires  RewardsConfigStore {
        assert!(exists<RewardsConfigStore>(@lend_config_admin), error::not_found(ENOT_INITIALIZED_REWARDS_CONFIG_STORE));

        let _store = borrow_global<RewardsConfigStore>(@lend_config_admin);
    //
    //     let coin_name = type_name<C>();
    //
    //     if (table::contains(&store.config, coin_name)) {
    //         let configs = table::borrow(&store.config, coin_name);
    //
    //         let reward_coin_name = type_name<R>();
    //
    //         let (exist, index) = index_of(configs, &reward_coin_name);
    //
    //         if (exist) {
    //             let config = vector::borrow(configs, index);
    //
    //             return (config.amount_supply, config.amount_borrow)
    //         }
    //     };
    //
        (0,0)
    }

    public entry fun add<C, R>(account: &signer, supply_reward_rate: u64, borrow_reward_rate: u64, start_time: u64, end_time: u64, decimals: u8, amount_supply: u64, amount_borrow: u64) acquires RewardsConfigStore {
        assert!(false, EDEPRECATED);
        assert!(end_time > start_time, ESTART_TIME_DELAY_TO_END_TIME);
        set<C, R>(account, false, supply_reward_rate, borrow_reward_rate, start_time, end_time, decimals, amount_supply, amount_borrow);
    }

    public fun stop<C, R>(account: &signer) acquires RewardsConfigStore {
        set<C, R>(account, true, 0, 0, 0, 0, 0, 0, 0);
    }

    public entry fun stop_rewards_activity<C, R>(admin: &signer) acquires RewardsConfigStore {
        stop<C, R>(admin);
    }

    public entry fun update_endtime<C, R>(end_time: u64) acquires RewardsConfigStore {
        assert!(false, EDEPRECATED);
        assert!(exists<RewardsConfigStore>(@lend_config_admin), error::not_found(ENOT_INITIALIZED_REWARDS_CONFIG_STORE));

        let store = borrow_global_mut<RewardsConfigStore>(@lend_config_admin);

        let coin_name = type_name<C>();

        assert!(table::contains(&store.config, coin_name), ENOT_FOUND);

        let configs = table::borrow_mut(&mut store.config, coin_name);

        let reward_coin_name = type_name<R>();

        let (exist, index) = index_of(configs, &reward_coin_name);

        if (exist) {
            let config = vector::borrow_mut(configs, index);
            // assert!(end_time > config.end_time, EINVALID_END_TIME);

            config.end_time = end_time;
        }

    }

    public fun update<C, R>(account: &signer, supply_reward_rate: u64, borrow_reward_rate: u64, start_time: u64, end_time: u64, decimals: u8, amount_supply: u64, amount_borrow: u64) acquires RewardsConfigStore {
        assert!(end_time > start_time, ESTART_TIME_DELAY_TO_END_TIME);
        set<C, R>(account, false, supply_reward_rate, borrow_reward_rate, start_time, end_time, decimals, amount_supply, amount_borrow);
    }

    fun set<C, R>(account: &signer, pause: bool, supply_reward_rate: u64, borrow_reward_rate: u64, start_time: u64, end_time: u64, decimals: u8, amount_supply: u64, amount_borrow: u64) acquires RewardsConfigStore {
        let account_addr = signer::address_of(account);

        assert!(account_addr == @lend_config_admin || account_addr == @claim_oper, error::permission_denied(ENOT_ALLOWED));

        assert!(exists<RewardsConfigStore>(@lend_config_admin), error::not_found(ENOT_INITIALIZED_REWARDS_CONFIG_STORE));

        let store = borrow_global_mut<RewardsConfigStore>(@lend_config_admin);

        let coin_name = type_name<C>();

        if (table::contains(&store.config, coin_name)) {
            let configs = table::borrow_mut(&mut store.config, coin_name);

            let reward_coin_name = type_name<R>();

            let (exist, index) = index_of(configs, &reward_coin_name);

            if ( !exist ) {
                if (reward_coin_name != coin_name_apn()) {
                    activity_unique_check(configs);
                };
                // add
                vector::push_back(configs, RewardsConfig {
                    reward_coin_name,
                    decimals,
                    pause,
                    supply_reward_rate,
                    borrow_reward_rate,
                    start_time,
                    end_time,
                    amount_supply,
                    amount_borrow
                })
            } else {
                // update
                let config = vector::borrow_mut(configs, index);

                assert!(pause || start_time > config.end_time, ENOT_ALLOWED_UPDATE_IN_ACTIVITY);

                config.pause = pause;
                config.supply_reward_rate = supply_reward_rate;
                config.borrow_reward_rate = borrow_reward_rate;
                config.start_time = start_time;
                config.end_time = end_time;
                config.amount_supply = amount_supply;
                config.amount_borrow = amount_borrow;
            }
        } else {
            // add
            let reward_coin_name = type_name<R>();

            let configs = vector::empty<RewardsConfig>();
            vector::push_back(&mut configs, RewardsConfig {
                reward_coin_name,
                decimals,
                pause,
                supply_reward_rate,
                borrow_reward_rate,
                start_time,
                end_time,
                amount_supply,
                amount_borrow
            });

            table::add(&mut store.config, coin_name, configs);
        }
    }

    fun index_of(configs: &vector<RewardsConfig>, reward_coin_name: &String) : (bool, u64) {
        let i = 0;
        let len = vector::length(configs);

        while ( i < len) {
            let config = vector::borrow(configs, i);

            if (config.reward_coin_name == *reward_coin_name) {
                return (true, i)
            };

            i = i + 1;
        };

        (false, i)
    }

    #[view]
    public fun reward_config(coin_name: String, reward_coin_name: String): RewardsConfig acquires RewardsConfigStore {
        assert!(exists<RewardsConfigStore>(@lend_config_admin), error::not_found(ENOT_INITIALIZED_REWARDS_CONFIG_STORE));

        let store = borrow_global<RewardsConfigStore>(@lend_config_admin);

        if (table::contains(&store.config, coin_name)) {
            let configs = table::borrow(&store.config, coin_name);

            let (exist, index) = index_of(configs, &reward_coin_name);

            if (exist) {
                return *vector::borrow(configs, index)
            } else {
                abort ENOT_FOUND
            }
        } else {
            abort ENOT_FOUND
        }
    }

    public fun reward_coin_list(coin_name: &String): vector<String> acquires RewardsConfigStore {
        assert!(exists<RewardsConfigStore>(@lend_config_admin), error::not_found(ENOT_INITIALIZED_REWARDS_CONFIG_STORE));

        let store = borrow_global<RewardsConfigStore>(@lend_config_admin);

        let vs = vector::empty<String>();

        if (table::contains(&store.config, *coin_name)) {
            let configs = table::borrow(&store.config, *coin_name);

            let i = 0;
            let len = vector::length(configs);
            while (i < len) {
                let config = vector::borrow(configs, i);
                if(!config.pause) {
                    vector::push_back(&mut vs, config.reward_coin_name);
                };
                i = i + 1;
            }
        };

        assert!(vector::length(&vs) < 3, EMORE_THAN_TWO_REWARDS);

        vs
    }

    fun activity_unique_check(configs: &vector<RewardsConfig>) {
        let len = vector::length(configs);
        let i = 0;
        let count = 0;
        while (i < len) {
            let config = vector::borrow(configs, i);
            if (!config.pause) count = count + 1;
            i = i + 1;
        };

        assert!(count < 1, EONE_MORE_ACTIVITY_ACTIVE);
    }

    public fun coin_name_apn(): String {
        utf8(b"0xaceee9f9ec1bd0198002c24d4ca780362b590bf0c7b21fd9e990cb39fb74e747::coin::APU")
    }
}
