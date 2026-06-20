module 0x3c1d4a86594d681ff7e5d5a233965daeabdc6a15fe5672ceeda5260038857183::constant {
    use 0x1::string;
    public fun liquidate_oper(): u8 {
        5u8
    }
    public fun apt(): string::String {
        string::utf8(vector[48u8, 120u8, 49u8, 58u8, 58u8, 97u8, 112u8, 116u8, 111u8, 115u8, 95u8, 99u8, 111u8, 105u8, 110u8, 58u8, 58u8, 65u8, 112u8, 116u8, 111u8, 115u8, 67u8, 111u8, 105u8, 110u8])
    }
    public fun borrow_oper(): u8 {
        3u8
    }
    public fun claim_borrow_reward_oper(): u8 {
        8u8
    }
    public fun claim_supply_reward_oper(): u8 {
        7u8
    }
    public fun index_borrow(): u64 {
        2
    }
    public fun index_repay(): u64 {
        3
    }
    public fun index_supply(): u64 {
        0
    }
    public fun index_withdraw(): u64 {
        1
    }
    public fun new_usdc(): string::String {
        string::utf8(vector[48u8, 120u8, 101u8, 101u8, 98u8, 49u8, 54u8, 99u8, 99u8, 50u8, 57u8, 54u8, 101u8, 55u8, 102u8, 97u8, 57u8, 53u8, 54u8, 50u8, 97u8, 49u8, 51u8, 98u8, 52u8, 98u8, 57u8, 56u8, 53u8, 53u8, 56u8, 53u8, 54u8, 102u8, 100u8, 101u8, 56u8, 52u8, 97u8, 56u8, 99u8, 51u8, 53u8, 102u8, 55u8, 55u8, 100u8, 99u8, 50u8, 101u8, 48u8, 51u8, 48u8, 98u8, 53u8, 100u8, 50u8, 97u8, 97u8, 98u8, 56u8, 52u8, 55u8, 48u8, 100u8, 54u8, 58u8, 58u8, 99u8, 105u8, 114u8, 99u8, 108u8, 101u8, 58u8, 58u8, 85u8, 83u8, 68u8, 99u8])
    }
    public fun new_usdt(): string::String {
        string::utf8(vector[48u8, 120u8, 54u8, 54u8, 56u8, 52u8, 100u8, 49u8, 53u8, 100u8, 54u8, 57u8, 49u8, 101u8, 51u8, 101u8, 53u8, 101u8, 100u8, 98u8, 102u8, 51u8, 52u8, 55u8, 52u8, 101u8, 98u8, 97u8, 50u8, 53u8, 50u8, 101u8, 48u8, 100u8, 100u8, 50u8, 57u8, 98u8, 55u8, 100u8, 102u8, 98u8, 101u8, 102u8, 97u8, 54u8, 99u8, 99u8, 55u8, 99u8, 50u8, 101u8, 48u8, 48u8, 56u8, 49u8, 49u8, 102u8, 100u8, 52u8, 53u8, 52u8, 99u8, 55u8, 53u8, 97u8, 58u8, 58u8, 116u8, 101u8, 116u8, 104u8, 101u8, 114u8, 58u8, 58u8, 85u8, 83u8, 68u8, 116u8])
    }
    public fun oper_type(p0: u8): string::String {
        let _v0;
        if (p0 == 1u8) _v0 = string::utf8(vector[83u8, 117u8, 112u8, 112u8, 108u8, 121u8]) else if (p0 == 3u8) _v0 = string::utf8(vector[66u8, 111u8, 114u8, 114u8, 111u8, 119u8]) else if (p0 == 2u8) _v0 = string::utf8(vector[87u8, 105u8, 116u8, 104u8, 100u8, 114u8, 97u8, 119u8]) else if (p0 == 4u8) _v0 = string::utf8(vector[82u8, 101u8, 112u8, 97u8, 121u8]) else if (p0 == 5u8) _v0 = string::utf8(vector[76u8, 105u8, 113u8, 117u8, 105u8, 100u8, 97u8, 116u8, 101u8]) else _v0 = string::utf8(vector[85u8, 110u8, 107u8, 110u8, 111u8, 119u8]);
        _v0
    }
    public fun repay_oper(): u8 {
        4u8
    }
    public fun stapt(): string::String {
        string::utf8(vector[48u8, 120u8, 49u8, 49u8, 49u8, 97u8, 101u8, 51u8, 101u8, 53u8, 98u8, 99u8, 56u8, 49u8, 54u8, 97u8, 53u8, 101u8, 54u8, 51u8, 99u8, 50u8, 100u8, 97u8, 57u8, 55u8, 100u8, 48u8, 97u8, 97u8, 51u8, 56u8, 56u8, 54u8, 53u8, 49u8, 57u8, 101u8, 48u8, 99u8, 100u8, 53u8, 101u8, 52u8, 98u8, 48u8, 52u8, 54u8, 54u8, 53u8, 57u8, 102u8, 97u8, 51u8, 53u8, 55u8, 57u8, 54u8, 98u8, 100u8, 49u8, 49u8, 53u8, 52u8, 50u8, 97u8, 58u8, 58u8, 115u8, 116u8, 97u8, 112u8, 116u8, 95u8, 116u8, 111u8, 107u8, 101u8, 110u8, 58u8, 58u8, 83u8, 116u8, 97u8, 107u8, 101u8, 100u8, 65u8, 112u8, 116u8])
    }
    public fun supply_oper(): u8 {
        1u8
    }
    public fun validate_oper(): u8 {
        6u8
    }
    public fun withdraw_oper(): u8 {
        2u8
    }
    public fun wusdc(): string::String {
        string::utf8(vector[48u8, 120u8, 53u8, 101u8, 49u8, 53u8, 54u8, 102u8, 49u8, 50u8, 48u8, 55u8, 100u8, 48u8, 101u8, 98u8, 102u8, 97u8, 49u8, 57u8, 97u8, 57u8, 101u8, 101u8, 102u8, 102u8, 48u8, 48u8, 100u8, 54u8, 50u8, 97u8, 50u8, 56u8, 50u8, 50u8, 55u8, 56u8, 102u8, 98u8, 56u8, 55u8, 49u8, 57u8, 102u8, 52u8, 102u8, 97u8, 98u8, 51u8, 97u8, 53u8, 56u8, 54u8, 97u8, 48u8, 97u8, 50u8, 99u8, 48u8, 102u8, 102u8, 102u8, 98u8, 101u8, 97u8, 58u8, 58u8, 99u8, 111u8, 105u8, 110u8, 58u8, 58u8, 84u8])
    }
    public fun zusdc(): string::String {
        string::utf8(vector[48u8, 120u8, 102u8, 50u8, 50u8, 98u8, 101u8, 100u8, 101u8, 50u8, 51u8, 55u8, 97u8, 48u8, 55u8, 101u8, 49u8, 50u8, 49u8, 98u8, 53u8, 54u8, 100u8, 57u8, 49u8, 97u8, 52u8, 57u8, 49u8, 101u8, 98u8, 55u8, 98u8, 99u8, 100u8, 102u8, 100u8, 49u8, 102u8, 53u8, 57u8, 48u8, 55u8, 57u8, 50u8, 54u8, 97u8, 57u8, 101u8, 53u8, 56u8, 51u8, 51u8, 56u8, 102u8, 57u8, 54u8, 52u8, 97u8, 48u8, 49u8, 98u8, 49u8, 55u8, 102u8, 97u8, 58u8, 58u8, 97u8, 115u8, 115u8, 101u8, 116u8, 58u8, 58u8, 85u8, 83u8, 68u8, 67u8])
    }
    public fun zusdt(): string::String {
        string::utf8(vector[48u8, 120u8, 102u8, 50u8, 50u8, 98u8, 101u8, 100u8, 101u8, 50u8, 51u8, 55u8, 97u8, 48u8, 55u8, 101u8, 49u8, 50u8, 49u8, 98u8, 53u8, 54u8, 100u8, 57u8, 49u8, 97u8, 52u8, 57u8, 49u8, 101u8, 98u8, 55u8, 98u8, 99u8, 100u8, 102u8, 100u8, 49u8, 102u8, 53u8, 57u8, 48u8, 55u8, 57u8, 50u8, 54u8, 97u8, 57u8, 101u8, 53u8, 56u8, 51u8, 51u8, 56u8, 102u8, 57u8, 54u8, 52u8, 97u8, 48u8, 49u8, 98u8, 49u8, 55u8, 102u8, 97u8, 58u8, 58u8, 97u8, 115u8, 115u8, 101u8, 116u8, 58u8, 58u8, 85u8, 83u8, 68u8, 84u8])
    }
    public fun zweth(): string::String {
        string::utf8(vector[48u8, 120u8, 102u8, 50u8, 50u8, 98u8, 101u8, 100u8, 101u8, 50u8, 51u8, 55u8, 97u8, 48u8, 55u8, 101u8, 49u8, 50u8, 49u8, 98u8, 53u8, 54u8, 100u8, 57u8, 49u8, 97u8, 52u8, 57u8, 49u8, 101u8, 98u8, 55u8, 98u8, 99u8, 100u8, 102u8, 100u8, 49u8, 102u8, 53u8, 57u8, 48u8, 55u8, 57u8, 50u8, 54u8, 97u8, 57u8, 101u8, 53u8, 56u8, 51u8, 51u8, 56u8, 102u8, 57u8, 54u8, 52u8, 97u8, 48u8, 49u8, 98u8, 49u8, 55u8, 102u8, 97u8, 58u8, 58u8, 97u8, 115u8, 115u8, 101u8, 116u8, 58u8, 58u8, 87u8, 69u8, 84u8, 72u8])
    }
}
