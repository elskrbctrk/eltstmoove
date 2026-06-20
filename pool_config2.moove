module 0x3c1d4a86594d681ff7e5d5a233965daeabdc6a15fe5672ceeda5260038857183::pool_config2 {
    use 0x1::error;
    use 0x1::signer;
    use 0x1::string;
    use 0x1::type_info;
    use 0x1::vector;
    struct Config has key {
        stores: vector<Store>,
    }
    struct Store has copy, drop, store {
        coin_name: string::String,
        max_portion_borrow: u64,
        reserve0: u64,
        reserve1: u64,
        reserve2: u64,
    }
    fun borrow(p0: &string::String): Store
        acquires Config
    {
        if (!exists<Config>(@0x3c1d4a86594d681ff7e5d5a233965daeabdc6a15fe5672ceeda5260038857183)) {
            let _v0 = error::not_found(2);
            abort _v0
        };
        let _v1 = borrow_global<Config>(@0x3c1d4a86594d681ff7e5d5a233965daeabdc6a15fe5672ceeda5260038857183);
        let (_v2,_v3) = contains(&_v1.stores, p0);
        assert!(_v2, 5);
        *vector::borrow<Store>(&_v1.stores, _v3)
    }
    fun borrow_mut(p0: &mut vector<Store>, p1: &string::String): &mut Store {
        let (_v0,_v1) = contains(freeze(p0), p1);
        assert!(_v0, 5);
        vector::borrow_mut<Store>(p0, _v1)
    }
    public entry fun add<T0>(p0: &signer, p1: u64)
        acquires Config
    {
        validate_account(p0);
        let _v0 = borrow_global_mut<Config>(@0x3c1d4a86594d681ff7e5d5a233965daeabdc6a15fe5672ceeda5260038857183);
        let _v1 = type_info::type_name<T0>();
        let _v2 = &_v0.stores;
        let _v3 = &_v1;
        let (_v4,_v5) = contains(_v2, _v3);
        if (_v4) abort 7;
        let _v6 = &mut _v0.stores;
        let _v7 = Store{coin_name: _v1, max_portion_borrow: p1, reserve0: 0, reserve1: 0, reserve2: 0};
        vector::push_back<Store>(_v6, _v7);
    }
    fun contains(p0: &vector<Store>, p1: &string::String): (bool, u64) {
        let _v0 = 0;
        let _v1 = vector::length<Store>(p0);
        'l0: loop {
            loop {
                if (!(_v0 < _v1)) break 'l0;
                let _v2 = *&vector::borrow<Store>(p0, _v0).coin_name;
                let _v3 = *p1;
                if (_v2 == _v3) break;
                _v0 = _v0 + 1;
                continue
            };
            return (true, _v0)
        };
        (false, 0)
    }
    public fun get_config(p0: address): vector<Store>
        acquires Config
    {
        if (!exists<Config>(p0)) {
            let _v0 = error::not_found(2);
            abort _v0
        };
        *&borrow_global<Config>(p0).stores
    }
    public entry fun initialize(p0: &signer) {
        let _v0 = signer::address_of(p0);
        if (!(_v0 == @0x3c1d4a86594d681ff7e5d5a233965daeabdc6a15fe5672ceeda5260038857183)) {
            let _v1 = error::permission_denied(8);
            abort _v1
        };
        if (!!exists<Config>(_v0)) {
            let _v2 = error::not_found(1);
            abort _v2
        };
        let _v3 = Config{stores: vector::empty<Store>()};
        move_to<Config>(p0, _v3);
    }
    public fun max_portion_borrow_with_coin_name(p0: &string::String): u64
        acquires Config
    {
        let _v0 = borrow(p0);
        *&(&_v0).max_portion_borrow
    }
    public entry fun remove<T0>(p0: &signer)
        acquires Config
    {
        validate_account(p0);
        let _v0 = borrow_global_mut<Config>(@0x3c1d4a86594d681ff7e5d5a233965daeabdc6a15fe5672ceeda5260038857183);
        let _v1 = type_info::type_name<T0>();
        let _v2 = &_v0.stores;
        let _v3 = &_v1;
        let (_v4,_v5) = contains(_v2, _v3);
        assert!(_v4, 5);
        let _v6 = vector::remove<Store>(&mut _v0.stores, _v5);
    }
    public entry fun set_max_portion_borrow<T0>(p0: &signer, p1: u64)
        acquires Config
    {
        validate_account(p0);
        let _v0 = borrow_global_mut<Config>(@0x3c1d4a86594d681ff7e5d5a233965daeabdc6a15fe5672ceeda5260038857183);
        let _v1 = type_info::type_name<T0>();
        let _v2 = &mut _v0.stores;
        let _v3 = &_v1;
        let _v4 = &mut borrow_mut(_v2, _v3).max_portion_borrow;
        *_v4 = p1;
    }
    fun validate_account(p0: &signer) {
        let _v0 = signer::address_of(p0);
        if (!(_v0 == @0x3c1d4a86594d681ff7e5d5a233965daeabdc6a15fe5672ceeda5260038857183)) {
            let _v1 = error::permission_denied(8);
            abort _v1
        };
        if (!exists<Config>(_v0)) {
            let _v2 = error::not_found(2);
            abort _v2
        };
    }
}
