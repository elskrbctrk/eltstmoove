module lend_protocol::vcoins {

    use lend_protocol::utils;
    use std::error;
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::coin::{BurnCapability, MintCapability};
    use std::string;
    use std::option;
    use lend_protocol::resource_account;

    friend lend_protocol::lend;
    // friend lend_protocol::stake;

    const ENO_MINT_CAPABILITIES: u64 = 1;
    const ENO_BURN_CAPABILITIES: u64 = 2;

    const MAX_COIN_SYMBOL_LENGTH: u64 = 10;

    const TOTAL_SUPPLY_AMOUNT: u64 = 100000000;

    struct V<phantom CoinType> has key {}

    struct CapStore<phantom  CoinType> has key {
        mint_cap: MintCapability<CoinType>,
        burn_cap: BurnCapability<CoinType>,
    }

    public(friend) fun initialize<CoinType>(admin: &signer) {
        utils::assert_lend_protocol_admin(admin);

        let coins_signer = resource_account::coins_signer(@lend_protocol);

        let name = coin::name<CoinType>();
        let symbol = string::utf8(b"v");
        let len = string::length(&coin::symbol<CoinType>());
        if ( len == MAX_COIN_SYMBOL_LENGTH) {
            string::append(&mut symbol, string::sub_string(&coin::symbol<CoinType>(), 0, (len - 2)))
        } else {
            string::append(&mut symbol, coin::symbol<CoinType>());
        };
        let decimal = coin::decimals<CoinType>();
        let monitor_supply = if (option::is_some(&coin::supply<CoinType>())) {
            true
        } else {false};

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<V<CoinType>>(admin, name, symbol, decimal, monitor_supply);

        coin::register<V<CoinType>>(&coins_signer);

        move_to(&coins_signer, CapStore<V<CoinType>>{
            mint_cap,
            burn_cap,
        });

        coin::destroy_freeze_cap(freeze_cap);
    }

    // reserved
    fun destroy_cap<CoinType>(admin: &signer) acquires CapStore {
        utils::assert_lend_protocol_admin(admin);

        let CapStore { burn_cap, mint_cap } = move_from<CapStore<CoinType>>(signer::address_of(admin));
        coin::destroy_mint_cap(mint_cap);
        coin::destroy_burn_cap(burn_cap);
    }

    public (friend) fun mint<CoinType>(account: &signer, dst_addr: address, amount: u64) acquires CapStore {
        let account_addr = signer::address_of(account);

        assert!(
            exists<CapStore<CoinType>>(account_addr),
            error::not_found(ENO_MINT_CAPABILITIES),
        );

        let mint_cap = &borrow_global<CapStore<CoinType>>(account_addr).mint_cap;
        let coins_minted = coin::mint<CoinType>(amount, mint_cap);
        coin::deposit<CoinType>(dst_addr, coins_minted);
    }

    public (friend) fun burn<CoinType>(account: &signer, user_addr: address, amount: u64) acquires CapStore {
        let account_addr = signer::address_of(account);

        assert!(
            exists<CapStore<CoinType>>(account_addr),
            error::not_found(ENO_BURN_CAPABILITIES),
        );

        let burn_cap= &borrow_global<CapStore<CoinType>>(account_addr).burn_cap;

        coin::burn_from<CoinType>(user_addr, amount, burn_cap);
    }
}
