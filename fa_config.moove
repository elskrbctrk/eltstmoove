module lend_config::fa_config {
    use std::string::String;
    use std::signer;
    use std::error;
    use aptos_std::table;
    use aptos_framework::timestamp;
    use aptos_framework::event;

    const ENOT_ALLOWED: u64 = 1;
    const ENOT_FOUND_CONFIG: u64 = 2;
    const EALREADY_PUBLISHED_CONFIG: u64 = 3;
    const ENOT_IN_TABLE: u64 = 4;
    const EDEPRECATED: u64 = 5;

    #[event]
    struct FaConfigInitEvent has drop, store {
    }   

    #[event]
    struct FaConfigAddEvent has drop, store {
        coin_name: String,
        fa_address: address,
    }

    struct FaConfig has key {
        fas: table::Table<String, Fa>,
    }

    struct Fa has copy, drop, store {
        fa_address: address,
        is_active: bool,
        created_at: u64,
    }

    struct FaCoin has key {
        coins: table::Table<address, String>
    }

    // init
    public entry fun initialize(admin: &signer) {
        assert!(false, EDEPRECATED);
        assert!(signer::address_of(admin) == @lend_config_admin, error::permission_denied(ENOT_ALLOWED));

        assert!(!exists<FaConfig>(@lend_config_admin), error::not_found(EALREADY_PUBLISHED_CONFIG));

        let fa_config = FaConfig {
            fas: table::new<String, Fa>(),
        };

        move_to(admin, fa_config);

        event::emit(FaConfigInitEvent{});
    }

    // init
    public entry fun initialize_fa_coins(admin: &signer) {
        assert!(false, EDEPRECATED);
        assert!(signer::address_of(admin) == @lend_config_admin, error::permission_denied(ENOT_ALLOWED));

        assert!(!exists<FaCoin>(@lend_config_admin), error::not_found(EALREADY_PUBLISHED_CONFIG));

        let fa = FaCoin {
            coins: table::new<address, String>(),
        };

        move_to(admin, fa);
    }


        // add fa config
    public entry fun add_fa_config(admin: &signer, coin_name: String, fa_address: address) acquires FaConfig, FaCoin {
        assert!(false, EDEPRECATED);
        assert!(signer::address_of(admin) == @lend_config_admin, error::permission_denied(ENOT_ALLOWED));

        assert!(exists<FaConfig>(@lend_config_admin), error::not_found(ENOT_FOUND_CONFIG));

        let fa_config= borrow_global_mut<FaConfig>(@lend_config_admin);

        if (!table::contains(&fa_config.fas, coin_name))
            {
                table::add(&mut fa_config.fas, coin_name, Fa {
                    fa_address,
                    is_active: true,
                    created_at: timestamp::now_seconds(),
                });
            };

        assert!(exists<FaCoin>(@lend_config_admin), error::not_found(ENOT_FOUND_CONFIG));

        let fa_coin = borrow_global_mut<FaCoin>(@lend_config_admin);

        table::add(&mut fa_coin.coins, fa_address, coin_name);


        let fa_config_add_event = FaConfigAddEvent{coin_name, fa_address};

        event::emit(fa_config_add_event)
    }

    // exists fa config
    #[view]
    public fun exists_fa_config(fa_address: address, coin_name: String): bool acquires FaConfig {

        assert!(exists<FaConfig>(@lend_config_admin), error::not_found(ENOT_FOUND_CONFIG));

        let fa_config = borrow_global<FaConfig>(@lend_config_admin);

        if (!table::contains(&fa_config.fas, coin_name)) {
            return false
        };

        let fa = table::borrow(&fa_config.fas, coin_name);

        if (fa.fa_address == fa_address) {
            return true
        };

        false
    }

    #[view]
    public fun coin_name(fa_address: address): String acquires FaCoin {
        assert!(exists<FaConfig>(@lend_config_admin), error::not_found(ENOT_FOUND_CONFIG));

        let fa_coin = borrow_global<FaCoin>(@lend_config_admin);

        assert!(table::contains(&fa_coin.coins, fa_address), ENOT_IN_TABLE);

        *table::borrow(&fa_coin.coins, fa_address)
    }
}
