module lend_protocol::lend {
    use std::signer;

    use aptos_framework::coin;

    use std::error;
    use lend_protocol::utils::{assert_lend_protocol_admin, assert_liquidate_oper, assert_interest_oper, assert_lend_config_admin, assert_claim_oper, assert_supply_allowed};
    use lend_protocol::resource_account;
    use lend_lib::math;
    use lend_protocol::vcoins::{Self, V};
    use lend_config::pool_config;
    use aptos_std::type_info::type_name;
    use lend_protocol::constant::{supply_oper, borrow_oper, withdraw_oper, repay_oper, liquidate_oper, claim_supply_reward_oper, claim_borrow_reward_oper};
    use lend_protocol::pool;
    use std::option::{some, none, Option};
    // use lend_multisig::multisig;
    // use hippo_aggregator::aggregator;
    use std::option;
    use aptos_framework::account;
    use aptos_framework::aptos_account;
    use lend_protocol::rewards;
    use lend_config::reward_config;
    use std::signer::address_of;
    use std::string;
    use std::vector;
    use aptos_framework::coin::Coin;
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object;
    use aptos_framework::object::{Object, object_address};
    use aptos_framework::primary_fungible_store;
    use lend_config::fa_config;
    use wrapper::panora_swap;

    const ENOT_INITIALIZE_COIN_FOR_POOL: u64 = 1;
    const EINSUFFICIENT_BALANCE_TO_REPAY: u64 = 2;
    const EALREADY_INITIALIZE_APN_COIN_FOR_POOL: u64 = 3;
    const ECOIN_NOT_REGISTER_ON_VAULT: u64 = 4;
    const ENOT_ALLOWED: u64 = 5;
    const EIN_NOT_EQUALS_OUT_FINES: u64 = 6;
    const EZERO_AMOUNT: u64 = 7;
    const EMORE_THAN_OUT: u64 = 8;
    const EINSUFFICIENT_BALANCE_TO_CLAIM: u64 = 9;
    const ENOT_PERMISSION: u64 = 10;
    const EALREADY_DEPRECATED: u64 = 11;
    const EDEPRECATED: u64 = 12;
    const ENOT_SUPPORT_COIN: u64 = 13;
    const EINVALID_ARG9: u64 = 14;
    const EDISPATCHABLE_FUNCTION_ERROR: u64 = 15;
    const EINVALID_TYPE_OF_IN: u64 = 16;
    const EINVALID_VIRTUAL_COIN: u64 = 17;

    const FEES_DENOMINATOR: u64 = 1000;
    const LIQUIDATE_FINES: u64 = 5;
    const LIQUIDATE_FINES_DECIMAL: u64 = 100;

    const FAUCET_AMOUNT: u64 = 2;

    /// Initailize pool
    public entry fun initialize(admin: &signer) {
        // multisig::validate_multisig();

        assert_lend_protocol_admin(admin);

        let admin_addr = signer::address_of(admin);

        let pool_signer = resource_account::pool_signer(admin_addr);

        pool::initialize(&pool_signer);
    }

    public entry fun initialize_rewards(admin: &signer) {
        assert_lend_protocol_admin(admin);

        let admin_addr = signer::address_of(admin);

        let reward_signer = resource_account::reward_signer(admin_addr);

        rewards::initialize(&reward_signer);
    }

    /// Initialize vcoins
    public entry fun add_pool<CoinType>(admin: &signer) {
        // multisig::validate_multisig();

        assert_lend_protocol_admin(admin);

        assert!(coin::is_coin_initialized<CoinType>(), error::unavailable(ENOT_INITIALIZE_COIN_FOR_POOL));

        let admin_addr = signer::address_of(admin);

        let pool_signer = resource_account::pool_signer(admin_addr);
        let pool_addr = signer::address_of(&pool_signer);


        if (!coin::is_account_registered<CoinType>(pool_addr)) {
            coin::register<CoinType>(&pool_signer);
        };

        // Initialize v-coin responding to coin
        vcoins::initialize<CoinType>(admin);

        pool::add_coin<CoinType>(&pool_signer);
    }

    /// Register APN for reward account
    public entry fun register<CoinType>(admin: &signer) {
        assert_lend_protocol_admin(admin);

        assert!(coin::is_coin_initialized<CoinType>(), error::unavailable(ENOT_INITIALIZE_COIN_FOR_POOL));

        let reward_signer = resource_account::reward_signer(@lend_protocol);
        let reward_addr = signer::address_of(&reward_signer);


        if (!coin::is_account_registered<CoinType>(reward_addr)) {
            coin::register<CoinType>(&reward_signer);
        };
    }

    public entry fun user_register(_admin: &signer, _user: &signer) {
        abort EDEPRECATED
    }

    public entry fun user_initialize(_user: &signer) {
        // let pool_signer = resource_account::pool_signer(@lend_protocol);
        // let pool_addr = signer::address_of(&pool_signer);
        //
        // pool::user_initialize(user, pool_addr);
    }

    /// Supply Operation
    public entry fun supply<CoinType>(user: &signer, amount: u64, _collateral: bool) {
        assert_supply_allowed(user);

        pool::check_position(user);

        let user_addr = signer::address_of(user);

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        let coin_name = type_name<CoinType>();

        // update supply info of pool, collateral is default true
        let (interest, _, _) = pool::process(pool_addr, user_addr, amount, supply_oper(), &coin_name, some(1), none());

        // transfer coin
        aptos_account::transfer_coins<CoinType>(user, pool_addr, amount);

        // need to convert interest to supply
        amount = amount + interest;
        // transfer or MINT V-Token to user
        let coins_signer = resource_account::coins_signer(@lend_protocol);

        if (!coin::is_account_registered<V<CoinType>>(user_addr)) {
            coin::register<V<CoinType>>(user);
        };
        vcoins::mint<V<CoinType>>(&coins_signer, user_addr, amount);
    }

    /// Borrow Operation
    public entry fun borrow<CoinType>(user: &signer, amount: u64) {
        assert!(false, EDEPRECATED);
        assert!(amount > 0, EZERO_AMOUNT);

        let user_addr = signer::address_of(user);

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        // fees
        let fees = (pool_config::fees<CoinType>() as u64);
        let fees = math::mul_div(amount, fees, FEES_DENOMINATOR);

        let borrow_coin = coin::withdraw<CoinType>(&pool_signer, amount);

        let fees_coin = coin::extract(&mut borrow_coin, fees);

        aptos_account::deposit_coins(@vault_admin, fees_coin);

        let v_balance = if (coin::is_account_registered<V<CoinType>>(user_addr)) {
            coin::balance<V<CoinType>>(user_addr)
        } else {
            0
        };

        let coin_name = type_name<CoinType>();
        // update borrow info of pool
        pool::process(pool_addr, user_addr, amount, borrow_oper(), &coin_name, some(v_balance), none());

        aptos_account::deposit_coins(user_addr, borrow_coin);
    }

    /// Withdraw Operation
    public entry fun withdraw<CoinType>(user: &signer, amount: u64, new_wallet: address) {
        assert!(amount > 0, EZERO_AMOUNT);

        account::exists_at(new_wallet);

        let user_addr = signer::address_of(user);

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        let coin_name = type_name<CoinType>();
        // update supply info of pool
        let (interest, _, if_charge_fee) = pool::process(pool_addr, user_addr, amount, withdraw_oper(), &coin_name, some(0), none());

        let fees = if (if_charge_fee) {
            let fees = (pool_config::fees<CoinType>() as u64);
            let fees = math::mul_div(amount, fees, FEES_DENOMINATOR);

            aptos_account::transfer_coins<CoinType>(&pool_signer, @vault_admin, fees);

            fees
        } else {
            0
        };

        let coins_signer = resource_account::coins_signer(@lend_protocol);

        if (interest >= amount) {
            // mint v
            vcoins::mint<V<CoinType>>(&coins_signer, user_addr, interest - amount);
        } else {
            // burn v
            vcoins::burn<V<CoinType>>(&coins_signer, user_addr, amount - interest);
        };

        // transfer amount of coin to user
        aptos_account::transfer_coins<CoinType>(&pool_signer, new_wallet, (amount - fees));

    }

    ///  Repay Operation
    public entry fun repay<CoinType>(user: &signer, amount: u64) {
        assert!(amount > 0, EZERO_AMOUNT);
        // transfer coin to pool
        let user_addr = signer::address_of(user);
        assert!(coin::balance<CoinType>(user_addr) >= amount, error::aborted(EINSUFFICIENT_BALANCE_TO_REPAY));

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        aptos_account::transfer_coins<CoinType>(user, pool_addr, amount);

        let coin_name = type_name<CoinType>();

        // update borrow info of pool
        pool::process(pool_addr, user_addr, amount, repay_oper(), &coin_name, none(), none());

    }

    /// Liqudate Operation
    public entry fun liquidate<IN, Y, Z, OUT, E1, E2, E3>(account: &signer, user_addr: address, in: u64, out: u64, num_steps: u8,
                                        first_dex_type: u8,
                                        first_pool_type: u64,
                                        first_is_x_to_y: bool, // first trade uses normal order
                                        second_dex_type: u8,
                                        second_pool_type: u64,
                                        second_is_x_to_y: bool, // second trade uses normal order
                                        third_dex_type: u8,
                                        third_pool_type: u64,
                                        third_is_x_to_y: bool, // second trade uses normal order
                                        ) {
        assert_lend_protocol_admin(account);

    }

    ///////////////////////////////fa/////////////////////////////////////////////////
    /// Supply Operation
    public entry fun supply_fa<CoinType, T: key>(user: &signer, metadata: Object<T>, amount: u64, _collateral: bool) {
        assert_supply_allowed(user);
        pool::check_position(user);

        let user_addr = signer::address_of(user);

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        let fa_addr = object_address(&metadata);

        let coin_name = type_name<CoinType>();

        assert!(fa_config::exists_fa_config(fa_addr, coin_name), error::invalid_argument(ENOT_SUPPORT_COIN));

        // update supply info of pool, collateral is default true
        let (interest, _, _) = pool::process(pool_addr, user_addr, amount, supply_oper(), &coin_name, some(1), none());

        // transfer coin
        primary_fungible_store::transfer(user, metadata, pool_addr, amount);

        // need to convert interest to supply
        amount = amount + interest;
        // transfer or MINT V-Token to user
        let coins_signer = resource_account::coins_signer(@lend_protocol);

        if (!coin::is_account_registered<V<CoinType>>(user_addr)) {
            coin::register<V<CoinType>>(user);
        };
        vcoins::mint<V<CoinType>>(&coins_signer, user_addr, amount);
    }

    /// Borrow Operation
    public entry fun borrow_fa<CoinType, T: key>(user: &signer, metadata: Object<T>, amount: u64) {
        assert!(false, EDEPRECATED);
        assert!(amount > 0, EZERO_AMOUNT);

        let user_addr = signer::address_of(user);

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        // fees
        let fees = (pool_config::fees<CoinType>() as u64);
        let fees = math::mul_div(amount, fees, FEES_DENOMINATOR);

        // let borrow_coin = coin::withdraw<CoinType>(&pool_signer, amount);

        // let fees_coin = coin::extract(&mut borrow_coin, fees);

        // aptos_account::deposit_coins(@vault_admin, fees_coin);

        let v_balance = if (coin::is_account_registered<V<CoinType>>(user_addr)) {
            coin::balance<V<CoinType>>(user_addr)
        } else {
            0
        };

        let fa_addr = object_address(&metadata);

        let coin_name = type_name<CoinType>();

        assert!(fa_config::exists_fa_config(fa_addr, coin_name), error::invalid_argument(ENOT_SUPPORT_COIN));

        // update borrow info of pool
        pool::process(pool_addr, user_addr, amount, borrow_oper(), &coin_name, some(v_balance), none());

        // aptos_account::deposit_coins(user_addr, borrow_coin);
        primary_fungible_store::transfer(&pool_signer, metadata, @vault_admin, fees);

        primary_fungible_store::transfer(&pool_signer, metadata, user_addr, amount - fees);

    }

    /// Withdraw Operation
    public entry fun withdraw_fa<CoinType, T: key>(user: &signer, metadata: Object<T>, amount: u64, new_wallet: address) {
        assert!(amount > 0, EZERO_AMOUNT);

        account::exists_at(new_wallet);

        let user_addr = signer::address_of(user);

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);


        let fa_addr = object_address(&metadata);

        let coin_name = type_name<CoinType>();

        assert!(fa_config::exists_fa_config(fa_addr, coin_name), error::invalid_argument(ENOT_SUPPORT_COIN));

        // update supply info of pool
        let (interest, _, if_charge_fee) = pool::process(pool_addr, user_addr, amount, withdraw_oper(), &coin_name, some(0), none());

        let fees = if (if_charge_fee) {
            let fees = (pool_config::fees<CoinType>() as u64);
            let fees = math::mul_div(amount, fees, FEES_DENOMINATOR);

            // aptos_account::transfer_coins<CoinType>(&pool_signer, @vault_admin, fees);
            primary_fungible_store::transfer(&pool_signer, metadata, @vault_admin, fees);

            fees
        } else {
            0
        };

        let coins_signer = resource_account::coins_signer(@lend_protocol);

        if (interest >= amount) {
            // mint v
            vcoins::mint<V<CoinType>>(&coins_signer, user_addr, interest - amount);
        } else {
            // burn v
            vcoins::burn<V<CoinType>>(&coins_signer, user_addr, amount - interest);
        };

        // transfer amount of coin to user
        // aptos_account::transfer_coins<CoinType>(&pool_signer, new_wallet, (amount - fees));
        primary_fungible_store::transfer(&pool_signer, metadata, new_wallet, (amount - fees));

    }

    ///  Repay Operation
    public entry fun repay_fa<CoinType, T:key>(user: &signer, metadata: Object<T>, amount: u64) {
        assert!(amount > 0, EZERO_AMOUNT);
        // transfer coin to pool
        let user_addr = signer::address_of(user);
        assert!(primary_fungible_store::balance<T>(user_addr, metadata) >= amount, error::aborted(EINSUFFICIENT_BALANCE_TO_REPAY));

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        // aptos_account::transfer_coins<CoinType>(user, pool_addr, amount);
        primary_fungible_store::transfer(user, metadata, pool_addr, amount);

        let fa_addr = object_address(&metadata);

        let coin_name = type_name<CoinType>();

        assert!(fa_config::exists_fa_config(fa_addr, coin_name), error::invalid_argument(ENOT_SUPPORT_COIN));

        // update borrow info of pool
        pool::process(pool_addr, user_addr, amount, repay_oper(), &coin_name, none(), none());

    }

    public entry fun liquidate_fa<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16, T17, T18, T19, T20, T21, T22, T23, T24, T25, T26, T27, T28, T29, T30, T31>(
        liquditor: &signer,
        user_addr: address,
        arg3: u64,
        arg4: u8,
        arg5: vector<u8>,
        arg6: vector<vector<vector<u8>>>,
        arg7: vector<vector<vector<u64>>>,
        arg8: vector<vector<vector<bool>>>,
        arg9: vector<vector<u8>>,
        arg10: vector<vector<vector<address>>>,
        arg11: vector<vector<address>>,
        arg12: vector<vector<address>>,
        arg13: 0x1::option::Option<vector<vector<vector<vector<vector<u8>>>>>>,
        arg14: vector<vector<vector<u64>>>,
        arg15: 0x1::option::Option<vector<vector<vector<u8>>>>,
        arg16: address,
        arg17: vector<u64>,
        arg18: u64,
        arg19: u64,
        arg20: address,
        // Additional arguments can be appended here, if required for your contract
    ) {
        assert_liquidate_oper(liquditor);

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        let coin_signer = resource_account::coins_signer(@lend_protocol);
        let coin_addr = signer::address_of(&coin_signer);

        let total_from_token_amount = 0;

        vector::for_each(
            arg17,
            |e| {
                total_from_token_amount = total_from_token_amount + e;
            }
        );


        let coin_name_in = type_name<T0>();
        let x = vector::borrow(&arg9, 0);
        let y = vector::borrow(x, 0);
        let (from_token_coin, from_token_fa) =
            // assert!(arg9[0][0] == 1 || arg9[0][9] == 2, EINVALID_ARG9);
            if (*y == 1 || *y == 2) {
                let fa_addresses = vector::borrow(&arg11, 0);
                let fa_address = vector::borrow(fa_addresses, 0);
                let coin_name = fa_config::coin_name(*fa_address);
                assert!(coin_name_in == coin_name, EINVALID_VIRTUAL_COIN);  // T0 is virtual coin type

                let obj = object::address_to_object<Metadata>(*fa_address);
                (
                    option::none(),
                    option::some(
                        primary_fungible_store::withdraw(
                            &pool_signer, obj, total_from_token_amount
                        )
                    )
                )
            } else {  // from coin
                (
                    option::some(
                        coin::withdraw<T0>(&pool_signer, total_from_token_amount)
                    ),
                    option::none()
                )
            };


        let coin_name_out = type_name<T31>();

        let (coin_m_left, fa_m_left, coin_m_out, fa_m_out) =
            panora_swap::router<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16, T17, T18, T19, T20, T21, T22, T23, T24, T25, T26, T27, T28, T29, T30, T31>(
                pool_addr,
                from_token_coin,
                from_token_fa,
                arg3,
                arg4,
                arg5,
                arg6,
                arg7,
                arg8,
                arg9,
                arg10,
                arg11,
                arg12,
                arg13,
                arg14,
                arg15,
                arg16,
                arg17,
                arg18,
                arg19,
                arg20,
            );

        let fines = arg18 - math::mul_div(arg18, LIQUIDATE_FINES_DECIMAL, (LIQUIDATE_FINES_DECIMAL + LIQUIDATE_FINES));

        // this function handles coin/fa options created above. In case of exact in swap, the options are destroyed and in case of exact out swap, the remaining from token is sent to the signer of this transaction
        let in_left= if (option::is_some(&fa_m_left)) {
            option::destroy_none(coin_m_left);
            check_and_deposit_fa_opt(&pool_signer, fa_m_left)
        } else if (option::is_some(&coin_m_left)) {
            option::destroy_none(fa_m_left);
            check_and_deposit_coin_opt(&pool_signer, coin_m_left)
        } else {
            option::destroy_none(coin_m_left);
            option::destroy_none(fa_m_left);
            0
        };

        // No need to handle coin_m_out and fa_m_out because of using ExactOut

        // Checking and depositing the returned token(coin/fa)
        check_and_deposit_fa_to_address_opt(pool_addr, fa_m_out);

        if (!fa_config::exists_fa_config(arg16, coin_name_out)) {
            check_and_deposit_coin_to_address_opt<T31>(
                pool_addr, coin_m_out
            );

            coin::transfer<T31>(&pool_signer, @vault_admin, fines);
        } else {
            option::destroy_none(coin_m_out);

            let obj = object::address_to_object<Metadata>(arg16);
            primary_fungible_store::transfer(&pool_signer, obj, @vault_admin, fines);
        };


        let (interest, _, _) = pool::process(
            pool_addr,
            user_addr,
            (total_from_token_amount - in_left),
            liquidate_oper(),
            &coin_name_in,
            some(arg18 - fines), // coin_out value
            some(coin_name_out)
        );

        // burn amount of in of v token
        // let coins_signer = resource_account::coins_signer(@lend_protocol);
        //
        // assert!(coin_name_in == type_name<T0>(), EINVALID_TYPE_OF_IN);
        //
        // if (interest >= total_from_token_amount - in_left) {
        //     vcoins::mint<V<T0>>(&coins_signer, user_addr, interest - (total_from_token_amount - in_left));
        // } else {
        //     let balance = coin::balance<V<T0>>(user_addr);
        //     let amount = if (balance >= total_from_token_amount - in_left - interest) {
        //         total_from_token_amount - in_left - interest
        //     } else {
        //         balance
        //     };
        //     vcoins::burn<V<T0>>(&coins_signer, user_addr, amount);
        // };
    }

    ////////////////////////////////////////////////////////////////////////////////

    public entry fun new_activity<C, R>(account: &signer, supply_reward_rate: u64, borrow_reward_rate: u64, start_time: u64, end_time: u64, decimals: u8, amount_supply: u64, amount_borrow: u64) {
        assert_lend_config_admin(account);
        reward_config::update<C, R>(account, supply_reward_rate, borrow_reward_rate, start_time, end_time, decimals, amount_supply, amount_borrow);

        rewards::reset(&type_name<C>(), &type_name<R>(), start_time);
    }

    #[deprecated]
    public entry fun clear_reserve3_by_user<C>(_account: &signer, _user_addr: address) {
        // assert_lend_config_admin(account);
        // assert_claim_oper(account);
        //
        // let pool_signer = resource_account::pool_signer(@lend_protocol);
        // let pool_addr = signer::address_of(&pool_signer);
        //
        // pool::clear_reserve3_by_user<C>(pool_addr, user_addr);
    }

    #[deprecated]
    public entry fun clear_reserve3<C>(_account: &signer) {
        // assert_lend_config_admin(account);
        // assert_claim_oper(account);

        // let pool_signer = resource_account::pool_signer(@lend_protocol);
        // let _pool_addr = signer::address_of(&pool_signer);

        // pool::clear_reserve3<C>(pool_addr);
    }

    public entry fun claim_by_subset<C, R>(account: &signer, subset_id: u64, slot: u64) {
        assert_claim_oper(account);

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        let reward_signer = resource_account::reward_signer(@lend_protocol);
        pool::process_claim_by_subset<C, R>(account, &reward_signer, pool_addr, subset_id, slot);
    }

    #[deprecated]
    public entry fun claim_all<C, R>(_account: &signer) {
    }

    public entry fun claim<C, R>(account: &signer, user_addr: address) {
        // assert_claim_oper(account);
        let account_addr = signer::address_of(account);
        assert!(account_addr == user_addr || account_addr == @claim_oper, ENOT_PERMISSION);

        let self_claim = if (account_addr == user_addr) {
            some(1)
        } else {
            some(0)
        };

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        let coin_name = type_name<C>();

        let reward_coin_name = type_name<R>();

        let (_, reward0, _) = pool::process(pool_addr, user_addr, 0, claim_supply_reward_oper(), &coin_name, self_claim, some(reward_coin_name));
        let (_, reward1, _) = pool::process(pool_addr, user_addr, 0, claim_borrow_reward_oper(), &coin_name, self_claim, some(reward_coin_name));

        let amount = reward0 + reward1;

        if (amount > 0) {
            let reward_signer = resource_account::reward_signer(@lend_protocol);
            let balance = coin::balance<R>(signer::address_of(&reward_signer));

            assert!(balance >= amount, EINSUFFICIENT_BALANCE_TO_CLAIM);
            aptos_account::transfer_coins<R>(&reward_signer, user_addr, amount);
        }
    }

    #[deprecated]
    public entry fun claim_both<C, R1, R2>(_account: &signer, _user_addr: address) {
    }

    public entry fun traverse_pool(account: &signer, subset_id: u64, slot: u64) {
	    assert_interest_oper(account);

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        pool::process_traverse(pool_addr, subset_id, slot);
    }


    public entry fun reset_collateral<CoinType>(user: &signer) {
        assert!(false, EDEPRECATED);
        // implement!
        let _user_addr = signer::address_of(user);

        // let pool_signer = resource_account::pool_signer(@lend_protocol);
        // let pool_addr = signer::address_of(&pool_signer);

        // pool::reset_collateral<CoinType>(pool_addr, user_addr)
    }

    public entry fun enable<CoinType>(admin: &signer, oper_type: u8) {
        assert_lend_protocol_admin(admin);

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        let coin_name = type_name<CoinType>();

        if (oper_type == supply_oper()) {
            pool::enable_pool(pool_addr, 0, &coin_name)
        } else if (oper_type == withdraw_oper()) {
            pool::enable_pool(pool_addr, 1, &coin_name)
        } else if (oper_type == borrow_oper()) {
            pool::enable_pool(pool_addr, 2, &coin_name)
        } else if (oper_type == repay_oper()) {
            pool::enable_pool(pool_addr, 3, &coin_name)
        }
    }

    public entry fun disable<CoinType>(admin: &signer, oper_type: u8) {
        assert_lend_protocol_admin(admin);

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        let coin_name = type_name<CoinType>();

        if (oper_type == supply_oper()) {
            pool::disable_pool(pool_addr, 0, &coin_name)
        } else if (oper_type == withdraw_oper()) {
            pool::disable_pool(pool_addr, 1, &coin_name)
        } else if (oper_type == borrow_oper()) {
            pool::disable_pool(pool_addr, 2, &coin_name)
        } else if (oper_type == repay_oper()) {
            pool::disable_pool(pool_addr, 3, &coin_name)
        }
    }

    public entry fun unpause_all(admin: &signer) {
        assert_lend_protocol_admin(admin);

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        pool::unpause_all(pool_addr, 0);
        pool::unpause_all(pool_addr, 1);
        pool::unpause_all(pool_addr, 2);
        pool::unpause_all(pool_addr, 3);
    }

    public entry fun pause_all(admin: &signer) {
        let addr = address_of(admin);
        if (addr != @pause_addr) {
            assert_lend_protocol_admin(admin);
        };

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        pool::pause_all(pool_addr, 0);
        pool::pause_all(pool_addr, 1);
        pool::pause_all(pool_addr, 2);
        pool::pause_all(pool_addr, 3);
    }

    public entry fun add_config<C>(
        account: &signer,
        ltv: u8,
        fees: u8,
        weight: u8,
        max_deposit_limit: u64,
        min_deposit_limit: u64
    ) {

        // multisig::validate_multisig();

        pool_config::add<C>(account, ltv, fees, weight, max_deposit_limit, min_deposit_limit);

    }

    public entry fun remove_config<C>(account: &signer) {
        assert!(false, EDEPRECATED);
        assert!(signer::address_of(account) == @lend_protocol, ENOT_ALLOWED);

        // multisig::validate_multisig();

        // pool_config::remove<C>(account);

        // TODO: traverse to reward due to weight changed, it's completed by central service now
    }

    public entry fun set_weight<C>(account: &signer, _weight: u8) {
        assert!(false, EDEPRECATED);
        assert!(signer::address_of(account) == @lend_protocol, ENOT_ALLOWED);

        // multisig::validate_multisig();

        // pool_config::set_weight<C>(account, weight);

        // TODO: traverse to reward due to weight changed, it's completed by central service now
    }

    // Helper function to deposit FA to the given signer
    fun check_and_deposit_fa_opt(
        sender: &signer, coin_opt: Option<0x1::fungible_asset::FungibleAsset>
    ): u64 {
        let amount = 0;
        if (option::is_some(&coin_opt)) {
            let fa = option::extract(&mut coin_opt);
            let sender_addr = signer::address_of(sender);

            amount = primary_fungible_store_deposit_helper(sender_addr, fa);

        };
        option::destroy_none(coin_opt);

        amount
    }

    // Helper function to deposit coins to the given signer
    fun check_and_deposit_coin_opt<X>(
        sender: &signer, coin_opt: Option<coin::Coin<X>>
    ): u64 {
        let amount  = 0;
        if (option::is_some(&coin_opt)) {
            let coin = option::extract(&mut coin_opt);
            amount = coin::value(&coin);
            let sender_addr = signer::address_of(sender);
            if (!coin::is_account_registered<X>(sender_addr)) {
                coin::register<X>(sender);
            };
            coin::deposit(sender_addr, coin);
        };
        option::destroy_none(coin_opt);
        amount
    }

    // Helper function to deposit FA to primary fungible store of the given FA
    fun primary_fungible_store_deposit_helper(
        receiver: address, fa: fungible_asset::FungibleAsset
    ): u64 {
        let v = fungible_asset::amount(&fa);
        let metadata = fungible_asset::asset_metadata(&fa);
        let before = primary_fungible_store::balance(receiver, metadata);

        primary_fungible_store::deposit(receiver, fa);

        let after = primary_fungible_store::balance(receiver, metadata);

        assert!(
            after - before == v,
            EDISPATCHABLE_FUNCTION_ERROR
        );

        v
    }

    // Helper function to deposit FA to the given address
    fun check_and_deposit_fa_to_address_opt(
        receiver: address, coin_opt: Option<0x1::fungible_asset::FungibleAsset>
    ) {
        if (option::is_some(&coin_opt)) {
            let fa = option::extract(&mut coin_opt);

            primary_fungible_store_deposit_helper(receiver, fa);

        };
        option::destroy_none(coin_opt);
    }

    // Helper function to deposit coins to the given address
    fun check_and_deposit_coin_to_address_opt<X>(
        receiver: address, coin_opt: Option<coin::Coin<X>>
    ) {

        if (option::is_some(&coin_opt)) {
            let coin = option::extract(&mut coin_opt);
            aptos_account::deposit_coins<X>(receiver, coin);
        };
        option::destroy_none(coin_opt);

    }

    #[view]
    public fun get_user_info(subset_id: u64, slot: u64): vector<pool::UserInfo> {

        let pool_signer = resource_account::pool_signer(@lend_protocol);
        let pool_addr = signer::address_of(&pool_signer);

        pool::traverse_pool(pool_addr, subset_id, slot)
    }

}
