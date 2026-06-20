module lend_protocol::pool {
    use std::bit_vector::BitVector;
    use std::string::{String};
    use aptos_framework::event::{EventHandle};
    use aptos_std::table::Table;
    use lend_protocol::constant::{supply_oper, borrow_oper, withdraw_oper, repay_oper, index_supply, index_withdraw, index_borrow, index_repay, liquidate_oper, claim_supply_reward_oper, claim_borrow_reward_oper, zusdc, zusdt, zweth, apt, wusdc, stapt,
        new_usdc,
        new_usdt
    };
    use aptos_std::table;
    use std::option::{Self, Option, none, some};
    use lend_lib::math;
    use std::error;
    use aptos_framework::timestamp;
    use std::vector;
    use lend_config::interest_rate::{calc_supply_index, calc_borrow_index, calc_utilization};
    use std::bit_vector;
    use std::signer;
    use aptos_framework::account;
    use aptos_std::type_info::type_name;
    use lend_config::interest_rate;
    use lend_config::pool_config;
    use aptos_framework::event;
    use lend_protocol::constant;
    use lend_feed_price::prices;
    use lend_config::pool_config_ext;
    use lend_protocol::rewards;
    use lend_config::reward_config::coin_name_apn;
    use lend_config::reward_config;
    use aptos_framework::coin;
    use aptos_framework::aptos_account;
    use lend_lib::math::pow_10;
    use std::string;


    const ENOT_PUBLISH_PROTOCOL: u64 = 1;
    const ENOT_PUBLISH_USER_POSITION: u64 = 2;
    const EALREADY_EXISTS_PROTOCOL: u64 = 3;
    const EALREADY_EXISTS_USER_POSITION: u64 = 4;
    const EINVALID_USER: u64 = 5;
    const EINSUFFICIENT_TO_WITHDRAW: u64 = 6;
    const EEXCEED_TO_REPAY: u64 = 7;
    const ENOT_SUPPORT_OPERATION: u64 = 8;
    const ENOT_SUPPORT_COIN: u64 = 9;
    const EINVALID_WITHDRAW: u64 = 10;
    const EINVALID_REPAY: u64 = 11;
    const ENOT_SATISFY_LIQUIDATE: u64 = 12;
    const ELESS_THAN_MIN_DEPOSIT_LIMIT: u64 = 13;
    const EMORE_THAN_MAX_DEPOSIT_LIMIT: u64 = 14;
    const EEXCEED_LIMIT_TO_BORROW: u64 = 15;
    const EALREADY_ADDED_COIN: u64 = 16;
    const EZERO_AMOUNT: u64 = 17;
    const EINVALID_SLOT: u64 = 18;
    const EINVALID_AMOUNT_OUT: u64 = 19;
    const EINSUFICIENT_COINS_IN_POOL_TO_WITHDRAW: u64 = 20;
    const EINSUFFICIENT_TO_BORROW: u64 = 21;
    const EFAIL_TRAVERSE: u64 = 22;
    const EMORE_THAN_MAX_PORTION_BORROW: u64 = 23;
    const EREWARD_PER_TOKEN_PAID_POISONED: u64 = 24;
    const EINSUFFICIENT_BALANCE_TO_CLAIM: u64 = 25;
    const EEXCEED_MAX_POOL_SUPPLYED_AMOUNT: u64 = 26;
    const ELESSTHAN_ONE_DOLLAR: u64 = 27;
    const ELESS_THAN_MIN_BORROW_LIMIT: u64 = 28;
    const EAMOUNT_LESS_THAN_ZERO: u64 = 29;
    const EINVALID_SUBSET: u64 = 30;

    const EPAUSE_SUPPLY: u64 = 3001;
    const EPAUSE_WITHDRAW: u64 = 3002;
    const EPAUSE_BORROW: u64 = 3003;
    const EPAUSE_REPAY: u64 = 3004;

    const LENGHT_SUBSET: u64 = 10;

    const BORROW_THRESHOLD: u64 = 80;
    const LIQUIDATE_THRESHOLD: u64 = 98; // Changed from 85 to enforce health factor < 1.02
    const THRESHOLD_DENOMINATOR: u64 = 100;

    const SIZE_OF_SLOT: u64 = 5000;

    const THREE_DAYS: u64 = 24 * 60 * 60;
    const SECONDS_PER_WEEK: u64 = 7 * 24 * 60 * 60;

    friend lend_protocol::lend;

    struct SupplyPosition has store, drop {
        amount: u64,
        interest: u64,
        last_update_time_interest: u64,
        collateral: bool,
        reward: u64,
        last_update_time_reward: u64,
        index_interest: u128,
        reserve1: u128,
        reserve2: u64,
        reserve3: u64,
        reserve4: u64,
    }

    struct BorrowPosition has store, drop {
        amount: u64,
        interest: u64,
        last_update_time_interest: u64,
        reward: u64,
        last_update_time_reward: u64,
        index_interest: u128,
        reserve1: u128,
        reserve2: u64,
        reserve3: u64,
        reserve4: u64,
    }

    struct Positions has key, store {
        supply_position: Table<String, SupplyPosition>,
        borrow_position: Table<String, BorrowPosition>,
        supply_coins: vector<String>,
        borrow_coins: vector<String>,
        slot: u64,
        registered: bool,
    }

    struct OperEvent has store, drop {
        number_id: u128,
        coin_name: String,
        oper_type: String,
        amount: u64,
        interest: u64,
        supply_total_value: u128,
        supply_index: u128,
        supply_last_update_time: u64,
        borrow_total_value: u128,
        borrow_index: u128,
        borrow_last_update_time: u64,
        utilization: u64,
    }


    struct SupplyPool has store {
        total_value: u128,
        last_update_time_interest: u64,
        index_interest: u128,
        reverse1: u64,
        // recording timestamp while traverse position
        reverse2: u128,
        // recording index while traverse position
    }

    struct BorrowPool has store {
        total_value: u128,
        last_update_time_interest: u64,
        index_interest: u128,
        reverse1: u64,
        reverse2: u128,
    }

    struct Pool has store {
        // coin_name: String,
        pause: BitVector,
        utilization: u64,
        supply_pool: SupplyPool,
        borrow_pool: BorrowPool,
        reverse1: u64,
    }

    struct LendProtocol has key {
        // pools: vector<Pool>,
        // coin_name => Pool
        pools: Table<String, Pool>,
        // users: vector<address>,
        users: Table<u64, vector<address>>,
        coins: vector<String>,
        number_id: u128,
    }

    #[event]
    struct ClaimRewards has drop, store {
        source_coin_name: String,
        reward_coin_name: String,
        user_addr: address,
        rewards: u64
    }

    #[event]
    struct TravalPool has drop, store {
        action: String,
        coin_name: String,
        supply_interest_index: u128,
        borrow_interest_index: u128,
        execute_time: u64
    }

    #[event]
    struct ValidateBalance has drop, store {
        borrow_value: u64,
        supply_value: u64
    }

    #[event]
    struct Value has drop, store {
        amount: u64,
        n: u64,
        m: u64,
        v: u64
    }

    struct UserInfo has store, drop {
        address: address,
        coin_index: u64,
        supply_amount: u64,
        borrow_amount: u64,
    }

    struct LendEventHandle has key {
        oper_events: EventHandle<OperEvent>,
    }

    public(friend) fun initialize(pool: &signer) {
        let pool_addr = signer::address_of(pool);

        assert!(!exists<LendProtocol>(pool_addr), error::already_exists(EALREADY_EXISTS_PROTOCOL));

        move_to(pool, LendProtocol {
            pools: table::new(),
            users: table::new<u64, vector<address>>(),
            coins: vector::empty(),
            number_id: 0,
        });

        move_to(pool, LendEventHandle {
            oper_events: account::new_event_handle<OperEvent>(pool),
        })
    }

    public(friend) fun add_coin<C>(pool: &signer) acquires LendProtocol {
        let pool_addr = signer::address_of(pool);

        assert!(exists<LendProtocol>(pool_addr), error::already_exists(ENOT_PUBLISH_PROTOCOL));

        let protocol = borrow_global_mut<LendProtocol>(pool_addr);

        let coin_name = type_name<C>();

        assert!(!table::contains(&protocol.pools, coin_name), EALREADY_ADDED_COIN);

        table::add(&mut protocol.pools, coin_name, Pool {
            // coin_name,
            pause: bit_vector::new(4),
            utilization: 0,
            reverse1: 0,
            supply_pool: SupplyPool {
                total_value: 0,
                last_update_time_interest: 0,
                index_interest: interest_rate::index_extends_times(),
                reverse1: 0,
                reverse2: 0,
            },
            borrow_pool: BorrowPool {
                total_value: 0,
                last_update_time_interest: 0,
                index_interest: interest_rate::index_extends_times(),
                reverse1: 0,
                reverse2: 0,
            }
        });

        vector::push_back(&mut protocol.coins, coin_name);
    }

    public(friend) fun check_position(user: &signer) {
        if (!exists<Positions>(signer::address_of(user))) {
            move_to(user, Positions {
                supply_position: table::new(),
                borrow_position: table::new(),
                supply_coins: vector::empty(),
                borrow_coins: vector::empty(),
                slot: 0,
                registered: false
            })
        }
    }

    /// only use for new user
    public(friend) fun user_initialize(user: &signer, pool_addr: address) acquires LendProtocol, Positions {
        check_position(user);

        let user_addr = signer::address_of(user);

        assert!(exists<LendProtocol>(pool_addr), ENOT_PUBLISH_PROTOCOL);

        let protocol = borrow_global_mut<LendProtocol>(pool_addr);

        let position = borrow_global_mut<Positions>(user_addr);

        check_users(protocol, &mut position.registered, &mut position.slot, user_addr, supply_oper());
    }

    /// entry point of pool, return interest and reward and if_charge_fee
    public(friend) fun process(
        pool_addr: address,
        user_addr: address,
        amount: u64,
        oper_type: u8,
        coin_name: &String,
        reverse1: Option<u64>,
        reverse2: Option<String>
    ): (u64, u64, bool) acquires LendProtocol, Positions, LendEventHandle {
        assert!(exists<LendProtocol>(pool_addr), ENOT_PUBLISH_PROTOCOL);
        assert!(exists<Positions>(user_addr), ENOT_PUBLISH_USER_POSITION);

        let protocol = borrow_global_mut<LendProtocol>(pool_addr);
        let position = borrow_global_mut<Positions>(user_addr);

        assert!(table::contains(&protocol.pools, *coin_name), ENOT_SUPPORT_COIN);

        let reward = 0;
        let now = timestamp::now_seconds();

        let is_self = true;

        if (oper_type == claim_supply_reward_oper()) {
            let pool = table::borrow_mut(&mut protocol.pools, *coin_name);
            if (table::contains(&position.supply_position, *coin_name)) {
                is_self = if (*option::borrow(&reverse1) == 1) true else false;
                let supply_position = table::borrow_mut(&mut position.supply_position, *coin_name);
                update_supply_reward(supply_position, coin_name, now, pool.supply_pool.total_value, reverse2, is_self);

                if (option::is_some(&reverse2)) {
                    let reward_coin_name = option::borrow(&reverse2);

                    if (*reward_coin_name == coin_name_apn()) {
                        reward = supply_position.reward;
                        supply_position.reward = 0;
                        if (*option::borrow(&reverse1) == 0) {
                            supply_position.reserve2 = 0;
                        }
                    } else {
                        reward = supply_position.reserve3;
                        supply_position.reserve3 = 0;
                        if (*option::borrow(&reverse1) == 0) {
                            supply_position.reserve4 = 0;
                        }
                    }
                }
            };

            return (0, reward, false)
        } else if (oper_type == claim_borrow_reward_oper()) {
            let pool = table::borrow_mut(&mut protocol.pools, *coin_name);
            if (table::contains(&position.borrow_position, *coin_name)) {
                is_self = if (*option::borrow(&reverse1) == 1) true else false;
                let borrow_position = table::borrow_mut(&mut position.borrow_position, *coin_name);
                update_borrow_reward(borrow_position, coin_name, now, pool.borrow_pool.total_value, reverse2, is_self);

                if (option::is_some(&reverse2)) {
                    let reward_coin_name = option::borrow(&reverse2);

                    if (*reward_coin_name == coin_name_apn()) {
                        reward = borrow_position.reward;
                        borrow_position.reward = 0;
                        if (*option::borrow(&reverse1) == 0) {
                            borrow_position.reserve2 = 0;
                        }
                    } else {
                        reward = borrow_position.reserve3;
                        borrow_position.reserve3 = 0;
                        if (*option::borrow(&reverse1) == 0) {
                            borrow_position.reserve4 = 0;
                        }
                    }
                }
            };
            return (0, reward, false)
        };

        let res = check_users(protocol, &mut position.registered, &mut position.slot, user_addr, oper_type);

        if (res && !vector::is_empty(&position.supply_coins)) {
            update_interest(&mut protocol.pools, position);
        };

        let now = timestamp::now_seconds();

        let interest = 0;
        let if_charge_fee = false;

        if (oper_type == supply_oper()) {
            let pool = table::borrow_mut(&mut protocol.pools, *coin_name);
            assert!(bit_vector::is_index_set(&pool.pause, index_supply()), EPAUSE_SUPPLY);

            assert!(amount >= pool_config::min_deposit_limit_with_coin_name(coin_name), ELESS_THAN_MIN_DEPOSIT_LIMIT);

            assert!(
                pool.supply_pool.total_value + (amount as u128) <= (pool_config_ext::max_supplyed_amount_with_coin_name(
                    coin_name
                ) as u128),
                EEXCEED_MAX_POOL_SUPPLYED_AMOUNT
            );

            if (!vector::contains(&position.supply_coins, coin_name)) {
                assert!(
                    amount <= pool_config::max_deposit_limit_with_coin_name(coin_name),
                    EMORE_THAN_MAX_DEPOSIT_LIMIT
                );

                let reward_coin_list = reward_config::reward_coin_list(coin_name);

                let i = 0;
                let len = vector::length(&reward_coin_list);

                let reserve2 = 0;
                let reserve4 = 0;

                while (i < len) {
                    let reward_coin_name = vector::borrow(&reward_coin_list, i);
                    let (reward_per_token, _) = rewards::update_supply_reward(
                        coin_name,
                        reward_coin_name,
                        now,
                        pool.supply_pool.total_value,
                        is_self
                    );

                    if (*reward_coin_name == coin_name_apn()) {
                        reserve2 = reward_per_token;
                    } else {
                        reserve4 = reward_per_token;
                    };

                    i = i + 1;
                };

                new_supply_position(pool, position, coin_name, amount, reverse1, reserve2, reserve4);
            } else {
                let supply_position = table::borrow_mut(&mut position.supply_position, *coin_name);

                let balance = supply_position.amount;
                assert!(
                    balance + amount <= pool_config::max_deposit_limit_with_coin_name(coin_name),
                    EMORE_THAN_MAX_DEPOSIT_LIMIT
                );

                update_supply_reward(supply_position, coin_name, now, pool.supply_pool.total_value, none(), is_self);

                interest = process_supply(&mut pool.supply_pool, supply_position, amount, now, oper_type);
            };

            update_pool_utilization(pool);
        } else if (oper_type == withdraw_oper()) {
            assert!(amount > 0, EZERO_AMOUNT);


            let pool = table::borrow_mut(&mut protocol.pools, *coin_name);
            assert!(bit_vector::is_index_set(&pool.pause, index_withdraw()), EPAUSE_WITHDRAW);

            if (!vector::contains(&position.supply_coins, coin_name)) {
                abort EINVALID_WITHDRAW
            };

            assert!(
                (amount as u128) + pool.borrow_pool.total_value <= pool.supply_pool.total_value,
                EINSUFICIENT_COINS_IN_POOL_TO_WITHDRAW
            );

            let v_balance = *option::borrow(&reverse1);

            validate_balances(pool, position, amount, coin_name, v_balance, oper_type);

            let supply_position = table::borrow_mut(&mut position.supply_position, *coin_name);

            update_supply_reward(supply_position, coin_name, now, pool.supply_pool.total_value, none(), is_self);

            interest = process_withdraw(&mut pool.supply_pool, supply_position, amount, now, oper_type);

            if (supply_position.amount == 0) {
                let (_e, i) = vector::index_of(&position.supply_coins, coin_name);
                vector::remove(&mut position.supply_coins, i);

                table::remove(&mut position.supply_position, *coin_name);
            };

            update_pool_utilization(pool);
        } else if (oper_type == borrow_oper()) {
            assert!(amount > pool_config_ext::min_borrow_amount_with_coin_name(coin_name), ELESS_THAN_MIN_BORROW_LIMIT);

            let pool = table::borrow_mut(&mut protocol.pools, *coin_name);
            assert!(bit_vector::is_index_set(&pool.pause, index_borrow()), EPAUSE_BORROW);

            assert!(
                ((amount as u128) + pool.borrow_pool.total_value) <= (pool_config_ext::max_portion_borrow_with_coin_name(
                    coin_name
                ) as u128) * pool.supply_pool.total_value / 100,
                EMORE_THAN_MAX_PORTION_BORROW
            );

            let v_balance = *option::borrow(&reverse1);

            validate_balances(pool, position, amount, coin_name, v_balance, oper_type);

            if (!vector::contains(&position.borrow_coins, coin_name)) {
                let reward_coin_list = reward_config::reward_coin_list(coin_name);

                let i = 0;
                let len = vector::length(&reward_coin_list);

                let reserve2 = 0;
                let reserve4 = 0;

                while (i < len) {
                    let reward_coin_name = vector::borrow(&reward_coin_list, i);
                    let (reward_per_token, _) = rewards::update_borrow_reward(
                        coin_name,
                        reward_coin_name,
                        now,
                        pool.borrow_pool.total_value,
                        is_self
                    );

                    if (*reward_coin_name == coin_name_apn()) {
                        reserve2 = reward_per_token;
                    } else {
                        reserve4 = reward_per_token;
                    };

                    i = i + 1;
                };

                new_borrow_position(pool, position, coin_name, amount, reserve2, reserve4)
            } else {
                let borrow_position = table::borrow_mut(&mut position.borrow_position, *coin_name);

                update_borrow_reward(borrow_position, coin_name, now, pool.borrow_pool.total_value, none(), is_self);

                process_borrow(&mut pool.borrow_pool, borrow_position, amount, now, oper_type);
            };

            update_pool_utilization(pool);
        } else if (oper_type == repay_oper()) {
            assert!(amount > 0, EZERO_AMOUNT);

            let pool = table::borrow_mut(&mut protocol.pools, *coin_name);
            assert!(bit_vector::is_index_set(&pool.pause, index_repay()), EPAUSE_REPAY);

            if (!vector::contains(&position.borrow_coins, coin_name)) {
                abort EINVALID_REPAY
            };

            let borrow_position = table::borrow_mut(&mut position.borrow_position, *coin_name);

            update_borrow_reward(borrow_position, coin_name, now, pool.borrow_pool.total_value, none(), is_self);

            process_repay(&mut pool.borrow_pool, borrow_position, amount, now, oper_type);

            if (borrow_position.amount == 0) {
                let (_e, i) = vector::index_of(&position.borrow_coins, coin_name);
                vector::remove(&mut position.borrow_coins, i);

                table::remove(&mut position.borrow_position, *coin_name);
            };

            update_pool_utilization(pool);
        } else if (oper_type == liquidate_oper()) {
            if (option::is_none(&reverse1)) {
                abort EINVALID_AMOUNT_OUT
            };

            let amount_out = option::borrow(&reverse1);

            validate_liquidate(position);

            let coin_name_out = if (option::is_some(&reverse2)) {
                option::borrow(&reverse2)
            } else {
                coin_name
            };

            if (!vector::contains(&position.supply_coins, coin_name)) {
                abort EINVALID_WITHDRAW
            };

            if (!vector::contains(&position.borrow_coins, coin_name_out)) {
                abort EINVALID_REPAY
            };

            let supply_position = table::borrow_mut(&mut position.supply_position, *coin_name);

            let borrow_position = table::borrow_mut(&mut position.borrow_position, *coin_name_out);

            interest = process_liquidate(
                &mut protocol.pools,
                supply_position,
                borrow_position,
                amount,
                now,
                *amount_out,
                coin_name,
                coin_name_out
            );
        };

        let pool = table::borrow(&protocol.pools, *coin_name);

        let event_handle = borrow_global_mut<LendEventHandle>(pool_addr);
        event::emit_event<OperEvent>(&mut event_handle.oper_events, OperEvent {
            coin_name: *coin_name,
            oper_type: constant::oper_type(oper_type),
            amount,
            interest,
            supply_total_value: pool.supply_pool.total_value,
            supply_index: pool.supply_pool.index_interest,
            supply_last_update_time: pool.supply_pool.last_update_time_interest,
            borrow_total_value: pool.borrow_pool.total_value,
            borrow_index: pool.borrow_pool.index_interest,
            borrow_last_update_time: pool.borrow_pool.last_update_time_interest,
            utilization: pool.utilization,
            number_id: protocol.number_id
        });

        (interest, 0, if_charge_fee)
    }

    fun process_supply(
        supply_pool: &mut SupplyPool,
        supply_position: &mut SupplyPosition,
        amount: u64,
        ts: u64,
        oper_type: u8
    ): u64 {
        // add amount to position and return cumulative interest
        let interest = update_supply_position(supply_position, amount, 0, ts, option::some(oper_type));

        // add amount to pool
        update_supply_pool(supply_pool, 0, ts, amount, option::some(oper_type));

        interest
    }

    fun process_withdraw(
        supply_pool: &mut SupplyPool,
        supply_position: &mut SupplyPosition,
        amount: u64,
        ts: u64,
        oper_type: u8
    ): u64 {
        // minus amount from position and return cumulative interest for v-token
        let interest = update_supply_position(supply_position, amount, 0, ts, option::some(oper_type));

        // minus amount from pool
        update_supply_pool(supply_pool, 0, ts, amount, option::some(oper_type));

        interest
    }

    fun process_borrow(
        borrow_pool: &mut BorrowPool,
        borrow_position: &mut BorrowPosition,
        amount: u64,
        ts: u64,
        oper_type: u8
    ) {
        // add amount to position
        update_borrow_position(borrow_position, amount, 0, ts, option::some(oper_type));

        // add amount to pool
        update_borrow_pool(borrow_pool, 0, ts, amount, option::some(oper_type));
    }

    fun process_repay(
        borrow_pool: &mut BorrowPool,
        borrow_position: &mut BorrowPosition,
        amount: u64,
        ts: u64,
        oper_type: u8
    ) {
        // minus amount from position
        update_borrow_position(borrow_position, amount, 0, ts, option::some(oper_type));

        // minus amount from pool
        update_borrow_pool(borrow_pool, 0, ts, amount, option::some(oper_type));
    }

    fun process_liquidate(
        pools: &mut Table<String, Pool>,
        supply_position: &mut SupplyPosition,
        borrow_position: &mut BorrowPosition,
        amount_in: u64,
        ts: u64,
        amount_out: u64,
        coin_name: &String,
        coin_name_out: &String
    ): u64 {
        let interest =
            if (*coin_name == *coin_name_out) {
                let pool_in = table::borrow_mut(pools, *coin_name);

                update_supply_reward(
                    supply_position,
                    coin_name,
                    ts,
                    pool_in.supply_pool.total_value,
                    none(),
                    true
                );

                // withdraw
                let a = process_withdraw(&mut pool_in.supply_pool, supply_position, amount_in, ts, withdraw_oper());

                update_borrow_reward(
                    borrow_position,
                    coin_name,
                    ts,
                    pool_in.borrow_pool.total_value,
                    none(),
                    true
                );

                // repay
                process_repay(&mut pool_in.borrow_pool, borrow_position, amount_out, ts, repay_oper());

                update_pool_utilization(pool_in);

                a
            } else {
                let pool_in = table::borrow_mut(pools, *coin_name);

                update_supply_reward(
                    supply_position,
                    coin_name,
                    ts,
                    pool_in.supply_pool.total_value,
                    none(),
                    true
                );

                let b = process_withdraw(&mut pool_in.supply_pool, supply_position, amount_in, ts, withdraw_oper());
                update_pool_utilization(pool_in);

                let pool_out = table::borrow_mut(pools, *coin_name_out);

                update_borrow_reward(
                    borrow_position,
                    coin_name_out,
                    ts,
                    pool_out.borrow_pool.total_value,
                    none(),
                    true
                );

                process_repay(&mut pool_out.borrow_pool, borrow_position, amount_out, ts, repay_oper());
                update_pool_utilization(pool_out);

                b
            };

        interest
    }

    fun earned_supply(
        reward_per_token: u64,
        supply_position: &mut SupplyPosition,
        reward_coin_name: &String,
        decimals: u8
    ) {
        // let reward_config = reward_config4::reward_config(*coin_name, *reward_coin_name);

        if (*reward_coin_name == coin_name_apn()) {
            assert!(reward_per_token >= supply_position.reserve2, EREWARD_PER_TOKEN_PAID_POISONED);
            supply_position.reward = supply_position.amount * (reward_per_token - supply_position.reserve2) / pow_10(
                decimals
            ) + supply_position.reward;
            supply_position.reserve2 = reward_per_token;
        } else {
            assert!(reward_per_token >= supply_position.reserve4, EREWARD_PER_TOKEN_PAID_POISONED);
            supply_position.reserve3 = supply_position.amount * (reward_per_token - supply_position.reserve4) / pow_10(
                decimals
            ) + supply_position.reserve3;
            supply_position.reserve4 = reward_per_token;
        };

        supply_position.last_update_time_reward = timestamp::now_seconds();
    }

    fun earned_borrow(
        reward_per_token: u64,
        borrow_position: &mut BorrowPosition,
        reward_coin_name: &String,
        decimals: u8
    ) {
        // let reward_config = reward_config4::reward_config(*coin_name, *reward_coin_name);

        if (*reward_coin_name == coin_name_apn()) {
            assert!(reward_per_token >= borrow_position.reserve2, EREWARD_PER_TOKEN_PAID_POISONED);
            borrow_position.reward = borrow_position.amount * (reward_per_token - borrow_position.reserve2) / pow_10(
                decimals
            ) + borrow_position.reward;
            borrow_position.reserve2 = reward_per_token;
        } else {
            assert!(reward_per_token >= borrow_position.reserve4, EREWARD_PER_TOKEN_PAID_POISONED);
            borrow_position.reserve3 = borrow_position.amount * (reward_per_token - borrow_position.reserve4) / pow_10(
                decimals
            ) + borrow_position.reserve3;
            borrow_position.reserve4 = reward_per_token;
        };

        borrow_position.last_update_time_reward = timestamp::now_seconds();
    }

    fun update_supply_reward(
        supply_position: &mut SupplyPosition,
        coin_name: &String,
        now: u64,
        total_amount: u128,
        reward_coin_name: Option<String>,
        is_self: bool
    ) {
        if (option::is_none(&reward_coin_name)) {
            let reward_coin_list = reward_config::reward_coin_list(coin_name);
            let i = 0;
            let len = vector::length(&reward_coin_list);

            while (i < len) {
                let reward_coin_name = vector::borrow(&reward_coin_list, i);
                i = i + 1;

                let reward_config = reward_config::reward_config(*coin_name, *reward_coin_name);

                if (supply_position.last_update_time_reward > reward_config::end_time(&reward_config)) continue;

                let (reward_per_token, decimals) = rewards::update_supply_reward(
                    coin_name,
                    reward_coin_name,
                    now,
                    total_amount,
                    is_self
                );

                earned_supply(reward_per_token, supply_position, reward_coin_name, decimals);
            }
        } else {
            let reward_coin_name = option::borrow(&reward_coin_name);

            let reward_config = reward_config::reward_config(*coin_name, *reward_coin_name);

            if (supply_position.last_update_time_reward > reward_config::end_time(&reward_config)) return;

            let (reward_per_token, decimals) = rewards::update_supply_reward(
                coin_name,
                reward_coin_name,
                now,
                total_amount,
                is_self
            );

            earned_supply(reward_per_token, supply_position, reward_coin_name, decimals)
        };
    }

    fun update_borrow_reward(
        borrow_position: &mut BorrowPosition,
        coin_name: &String,
        now: u64,
        total_amount: u128,
        reward_coin_name: Option<String>,
        is_self: bool
    ) {
        if (option::is_none(&reward_coin_name)) {
            let reward_coin_list = reward_config::reward_coin_list(coin_name);
            let i = 0;
            let len = vector::length(&reward_coin_list);

            while (i < len) {
                let reward_coin_name = vector::borrow(&reward_coin_list, i);
                i = i + 1;

                let reward_config = reward_config::reward_config(*coin_name, *reward_coin_name);

                if (borrow_position.last_update_time_reward > reward_config::end_time(&reward_config)) continue;

                let (reward_per_token, decimals) = rewards::update_borrow_reward(
                    coin_name,
                    reward_coin_name,
                    now,
                    total_amount,
                    is_self
                );

                earned_borrow(reward_per_token, borrow_position, reward_coin_name, decimals);
            }
        } else {
            let reward_coin_name = option::borrow(&reward_coin_name);

            let reward_config = reward_config::reward_config(*coin_name, *reward_coin_name);

            if (borrow_position.last_update_time_reward > reward_config::end_time(&reward_config)) return;

            let (reward_per_token, decimals) = rewards::update_borrow_reward(
                coin_name,
                reward_coin_name,
                now,
                total_amount,
                is_self
            );

            earned_borrow(reward_per_token, borrow_position, reward_coin_name, decimals);
        }
    }

    public(friend) fun clear_reserve3_by_user<C>(pool_addr: address, user_addr: address) acquires Positions {
        assert!(exists<LendProtocol>(pool_addr), ENOT_PUBLISH_PROTOCOL);

        let coin_name = type_name<C>();

        assert!(exists<Positions>(user_addr), ENOT_PUBLISH_USER_POSITION);
        let position = borrow_global_mut<Positions>(user_addr);

        if (table::contains(&position.supply_position, coin_name)) {
            let supply_position = table::borrow_mut(&mut position.supply_position, coin_name);
            supply_position.reserve3 = 0;
            supply_position.reserve4 = 0;
        };

        if (table::contains(&position.borrow_position, coin_name)) {
            let borrow_position = table::borrow_mut(&mut position.borrow_position, coin_name);
            borrow_position.reserve3 = 0;
            borrow_position.reserve4 = 0;
        };
    }

    public(friend) fun clear_reserve3<C>(pool_addr: address) acquires LendProtocol, Positions {
        assert!(exists<LendProtocol>(pool_addr), ENOT_PUBLISH_PROTOCOL);

        let protocol = borrow_global_mut<LendProtocol>(pool_addr);

        let coin_name = type_name<C>();
        assert!(table::contains(&protocol.pools, coin_name), ENOT_SUPPORT_COIN);

        let i = 0;
        let slot = slot(protocol.number_id);
        while (i <= slot) {
            let user_list = table::borrow(&protocol.users, i);

            let j = 0;
            let len = vector::length(user_list);

            while (j < len) {
                let user_addr = *vector::borrow(user_list, j);

                assert!(exists<Positions>(user_addr), ENOT_PUBLISH_USER_POSITION);
                let position = borrow_global_mut<Positions>(user_addr);

                if (table::contains(&position.supply_position, coin_name)) {
                    let supply_position = table::borrow_mut(&mut position.supply_position, coin_name);
                    supply_position.reserve3 = 0;
                };

                if (table::contains(&position.borrow_position, coin_name)) {
                    let borrow_position = table::borrow_mut(&mut position.borrow_position, coin_name);
                    borrow_position.reserve3 = 0;
                };

                j = j + 1;
            };

            i = i + 1;
        }
    }

    fun claim_supply_reward_by_position(
        supply_position: &mut SupplyPosition,
        coin_name: &String,
        reward_coin_name: String,
        total_value: u128
    ): u64 {
        update_supply_reward(
            supply_position,
            coin_name,
            timestamp::now_seconds(),
            total_value,
            some(reward_coin_name),
            false
        );

        let reward =
            if (reward_coin_name == coin_name_apn()) {
                let r = supply_position.reward;
                supply_position.reward = 0;
                supply_position.reserve2 = 0;
                r
            } else {
                let r = supply_position.reserve3;
                supply_position.reserve3 = 0;
                supply_position.reserve4 = 0;
                r
            };

        reward
    }

    fun claim_borrow_reward_by_position(
        borrow_position: &mut BorrowPosition,
        coin_name: &String,
        reward_coin_name: String,
        total_value: u128
    ): u64 {
        update_borrow_reward(
            borrow_position,
            coin_name,
            timestamp::now_seconds(),
            total_value,
            some(reward_coin_name),
            false
        );

        let reward =
        if (reward_coin_name == coin_name_apn()) {
            let r = borrow_position.reward;
            borrow_position.reward = 0;
            borrow_position.reserve2 = 0;
            r
        } else {
            let r = borrow_position.reserve3;
            borrow_position.reserve3 = 0;
            borrow_position.reserve4 = 0;
            r
        };

        reward
    }

    fun transfer_reward<C, R>(from: &signer, to: address, amount: u64) {
        if (amount > 0) {
            let balance = coin::balance<R>(signer::address_of(from));
            assert!(balance >= amount, EINSUFFICIENT_BALANCE_TO_CLAIM);

            aptos_account::transfer_coins<R>(from, to, amount);
        };

        let event = ClaimRewards {
            source_coin_name: type_name<C>(),
            reward_coin_name: type_name<R>(),
            user_addr: to,
            rewards: amount
        };

        event::emit(event);
    }

    public(friend) fun process_claim_by_subset<C, R>(
        account: &signer,
        reward_resource_signer: &signer,
        pool_addr: address,
        subset_id: u64,
        slot: u64
    ) acquires LendProtocol, Positions {
        assert!(exists<LendProtocol>(pool_addr), ENOT_PUBLISH_PROTOCOL);

        let protocol = borrow_global<LendProtocol>(pool_addr);

        assert!(slot <= slot(protocol.number_id), EINVALID_SLOT);

        let users = table::borrow(&protocol.users, slot);

        let coin_name = type_name<C>();
        let reward_coin_name = type_name<R>();

        let start = subset_id * LENGHT_SUBSET;
        let end = math::min_u64((subset_id + 1) * LENGHT_SUBSET, vector::length(users));

        let pool = table::borrow(&protocol.pools, coin_name);

        let total_supply = pool.supply_pool.total_value;
        let total_borrow = pool.borrow_pool.total_value;

        while (start < end) {
            let (r0, r1) = (0, 0);

            let user_addr = *vector::borrow(users, start);
            assert!(exists<Positions>(user_addr), ENOT_PUBLISH_USER_POSITION);

            let position = borrow_global_mut<Positions>(user_addr);

            if (table::contains(&position.supply_position, coin_name)) {
                let supply_position = table::borrow_mut(&mut position.supply_position, coin_name);
                r0 = claim_supply_reward_by_position(supply_position, &coin_name, reward_coin_name, total_supply);
            };

            if (table::contains(&position.borrow_position, coin_name)) {
                let borrow_position = table::borrow_mut(&mut position.borrow_position, coin_name);
                r1 = claim_borrow_reward_by_position(borrow_position, &coin_name, reward_coin_name, total_borrow);
            };

            transfer_reward<C, R>(reward_resource_signer, user_addr, r0 + r1);

            start = start + 1;
        };

        if (((slot * SIZE_OF_SLOT + subset_id * LENGHT_SUBSET as u128) <= protocol.number_id)
            && ((slot * SIZE_OF_SLOT + (subset_id + 1) * LENGHT_SUBSET as u128) > protocol.number_id)
        ) {
            reward_config::stop<C, R>(account);
        }
    }

    // todo: set reward to 0, and set pause to true
    public(friend) fun process_claim<C, R>(account: &signer, pool_addr: address) acquires LendProtocol, Positions {
        assert!(exists<LendProtocol>(pool_addr), ENOT_PUBLISH_PROTOCOL);

        let protocol = borrow_global_mut<LendProtocol>(pool_addr);

        let coin_name = type_name<C>();
        assert!(table::contains(&protocol.pools, coin_name), ENOT_SUPPORT_COIN);

        let i = 0;
        let slot = slot(protocol.number_id);
        while (i <= slot) {
            let user_list = table::borrow(&protocol.users, i);

            let j = 0;
            let len = vector::length(user_list);

            while (j < len) {
                let user_addr = *vector::borrow(user_list, j);

                assert!(exists<Positions>(user_addr), ENOT_PUBLISH_USER_POSITION);
                let position = borrow_global_mut<Positions>(user_addr);

                let reward0 = 0;
                let reward1 = 0;
                let now = timestamp::now_seconds();
                let reward_coin_name = type_name<R>();

                // supply
                let pool = table::borrow_mut(&mut protocol.pools, coin_name);
                if (table::contains(&position.supply_position, coin_name)) {
                    let supply_position = table::borrow_mut(&mut position.supply_position, coin_name);

                    update_supply_reward(
                        supply_position,
                        &coin_name,
                        now,
                        pool.supply_pool.total_value,
                        some(reward_coin_name),
                        false
                    );

                    if (reward_coin_name == coin_name_apn()) {
                        reward0 = supply_position.reward;
                        supply_position.reward = 0;
                        supply_position.reserve2 = 0;
                    } else {
                        reward0 = supply_position.reserve3;
                        supply_position.reserve3 = 0;
                        supply_position.reserve4 = 0;
                    }
                };

                if (table::contains(&position.borrow_position, coin_name)) {
                    let borrow_position = table::borrow_mut(&mut position.borrow_position, coin_name);
                    update_borrow_reward(
                        borrow_position,
                        &coin_name,
                        now,
                        pool.borrow_pool.total_value,
                        some(reward_coin_name),
                        false
                    );

                    if (reward_coin_name == coin_name_apn()) {
                        reward1 = borrow_position.reward;
                        borrow_position.reward = 0;
                        borrow_position.reserve2 = 0;
                    } else {
                        reward1 = borrow_position.reserve3;
                        borrow_position.reserve3 = 0;
                        borrow_position.reserve4 = 0;
                    }
                };

                if (reward0 + reward1 > 0) {
                    let balance = coin::balance<R>(signer::address_of(account));
                    assert!(balance >= reward0 + reward1, EINSUFFICIENT_BALANCE_TO_CLAIM);

                    aptos_account::transfer_coins<R>(account, user_addr, reward0 + reward1);
                };

                let event = ClaimRewards {
                    source_coin_name: coin_name,
                    reward_coin_name,
                    user_addr,
                    rewards: reward0 + reward1
                };

                event::emit(event);

                j = j + 1;
            };

            i = i + 1;
        };
    }

    fun slot(number_id: u128): u64 {
        math::mul_div_u128(number_id, 1, (SIZE_OF_SLOT as u128))
    }

    fun check_users(
        protocol: &mut LendProtocol,
        registered: &mut bool,
        slot: &mut u64,
        user_addr: address,
        oper_type: u8
    ): bool {
        // it means that user is newer
        if (*registered == false) {
            if (oper_type == supply_oper()) {
                *slot = slot(protocol.number_id);
                if (!table::contains(&mut protocol.users, *slot)) {
                    // add
                    let vs = vector::empty();
                    vector::push_back(&mut vs, user_addr);
                    table::add(&mut protocol.users, *slot, vs);

                    protocol.number_id = protocol.number_id + 1;

                    *registered = true;

                    return false
                } else {
                    let users = table::borrow_mut(&mut protocol.users, *slot);

                    vector::push_back(users, user_addr);

                    protocol.number_id = protocol.number_id + 1;

                    *registered = true;

                    return false
                }
            } else {
                abort EINVALID_USER
            }
        };

        true
    }

    fun new_supply_position(
        pool: &mut Pool,
        positions: &mut Positions,
        coin_name: &String,
        amount: u64,
        collateral: Option<u64>,
        resv2: u64,
        resv4: u64
    ) {
        let collateral = if (*option::borrow(&collateral) == 1) {
            true
        } else {
            false
        };

        let now = timestamp::now_seconds();

        // update when first user join in pool
        if (pool.supply_pool.last_update_time_interest == 0) {
            pool.supply_pool.last_update_time_interest = now;
            pool.supply_pool.total_value = (amount as u128);
        } else {
            // first step: update index of current pool
            let index_supply = supply_index(pool, coin_name, now);
            let index_borrow = borrow_index(pool, coin_name, now);
            update_pool_interest(pool, index_supply, index_borrow, amount, 0, now);
        };

        table::add(&mut positions.supply_position, *coin_name, SupplyPosition {
            amount,
            interest: 0,
            last_update_time_interest: now,
            collateral,
            reward: 0,
            last_update_time_reward: 0,
            index_interest: pool.supply_pool.index_interest,
            reserve1: 0,
            reserve2: resv2,
            reserve3: 0,
            reserve4: resv4,
        });

        vector::push_back(&mut positions.supply_coins, *coin_name);
    }

    fun new_borrow_position(
        pool: &mut Pool,
        positions: &mut Positions,
        coin_name: &String,
        amount: u64,
        resv2: u64,
        resv4: u64
    ) {
        let now = timestamp::now_seconds();

        // update when first user join in pool
        if (pool.borrow_pool.last_update_time_interest == 0) {
            pool.borrow_pool.last_update_time_interest = now;
            pool.borrow_pool.total_value = (amount as u128);
            pool.supply_pool.last_update_time_interest = now;
        } else {
            let index_borrow = borrow_index(pool, coin_name, now);
            let index_supply = supply_index(pool, coin_name, now);
            update_pool_interest(pool, index_supply, index_borrow, 0, amount, now);
        };

        table::add(&mut positions.borrow_position, *coin_name, BorrowPosition {
            amount,
            interest: 0,
            last_update_time_interest: now,
            reward: 0,
            last_update_time_reward: 0,
            index_interest: pool.borrow_pool.index_interest,
            reserve1: 0,
            reserve2: resv2,
            reserve3: 0,
            reserve4: resv4,
        });

        vector::push_back(&mut positions.borrow_coins, *coin_name);

        // pool.borrow_pool.total_value = pool.borrow_pool.total_value + (amount as u128);
    }

    fun update_supply_position(
        supply_position: &mut SupplyPosition,
        amount: u64,
        index: u128,
        ts: u64,
        oper_type: Option<u8>
    ): u64 {
        let interest = 0;
        if (option::is_none(&oper_type)) {
            let linear_annuity = math::mul_div_u128(
                (supply_position.amount as u128),
                index,
                supply_position.index_interest
            );

            // linear_annuity MUST be greater than amount
            interest = linear_annuity - supply_position.amount;

            supply_position.interest = supply_position.interest + interest;
            supply_position.index_interest = index;
            supply_position.last_update_time_interest = ts;
            supply_position.amount = supply_position.amount + interest;
        } else {
            let oper_type = option::borrow(&oper_type);

            if (*oper_type == supply_oper()) {
                supply_position.amount = supply_position.amount + amount;
                interest = supply_position.interest;
                supply_position.interest = 0;
            } else if (*oper_type == withdraw_oper()) {
                assert!(supply_position.amount >= amount, error::invalid_argument(EINSUFFICIENT_TO_WITHDRAW));
                supply_position.amount = supply_position.amount - amount;
                interest = supply_position.interest;
                supply_position.interest = 0;
            }
        };
        interest
    }

    fun update_borrow_position(
        borrow_position: &mut BorrowPosition,
        amount: u64,
        index: u128,
        ts: u64,
        oper_type: Option<u8>
    ): u64 {
        let interest = 0;
        if (option::is_none(&oper_type)) {
            let linear_annuity = math::mul_div_u128(
                (borrow_position.amount as u128),
                index,
                borrow_position.index_interest
            );

            // linear_annuity MUST be greater than amount
            interest = linear_annuity - borrow_position.amount + 1;

            borrow_position.interest = borrow_position.interest + interest;
            borrow_position.index_interest = index;
            borrow_position.last_update_time_interest = ts;
            borrow_position.amount = borrow_position.amount + interest;
        } else {
            let oper_type = option::borrow(&oper_type);
            if (*oper_type == borrow_oper()) {
                borrow_position.amount = borrow_position.amount + amount;
                interest = borrow_position.interest;
                borrow_position.interest = 0;
            } else if (*oper_type == repay_oper()) {
                assert!(borrow_position.amount >= amount, error::invalid_argument(EEXCEED_TO_REPAY));
                borrow_position.amount = borrow_position.amount - amount;
                if (borrow_position.amount == 1) {
                    borrow_position.amount = 0
                };
                interest = borrow_position.interest;
                borrow_position.interest = 0;
            }
        };
        interest
    }

    fun update_supply_pool(supply_pool: &mut SupplyPool, index: u128, ts: u64, amount: u64, oper_type: Option<u8>) {
        if (option::is_none(&oper_type)) {
            let interest = supply_pool.total_value * index / supply_pool.index_interest - supply_pool.total_value;

            supply_pool.index_interest = index;
            supply_pool.last_update_time_interest = ts;
            supply_pool.total_value = supply_pool.total_value + (amount as u128) + interest;
        } else {
            let oper_type = option::borrow(&oper_type);
            if (*oper_type == supply_oper()) {
                supply_pool.total_value = supply_pool.total_value + (amount as u128)
            } else if (*oper_type == withdraw_oper()) {
                supply_pool.total_value = supply_pool.total_value - (amount as u128)
            } else {
                abort ENOT_SUPPORT_OPERATION
            }
        }
    }

    fun update_borrow_pool(borrow_pool: &mut BorrowPool, index: u128, ts: u64, amount: u64, oper_type: Option<u8>) {
        if (option::is_none(&oper_type)) {
            let interest = borrow_pool.total_value * index / borrow_pool.index_interest - borrow_pool.total_value;

            borrow_pool.index_interest = index;
            borrow_pool.last_update_time_interest = ts;
            borrow_pool.total_value = borrow_pool.total_value + (amount as u128) + interest;
        } else {
            let oper_type = option::borrow(&oper_type);

            if (*oper_type == borrow_oper()) {
                borrow_pool.total_value = borrow_pool.total_value + (amount as u128)
            } else if (*oper_type == repay_oper()) {
                if ((amount as u128) < borrow_pool.total_value) {
                    borrow_pool.total_value = borrow_pool.total_value - (amount as u128)
                } else {
                    borrow_pool.total_value = 0
                }
            } else {
                abort ENOT_SUPPORT_OPERATION
            };
        };
    }

    fun update_pool_utilization(pool: &mut Pool) {
        pool.utilization = calc_utilization(pool.borrow_pool.total_value, pool.supply_pool.total_value);
    }

    fun update_interest(pools: &mut Table<String, Pool>, position: &mut Positions) {
        let i = 0;
        let len = vector::length(&position.supply_coins);
        while (i < len) {
            let coin_name = vector::borrow(&position.supply_coins, i);

            let now = timestamp::now_seconds();
            let pool = table::borrow_mut(pools, *coin_name);

            let supply_position = table::borrow_mut(&mut position.supply_position, *coin_name);

            // update_supply_interest(supply_position, pool, coin_name, now);
            let index_supply = supply_index(pool, coin_name, now);
            let index_borrow = borrow_index(pool, coin_name, now);

            update_supply_position(supply_position, 0, index_supply, now, option::none());

            if (vector::contains(&position.borrow_coins, coin_name)) {
                let borrow_position = table::borrow_mut(&mut position.borrow_position, *coin_name);

                update_borrow_position(borrow_position, 0, index_borrow, now, option::none());
            };

            update_pool_interest(pool, index_supply, index_borrow, 0, 0, now);

            // calc utilization when end of each coin
            update_pool_utilization(pool);

            i = i + 1;
        };

        let i = 0;
        let len = vector::length(&position.borrow_coins);
        while (i < len) {
            let coin_name = vector::borrow(&position.borrow_coins, i);

            if (!vector::contains(&position.supply_coins, coin_name)) {
                let now = timestamp::now_seconds();
                let pool = table::borrow_mut(pools, *coin_name);

                let index_supply = supply_index(pool, coin_name, now);
                let index_borrow = borrow_index(pool, coin_name, now);

                let borrow_position = table::borrow_mut(&mut position.borrow_position, *coin_name);

                update_borrow_position(borrow_position, 0, index_borrow, now, option::none());

                update_pool_interest(pool, index_supply, index_borrow, 0, 0, now);

                // calc utilization when end of each coin
                update_pool_utilization(pool);
            };

            i = i + 1;
        }
    }

    fun update_pool_interest(
        pool: &mut Pool,
        index_supply: u128,
        index_borrow: u128,
        amt_supply: u64,
        amt_borrow: u64,
        ts: u64
    ) {
        update_supply_pool(&mut pool.supply_pool, index_supply, ts, amt_supply, option::none());
        update_borrow_pool(&mut pool.borrow_pool, index_borrow, ts, amt_borrow, option::none());
    }

    fun supply_index(pool: &Pool, coin_name: &String, ts: u64): u128 {
        let diff_time = if (pool.supply_pool.last_update_time_interest == 0) {
            0
        } else {
            ts - pool.supply_pool.last_update_time_interest
        };

        calc_supply_index(
            pool.utilization,
            diff_time,
            pool.supply_pool.index_interest,
            coin_name
        )
    }

    fun borrow_index(pool: &Pool, coin_name: &String, ts: u64): u128 {
        let diff_time = if (pool.borrow_pool.last_update_time_interest == 0) {
            0
        } else {
            ts - pool.borrow_pool.last_update_time_interest
        };

        calc_borrow_index(
            pool.utilization,
            diff_time,
            pool.borrow_pool.index_interest,
            coin_name
        )
    }

    fun value(amount: u64, n: u64, m: u64): u64 {
        if (amount == 0) return 0;

        let v = math::mul_div(amount, n, math::pow_10((m as u8)));
        if ( v == 0) v = 1;
        v
    }

    fun value_ltv(amount: u64, coin_name: &String): (u64) {
        if (amount == 0) return 0;

        let v = math::mul_div(amount, (pool_config::ltv_with_coin_name(coin_name) as u64), THRESHOLD_DENOMINATOR);
        v
    }

    fun balances_of(position: &Positions): (u64, u64) {
        let i = 0;
        let len = vector::length(&position.supply_coins);
        let total_supply_value = 0;
        let total_borrow_value = 0;
        while (i < len) {
            let coin_name = vector::borrow(&position.supply_coins, i);

            let (n, m) = prices::get_price(coin_name);

            let supply_position = table::borrow(&position.supply_position, *coin_name);

            if (supply_position.collateral) {
                total_supply_value = total_supply_value + value_ltv(value(supply_position.amount, n, m), coin_name);
            };

            if (vector::contains(&position.borrow_coins, coin_name)) {
                let borrow_position = table::borrow(&position.borrow_position, *coin_name);

                total_borrow_value = total_borrow_value + value(borrow_position.amount, n, m);
            };

            i = i + 1;
        };

        let i = 0;
        let len = vector::length(&position.borrow_coins);
        while (i < len) {
            let coin_name = vector::borrow(&position.borrow_coins, i);

            if (!vector::contains(&position.supply_coins, coin_name)) {
                let (n, m) = prices::get_price(coin_name);
                let borrow_position = table::borrow(&position.borrow_position, *coin_name);

                total_borrow_value = total_borrow_value + value(borrow_position.amount, n, m);
            };
            i = i + 1;
        };

        (total_supply_value, total_borrow_value)
    }

    fun validate_liquidate(position: &Positions) {
        let (total_supply, total_borrow) = balances_of(position);

        assert!(math::mul_div(total_supply, LIQUIDATE_THRESHOLD, THRESHOLD_DENOMINATOR) <= total_borrow, ENOT_SATISFY_LIQUIDATE);
    }

    fun validate_balances(
        pool: &Pool,
        position: &Positions,
        amount: u64,
        coin_name: &String,
        v_balance: u64,
        oper_type: u8
    ) {
        // check pool
        assert!(
            pool.supply_pool.total_value > (pool.borrow_pool.total_value + (amount as u128)),
            EINSUFFICIENT_TO_BORROW
        );

        let (total_supply_value, total_borrow_value) = balances_of(position);

        if (oper_type == withdraw_oper() && total_borrow_value == 0) {
            return
        };

        // event::emit(ValidateBalance{
        //     borrow_value: total_borrow_value,
        //     supply_value: total_supply_value
        // });

        let (n, m) = prices::get_price(coin_name);

        let borrow_value = value(amount, n, m);
        // assert!(borrow_value > 1, ELESSTHAN_ONE_DOLLAR);

        total_borrow_value = total_borrow_value + borrow_value;

        total_supply_value = total_supply_value - value_ltv(value(v_balance, n, m), coin_name);

        // event::emit(Value {
        //    amount,
        //     n,
        //     m,
        //     v: value(amount, n, m)
        // });
        //
        // event::emit(ValidateBalance{
        //     borrow_value: total_borrow_value,
        //     supply_value: total_supply_value
        // });


        assert!(total_supply_value > total_borrow_value, EEXCEED_LIMIT_TO_BORROW)
    }

    public(friend) fun process_traverse(
        pool_addr: address,
        subset_id: u64,
        slot: u64
    ) acquires LendProtocol, Positions {
        assert!(exists<LendProtocol>(pool_addr), ENOT_PUBLISH_PROTOCOL);

        let protocol = borrow_global_mut<LendProtocol>(pool_addr);

        assert!(slot <= slot(protocol.number_id), EINVALID_SLOT);

        let users = table::borrow(&protocol.users, slot);

        let start = subset_id * LENGHT_SUBSET;
        let len = vector::length(users);
        let end = math::min_u64((subset_id + 1) * LENGHT_SUBSET, len);

        if (start == 0 && slot == 0) {
            set_reverse(&mut protocol.pools, &protocol.coins)
        };

        while (start < end) {
            let user_addr = vector::borrow(users, start);
            start = start + 1;

            // assert!(exists<Positions>(*user_addr), ENOT_PUBLISH_USER_POSITION);
            if (!exists<Positions>(*user_addr)) continue;

            let position = borrow_global_mut<Positions>(*user_addr);

            if (vector::is_empty(&position.supply_coins)) continue;

            traverse_position(&protocol.pools, position);
        };

        if (((slot * SIZE_OF_SLOT + subset_id * LENGHT_SUBSET as u128) <= protocol.number_id)
            && ((slot * SIZE_OF_SLOT + (subset_id + 1) * LENGHT_SUBSET as u128) > protocol.number_id))
            {
                reset_reverse(&mut protocol.pools, &protocol.coins)
            }
    }

    fun set_reverse(pools: &mut Table<String, Pool>, coins: &vector<String>) {
        let i = 0;
        let len = vector::length(coins);
        while (i < len) {
            let coin = vector::borrow(coins, i);
            let pool = table::borrow_mut(pools, *coin);

            let now = timestamp::now_seconds();

            let index_supply = supply_index(pool, coin, now);
            let index_borrow = borrow_index(pool, coin, now);

            update_pool_interest(pool, index_supply, index_borrow, 0, 0, now);

            // calc utilization when end of each coin
            update_pool_utilization(pool);

            update_pool_reverse(pool, index_supply, index_borrow, now);

            event::emit(TravalPool {
                action: string::utf8(b"SET-ITEREST-INDEX"),
                coin_name: *coin,
                supply_interest_index: pool.supply_pool.reverse2,
                borrow_interest_index: pool.borrow_pool.reverse2,
                execute_time: pool.reverse1
            });

            i = i + 1;
        }
    }

    fun reset_reverse(pools: &mut Table<String, Pool>, coins: &vector<String>) {
        let i = 0;
        let len = vector::length(coins);
        while (i < len) {
            let coin = vector::borrow(coins, i);
            let pool = table::borrow_mut(pools, *coin);

            update_pool_reverse(pool, 0, 0, 0);

            event::emit(TravalPool {
                action: string::utf8(b"RESET-ITEREST-INDEX"),
                coin_name: *coin,
                supply_interest_index: pool.supply_pool.reverse2,
                borrow_interest_index: pool.borrow_pool.reverse2,
                execute_time: pool.reverse1
            });

            i = i + 1;
        }
    }

    // fun traverse_position(pools: &mut Table<String, Pool>, position: &mut Positions) {
    fun traverse_position(pools: &Table<String, Pool>, position: &mut Positions) {
        let i = 0;
        let len = vector::length(&position.supply_coins);
        while (i < len) {
            let coin_name = vector::borrow(&position.supply_coins, i);
            i = i + 1;

            // let pool = table::borrow_mut(pools, *coin_name);
            let pool = table::borrow(pools, *coin_name);

            let now = pool.reverse1;

            let supply_position = table::borrow_mut(&mut position.supply_position, *coin_name);

            if (now <= supply_position.last_update_time_interest) continue;

            let index_supply = pool.supply_pool.reverse2;
            let index_borrow = pool.borrow_pool.reverse2;

            let diff = now - supply_position.last_update_time_interest;
            let min_traverse_amount = math::mul_div_u128(pool.supply_pool.total_value, 1, 10000);


            if (diff > SECONDS_PER_WEEK || supply_position.amount > min_traverse_amount) {
                update_supply_position(supply_position, 0, index_supply, now, option::none());
            };

            if (vector::contains(&position.borrow_coins, coin_name)) {
                let borrow_position = table::borrow_mut(&mut position.borrow_position, *coin_name);

                if (now <= borrow_position.last_update_time_interest) continue;

                let diff = now - borrow_position.last_update_time_interest;
                let min_traverse_amount = math::mul_div_u128(pool.borrow_pool.total_value, 1, 10000);

                if (diff > SECONDS_PER_WEEK || borrow_position.amount > min_traverse_amount) {
                    update_borrow_position(borrow_position, 0, index_borrow, now, option::none());
                }
            };
        };

        let i = 0;
        let len = vector::length(&position.borrow_coins);
        while (i < len) {
            let coin_name = vector::borrow(&position.borrow_coins, i);
            i = i + 1;

            if (!vector::contains(&position.supply_coins, coin_name)) {
                // let pool = table::borrow_mut(pools, *coin_name);
                let pool = table::borrow(pools, *coin_name);

                let now = pool.reverse1;

                let borrow_position = table::borrow_mut(&mut position.borrow_position, *coin_name);

                if (now <= borrow_position.last_update_time_interest) continue;

                let index_borrow = pool.borrow_pool.reverse2;

                let diff = now - borrow_position.last_update_time_interest;
                let min_traverse_amount = math::mul_div_u128(pool.borrow_pool.total_value, 1, 3);

                if (diff > SECONDS_PER_WEEK || borrow_position.amount > min_traverse_amount) {
                    update_borrow_position(borrow_position, 0, index_borrow, now, option::none());
                }
            };
        }
    }

    fun update_pool_reverse(pool: &mut Pool, index_supply: u128, index_borrow: u128, ts: u64) {
        pool.reverse1 = ts;
        pool.supply_pool.reverse2 = index_supply;
        pool.borrow_pool.reverse2 = index_borrow;
    }

    public(friend) fun enable_pool(pool_addr: address, pos: u64, coin_name: &String) acquires LendProtocol {
        assert!(exists<LendProtocol>(pool_addr), error::not_found(ENOT_PUBLISH_PROTOCOL));

        let protocol = borrow_global_mut<LendProtocol>(pool_addr);

        let pool = table::borrow_mut(&mut protocol.pools, *coin_name);

        bit_vector::set(&mut pool.pause, pos)
    }

    public(friend) fun disable_pool(pool_addr: address, pos: u64, coin_name: &String) acquires LendProtocol {
        assert!(exists<LendProtocol>(pool_addr), error::not_found(ENOT_PUBLISH_PROTOCOL));

        let protocol = borrow_global_mut<LendProtocol>(pool_addr);

        let pool = table::borrow_mut(&mut protocol.pools, *coin_name);

        bit_vector::unset(&mut pool.pause, pos)
    }

    public(friend) fun unpause_all(pool_addr: address, pos: u64) acquires  LendProtocol {
        assert!(exists<LendProtocol>(pool_addr), error::not_found(ENOT_PUBLISH_PROTOCOL));

        let protocol = borrow_global_mut<LendProtocol>(pool_addr);

        let len = vector::length(&protocol.coins);
        let i = 0;
        while (i < len) {
            let coin_name = vector::borrow(&protocol.coins, i);

            let pool = table::borrow_mut(&mut protocol.pools, *coin_name);

            bit_vector::set(&mut pool.pause, pos);

            i = i + 1;
        }
    }

    public(friend) fun pause_all(pool_addr: address, pos: u64) acquires  LendProtocol {
        assert!(exists<LendProtocol>(pool_addr), error::not_found(ENOT_PUBLISH_PROTOCOL));

        let protocol = borrow_global_mut<LendProtocol>(pool_addr);

        let len = vector::length(&protocol.coins);
        let i = 0;
        while (i < len) {
            let coin_name = vector::borrow(&protocol.coins, i);

            let pool = table::borrow_mut(&mut protocol.pools, *coin_name);

            bit_vector::unset(&mut pool.pause, pos);

            i = i + 1;
        }

    }

    public(friend) fun traverse_pool(
        pool_addr: address,
        subset_id: u64,
        slot: u64
    ): vector<UserInfo> acquires LendProtocol, Positions {
        assert!(exists<LendProtocol>(pool_addr), ENOT_PUBLISH_PROTOCOL);

        let protocol = borrow_global_mut<LendProtocol>(pool_addr);

        assert!(slot <= slot(protocol.number_id), EINVALID_SLOT);

        let users = table::borrow(&protocol.users, slot);

        let start = subset_id * LENGHT_SUBSET;
        let len = vector::length(users);
        let end = math::min_u64((subset_id + 1) * LENGHT_SUBSET, len);

        // assert!(end <= SIZE_OF_SLOT, EINVALID_SUBSET);

        let result = vector::empty<UserInfo>();

        while (start < end) {
            let user_addr = vector::borrow(users, start);
            start = start + 1;

            if (!exists<Positions>(*user_addr)) continue;

            let position = borrow_global_mut<Positions>(*user_addr);

            if (vector::is_empty(&position.supply_coins)) continue;

            let i = 0;
            let length = vector::length(&protocol.coins);
            while(i < length) {
                let coin_name = vector::borrow(&protocol.coins, i);
                
                let supply_amount = 0;
                let borrow_amount = 0;
                
                if (table::contains(&position.supply_position, *coin_name)) {
                    let supply_position = table::borrow(&position.supply_position, *coin_name);
                    supply_amount = supply_position.amount;
                };
                
                if (table::contains(&position.borrow_position, *coin_name)) {
                    let borrow_position = table::borrow(&position.borrow_position, *coin_name);
                    borrow_amount = borrow_position.amount;
                };
                
                let (n, m) = prices::get_price(coin_name);
                let supply_value = value(supply_amount, n, m);

                if (supply_value > 1 || borrow_amount > 0) {
                
                    vector::push_back(&mut result, UserInfo {
                        address: *user_addr,
                        coin_index: i,
                        supply_amount,
                        borrow_amount,
                    });
                };
                
                i = i + 1;
            };
        };

        result
    }



    #[test_only]
    public fun pool_balance<C>(pool_addr: address, ty: u8): u128 acquires LendProtocol {
        let coin_name = type_name<C>();
        let protocol = borrow_global<LendProtocol>(pool_addr);
        let pool = table::borrow(&protocol.pools, coin_name);
        if (ty == 0) {
            // Supply pool
            pool.supply_pool.total_value
        } else {
            // Borrow pool
            pool.borrow_pool.total_value
        }
    }

    #[test_only]
    public fun increase_protocol_id(pool_addr: address, additional_id: u64) acquires LendProtocol {
        let protocol = borrow_global_mut<LendProtocol>(pool_addr);
        protocol.number_id = protocol.number_id + (additional_id as u128);
    }

    #[test_only]
    public fun pool_utilization<C>(pool_addr: address): u64 acquires LendProtocol {
        let coin_name = type_name<C>();
        let protocol = borrow_global<LendProtocol>(pool_addr);
        let pool = table::borrow(&protocol.pools, coin_name);
        pool.utilization
    }
}
