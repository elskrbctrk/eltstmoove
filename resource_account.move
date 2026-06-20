module lend_protocol::resource_account {
    //    use std::vector;
    use std::signer;

    use aptos_framework::account;
    use aptos_framework::aptos_account;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::error;
    use lend_protocol::utils::{assert_lend_protocol_admin};
    // use lend_multisig::multisig;

    const EALREADY_EXISTS_ACCOUNT_SIGNERCAP: u64 = 1;
    const ENOT_EXISTS_ACCOUNT_SIGNERCAP: u64 = 2;

    friend lend_protocol::lend;
    // friend lend_protocol::stake;
    friend lend_protocol::vcoins;
    // friend lend_protocol::lend_tests;

    struct SignerCap has key {
        pool_signer_cap: account::SignerCapability,
        // stake_signer_cap: account::SignerCapability,
        coins_signer_cap: account::SignerCapability,
        reward_signer_cap: account::SignerCapability,
    }

    public entry fun create_resource_account(source: &signer, seed_pool: vector<u8>,  seed_coins: vector<u8>, seed_reward: vector<u8>, _optional_auth_key: vector<u8>) {
        // multisig::validate_multisig();

        assert_lend_protocol_admin(source);

        assert!(!exists<SignerCap>(signer::address_of(source)), error::already_exists(EALREADY_EXISTS_ACCOUNT_SIGNERCAP));
        let (pool_account, pool_signer_cap) = account::create_resource_account(source, seed_pool);
        // let (stake_account, stake_signer_cap) = account::create_resource_account(source, seed_stake);
        let (coins_account, coins_signer_cap) = account::create_resource_account(source, seed_coins);
        let (reward_account, reward_signer_cap) = account::create_resource_account(source, seed_reward);
        move_to(source,
            SignerCap {
                pool_signer_cap,
                // stake_signer_cap,
                coins_signer_cap,
                reward_signer_cap,
            });

        coin::register<AptosCoin>(&pool_account);
        aptos_account::transfer(source, signer::address_of(&pool_account), 300000);

        // coin::register<AptosCoin>(&stake_account);
        // aptos_account::transfer(source, signer::address_of(&stake_account), 30000000);

        coin::register<AptosCoin>(&coins_account);
        aptos_account::transfer(source, signer::address_of(&coins_account), 300000);

        coin::register<AptosCoin>(&reward_account);
        aptos_account::transfer(source, signer::address_of(&reward_account), 300000);
    }

    /// Get signer capability
    public (friend) fun pool_signer(admin_addr: address): signer acquires SignerCap {
        assert!(exists<SignerCap>(admin_addr), error::not_found(ENOT_EXISTS_ACCOUNT_SIGNERCAP));
        let store = borrow_global<SignerCap>(admin_addr);
        account::create_signer_with_capability(&store.pool_signer_cap)
    }

    // public (friend) fun stake_signer(admin_addr: address): signer acquires SignerCap {
    //     assert!(exists<SignerCap>(admin_addr), error::not_found(ENOT_EXISTS_ACCOUNT_SIGNERCAP));
    //     let store = borrow_global<SignerCap>(admin_addr);
    //     account::create_signer_with_capability(&store.stake_signer_cap)
    // }

    public (friend) fun coins_signer(admin_addr: address): signer acquires SignerCap {
        assert!(exists<SignerCap>(admin_addr), error::not_found(ENOT_EXISTS_ACCOUNT_SIGNERCAP));
        let store = borrow_global<SignerCap>(admin_addr);
        account::create_signer_with_capability(&store.coins_signer_cap)
    }

    public (friend) fun reward_signer(admin_addr: address): signer acquires SignerCap {
        assert!(exists<SignerCap>(admin_addr), error::not_found(ENOT_EXISTS_ACCOUNT_SIGNERCAP));
        let store = borrow_global<SignerCap>(admin_addr);
        account::create_signer_with_capability(&store.reward_signer_cap)
    }
}
