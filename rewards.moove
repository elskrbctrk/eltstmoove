module lend_protocol::rewards {

    use std::string::String;
    use aptos_std::table::{Self, Table};
    use std::signer;
    use std::error;
    use std::vector;
    use std::option;

    use lend_config::reward_config;
    use lend_lib::math::pow_10;

    const ENOT_ALLOWED: u64 = 1;
    const EALREADY_INITIALIZED_REWARDS_CONFIG: u64 = 2;
    const EALREADY_INITIALIZED_REWARDS_POOL_STORE: u64 = 3;
    const ENOT_INITIALIZED_REWARDS_CONFIG_STORE: u64 = 4;
    const ENOT_INITIALIZED_REWARDS_POOL_STORE: u64 = 5;
    const ENOT_FOUND: u64 = 6;
    const EOUT_OF_BOUND: u64 = 7;
    const EOVERTIME: u64 = 8;
    const EALREADY_INITIALIZED_REWARDS_POSITION_STORE: u64 = 9;
    const ENOT_INITIALIZED_REWARDS_POSITION_STORE: u64 = 10;
    const EACTIVITY_NOT_START: u64 = 11;
    const EACTIVITY_NOT_END: u64 = 12;

    friend lend_protocol::pool;
    friend lend_protocol::lend;

    struct RewardInfo has store, copy, drop {
        reward_coin_name: String,
        rewards_per_token: u64,
        last_update_time: u64
    }

    struct RewardsPoolStore has key, store {
        supply_pool: Table<String, vector<RewardInfo>>,
        borrow_pool: Table<String, vector<RewardInfo>>,
    }

    public (friend) fun initialize(reward_signer: &signer) {
        let reward_addr = signer::address_of(reward_signer);

        assert!(!exists<RewardsPoolStore>(reward_addr), error::already_exists(EALREADY_INITIALIZED_REWARDS_POOL_STORE));

        move_to(reward_signer, RewardsPoolStore {
            supply_pool: table::new(),
            borrow_pool: table::new(),
        });
    }

    #[view]
    public fun supply_reward_info(coin_name: String, reward_coin_name: String): option::Option<RewardInfo> acquires RewardsPoolStore {
        assert!(exists<RewardsPoolStore>(@reward_addr), error::already_exists(ENOT_INITIALIZED_REWARDS_POOL_STORE));

        let store = borrow_global<RewardsPoolStore>(@reward_addr);

        if(table::contains(&store.supply_pool, coin_name)) {
            let reward_infos = table::borrow(&store.supply_pool, coin_name);
            let (exist, index) = index_of(reward_infos, &reward_coin_name);
            if (exist) {
                return option::some(*vector::borrow(reward_infos, index) )
            }
        };
        option::none()
    }

    #[view]
    public fun borrow_reward_info(coin_name: String, reward_coin_name: String): option::Option<RewardInfo> acquires RewardsPoolStore {
        assert!(exists<RewardsPoolStore>(@reward_addr), error::already_exists(ENOT_INITIALIZED_REWARDS_POOL_STORE));

        let store = borrow_global<RewardsPoolStore>(@reward_addr);

        if(table::contains(&store.supply_pool, coin_name)) {
            let reward_infos = table::borrow(&store.borrow_pool, coin_name);
            let (exist, index) = index_of(reward_infos, &reward_coin_name);
            if (exist) {
                return option::some(*vector::borrow(reward_infos, index) )
            }
        };
        option::none()
    }

    fun set_rewards_per_token(reward_info: &mut RewardInfo, val: u64) {
        reward_info.rewards_per_token = val
    }

    fun set_last_update_time(reward_info: &mut RewardInfo, val: u64) {
        reward_info.last_update_time = val
    }

    fun index_of(reward_infos: &vector<RewardInfo>, reward_coin_name: &String) : (bool, u64) {
        let i = 0;
        let len = vector::length(reward_infos);

        while ( i < len) {
            let reward_info = vector::borrow(reward_infos, i);

            if (reward_info.reward_coin_name == *reward_coin_name) {
                return (true, i)
            };

            i = i + 1;
        };

        (false, i)
    }

    #[view]
    public fun rewards_pool(rewards_per_token: u64, end: u64, last_update_time: u64, rate: u64, decimals: u8, total_amount: u128) : u64 {
        if (total_amount == 0) return rewards_per_token;
        if (end < last_update_time) return 0;
        rewards_per_token + (((end - last_update_time) * rate * pow_10(decimals) as u128) / total_amount as u64)
    }

    fun rewards_per_token(reward_info: &RewardInfo, reward_rate: u64, now: u64, total_amount: u128, decimals: u8): u64 {
        if (total_amount == 0) {
            return reward_info.rewards_per_token
        };

        assert!(now >= reward_info.last_update_time, EACTIVITY_NOT_START);
        let new_rewards_per_token = reward_info.rewards_per_token + (((now - reward_info.last_update_time) * reward_rate * pow_10(decimals) as u128) / total_amount as u64);

        new_rewards_per_token
    }

    public (friend) fun reset(coin_name: &String, reward_coin_name: &String, start_time: u64) acquires RewardsPoolStore {
        assert!(exists<RewardsPoolStore>(@reward_addr), ENOT_INITIALIZED_REWARDS_POOL_STORE);

        let store = borrow_global_mut<RewardsPoolStore>(@reward_addr);

        if (table::contains(&store.supply_pool, *coin_name)) {
            let supply_pools = table::borrow_mut(&mut store.supply_pool, *coin_name);
            let (exist, index) = index_of(supply_pools, reward_coin_name);
            if(exist) {
                let supply_pool = vector::borrow_mut(supply_pools, index);
                set_rewards_per_token(supply_pool, 0);
                set_last_update_time(supply_pool, start_time);
            }
        };

        if(table::contains(&store.borrow_pool, *coin_name)) {
            let borrow_pools = table::borrow_mut(&mut store.borrow_pool, *coin_name);
            let (exist, index) = index_of(borrow_pools, reward_coin_name);
            if (exist) {
                let borrow_pool = vector::borrow_mut(borrow_pools, index);

                set_rewards_per_token(borrow_pool, 0);
                set_last_update_time(borrow_pool, start_time);
            }
        }
    }

    public (friend) fun update_supply_reward(coin_name: &String, reward_coin_name: &String, now: u64, total_amount: u128, is_self: bool): (u64, u8) acquires RewardsPoolStore {
        // validate
        let rewards_config = reward_config::reward_config(*coin_name, *reward_coin_name);

        if (!is_self) assert!(now > reward_config::end_time(&rewards_config), EACTIVITY_NOT_END);

        let rewards_per_token = 0;

        if (!reward_config::pause(&rewards_config) && now >= reward_config::start_time(&rewards_config)) {
            if (now > reward_config::end_time(&rewards_config)) {
                now = reward_config::end_time(&rewards_config)
            };

            assert!(exists<RewardsPoolStore>(@reward_addr), error::not_found(ENOT_INITIALIZED_REWARDS_POOL_STORE));

            let store = borrow_global_mut<RewardsPoolStore>(@reward_addr);
            if (!table::contains(&store.supply_pool, *coin_name)) {
                let vs = vector::empty<RewardInfo>();
                vector::push_back(&mut vs, RewardInfo {
                    reward_coin_name: *reward_coin_name,
                    rewards_per_token: 0,
                    last_update_time: reward_config::start_time(&rewards_config)
                });
                table::add(&mut store.supply_pool, *coin_name, vs);
            };

            let reward_infos = table::borrow_mut(&mut store.supply_pool, *coin_name);

            let (exist, index) = index_of(&*reward_infos, reward_coin_name);

            if (!exist) {
                vector::push_back(reward_infos, RewardInfo {
                    reward_coin_name: *reward_coin_name,
                    rewards_per_token: 0,
                    last_update_time: reward_config::start_time(&rewards_config)
                })
            };

            // update pool
            let reward_info = vector::borrow_mut(reward_infos, index);
            rewards_per_token = rewards_per_token(reward_info, reward_config::supply_reward_rate(&rewards_config), now, total_amount, reward_config::decimals(&rewards_config));
            reward_info.rewards_per_token = rewards_per_token;
            reward_info.last_update_time = now;
        };

        (rewards_per_token, reward_config::decimals(&rewards_config))
    }

    public (friend) fun update_borrow_reward(coin_name: &String, reward_coin_name: &String, now: u64, total_amount: u128, is_self: bool): (u64, u8) acquires RewardsPoolStore {
        // validate
        let rewards_config = reward_config::reward_config(*coin_name, *reward_coin_name);

        if (!is_self) assert!(now > reward_config::end_time(&rewards_config), EACTIVITY_NOT_END);

        let rewards_per_token = 0;

        if (!reward_config::pause(&rewards_config) && now >= reward_config::start_time(&rewards_config)) {
            if (now > reward_config::end_time(&rewards_config)) {
                now = reward_config::end_time(&rewards_config)
            };
            assert!(exists<RewardsPoolStore>(@reward_addr), error::already_exists(ENOT_INITIALIZED_REWARDS_POOL_STORE));

            let store = borrow_global_mut<RewardsPoolStore>(@reward_addr);
            if (!table::contains(&store.borrow_pool, *coin_name)) {
                let vs = vector::empty<RewardInfo>();
                vector::push_back(&mut vs, RewardInfo {
                    reward_coin_name: *reward_coin_name,
                    rewards_per_token: 0,
                    last_update_time: reward_config::start_time(&rewards_config)
                });
                table::add(&mut store.borrow_pool, *coin_name, vs);
            };

            let reward_infos = table::borrow_mut(&mut store.borrow_pool, *coin_name);

            let (exist, index) = index_of(&*reward_infos, reward_coin_name);

            if (!exist) {
                vector::push_back(reward_infos, RewardInfo {
                    reward_coin_name: *reward_coin_name,
                    rewards_per_token: 0,
                    last_update_time: reward_config::start_time(&rewards_config)
                })
            };

            // update pool
            let reward_info = vector::borrow_mut(reward_infos, index);
            rewards_per_token = rewards_per_token(reward_info, reward_config::borrow_reward_rate(&rewards_config), now, total_amount, reward_config::decimals(&rewards_config));

            reward_info.rewards_per_token = rewards_per_token;
            reward_info.last_update_time = now;
        };
        (rewards_per_token, reward_config::decimals(&rewards_config))
    }
}
