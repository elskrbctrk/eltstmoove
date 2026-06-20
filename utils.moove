module lend_protocol::utils {
    use std::error;
    use aptos_std::type_info;
    use std::signer::address_of;
    use std::vector;

    const ENOT_LEND_PROTOCOL_ADDRESS: u64 = 1;
    const ENOT_APN_COIN_ADDRESS: u64 = 2;
    const ENOT_APN_COIN: u64 = 3;
    const ENOT_LIQUIDATY_OPER: u64 = 4;
    const ENOT_REWARD_OPER: u64 = 5;
    const ENOT_VAULT_ADMIN: u64 = 6;
    const ENOT_CONFIG_MANAGER_ADDRESS: u64 = 7;
    const ENOT_CLAIM_OPER: u64 = 8;
    const ENOT_SUPPLY_ALLOWED: u64 = 9;

    const ALLOWED_ADDRESSES: vector<address> = vector[
        @lend_protocol,
        @supply1,
    ];


    public fun assert_lend_protocol_admin(account: &signer) {
        assert!(address_of(account) == @lend_protocol, error::permission_denied(ENOT_LEND_PROTOCOL_ADDRESS));
    }

    public fun assert_lend_config_admin(account: &signer) {
        assert!(address_of(account) == @lend_config_admin, error::permission_denied(ENOT_CONFIG_MANAGER_ADDRESS));
    }

    public fun assert_liquidate_oper(account: &signer) {
        assert!(address_of(account) == @liquidate_oper, error::permission_denied(ENOT_LIQUIDATY_OPER));
    }

    public fun assert_interest_oper(account: &signer) {
        assert!(address_of(account) == @interest_oper || address_of(account) == @interest_oper1 || address_of(account) == @interest_oper2 || address_of(account) == @interest_oper3 || address_of(account) == @interest_oper4, error::permission_denied(ENOT_REWARD_OPER));
    }

    public fun assert_claim_oper(account: &signer) {
        assert!(address_of(account) == @claim_oper, error::permission_denied(ENOT_CLAIM_OPER));
    }

    public fun assert_vault_admin(account: &signer) {
        assert!(address_of(account) == @vault_admin, error::permission_denied(ENOT_VAULT_ADMIN));
    }

    public fun assert_apn<APN>() {
        let type_info = type_info::type_of<APN>();

        let coin_addr = type_info::account_address(&type_info);
        assert!(coin_addr == @lend_protocol, error::invalid_argument(ENOT_APN_COIN_ADDRESS));

        let struct_name = type_info::struct_name(&type_info);
        assert!(struct_name == b"APN", error::invalid_argument(ENOT_APN_COIN));
    }

    public fun assert_supply_allowed(account: &signer) {
        let account_addr = address_of(account);
        
        let is_allowed = vector::contains(&ALLOWED_ADDRESSES, &account_addr);
        assert!(is_allowed, error::permission_denied(ENOT_SUPPLY_ALLOWED));
    }

    #[test(signer = @0x1337)]
    #[expected_failure(abort_code = 327689)]
    fun test_assert_supply_allowed_failure(signer: signer) {
        assert_supply_allowed(&signer);
    }

    #[test(signer = @supply1)]
    fun test_assert_supply_allowed_success(signer: signer) {
        assert_supply_allowed(&signer);
    }

}
