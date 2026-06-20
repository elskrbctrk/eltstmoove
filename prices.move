module 0x3c1d4a86594d681ff7e5d5a233965daeabdc6a15fe5672ceeda5260038857183::prices {
    use 0x1::aptos_coin;
    use 0x1::coin;
    use 0x1::error;
    use 0x1::signer;
    use 0x1::string;
    use 0x1::table;
    use 0x1::timestamp;
    use 0x1::type_info;
    use 0x7d7e436f0b2aafde60774efb26ccc432cf881b677aca7faaf2a01879bd19fb8::aggregator;
    use 0x7d7e436f0b2aafde60774efb26ccc432cf881b677aca7faaf2a01879bd19fb8::math;
    use 0x3c1d4a86594d681ff7e5d5a233965daeabdc6a15fe5672ceeda5260038857183::math as math_1;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::i64;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_identifier;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::pyth;
    struct Aggregator has copy, drop, store {
        cex_price: CEXPrice,
        pyth_price: PythPrice,
        switchboard_price: SwitchboardPrice,
        max_age: u64,
        decimal: u8,
    }
    struct CEXPrice has copy, drop, store {
        price: u64,
        exponent: u8,
        neg: bool,
        last_update_time: u64,
        state: bool,
    }
    struct PythPrice has copy, drop, store {
        price: i64::I64,
        exponent: i64::I64,
        identifier: vector<u8>,
        last_update_time: u64,
        state: bool,
    }
    struct SwitchboardPrice has copy, drop, store {
        price: u64,
        exponent: u8,
        neg: bool,
        addr: address,
        last_update_time: u64,
        state: bool,
    }
    struct PriceId has copy, drop {
        identifier: vector<u8>,
        addr: address,
    }
    struct PriceStore has store, key {
        inner: table::Table<string::String, Aggregator>,
    }
    fun abs_diff(p0: u64, p1: u64): u64 {
        if (p0 > p1) return p0 - p1;
        p1 - p0
    }
    public entry fun active_pyth_price<T0>(p0: &signer, p1: vector<vector<u8>>)
        acquires PriceStore
    {
        verify_account(p0);
        if (!exists<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41)) {
            let _v0 = error::not_found(1);
            abort _v0
        };
        let _v1 = type_info::type_name<T0>();
        let _v2 = borrow_global_mut<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41);
        assert!(table::contains<string::String, Aggregator>(&_v2.inner, _v1), 6);
        let _v3 = table::borrow_mut<string::String, Aggregator>(&mut _v2.inner, _v1);
        let _v4 = price_identifier::from_byte_vec(*&(&_v3.pyth_price).identifier);
        let _v5 = pyth::get_update_fee(&p1);
        let _v6 = coin::withdraw<aptos_coin::AptosCoin>(p0, _v5);
        pyth::update_price_feeds(p1, _v6);
        let _v7 = pyth::get_price(_v4);
        let _v8 = price::get_price(&_v7);
        let _v9 = &mut (&mut _v3.pyth_price).price;
        *_v9 = _v8;
        let _v10 = price::get_expo(&_v7);
        let _v11 = &mut (&mut _v3.pyth_price).exponent;
        *_v11 = _v10;
        let _v12 = price::get_timestamp(&_v7);
        let _v13 = &mut (&mut _v3.pyth_price).last_update_time;
        *_v13 = _v12;
    }
    public entry fun add<T0>(p0: &signer, p1: vector<u8>, p2: address, p3: u64)
        acquires PriceStore
    {
        verify_account(p0);
        if (!exists<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41)) {
            let _v0 = error::not_found(1);
            abort _v0
        };
        let _v1 = borrow_global_mut<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41);
        let _v2 = type_info::type_name<T0>();
        let _v3 = coin::decimals<T0>();
        let _v4 = &mut _v1.inner;
        let _v5 = CEXPrice{price: 0, exponent: 0u8, neg: false, last_update_time: 0, state: true};
        let _v6 = i64::from_u64(0);
        let _v7 = i64::from_u64(0);
        let _v8 = PythPrice{price: _v6, exponent: _v7, identifier: p1, last_update_time: 0, state: true};
        let _v9 = SwitchboardPrice{price: 0, exponent: 0u8, neg: false, addr: p2, last_update_time: 0, state: false};
        let _v10 = Aggregator{cex_price: _v5, pyth_price: _v8, switchboard_price: _v9, max_age: p3, decimal: _v3};
        table::upsert<string::String, Aggregator>(_v4, _v2, _v10);
    }
    public entry fun feed_cex_price<T0>(p0: &signer, p1: u64, p2: bool, p3: u8)
        acquires PriceStore
    {
        assert!(signer::address_of(p0) == @0x817a93f069e3939d06675d9e376f720d1844a94c5fa5dca858938b350560a6d, 2);
        if (!exists<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41)) {
            let _v0 = error::not_found(1);
            abort _v0
        };
        let _v1 = borrow_global_mut<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41);
        let _v2 = type_info::type_name<T0>();
        assert!(table::contains<string::String, Aggregator>(&_v1.inner, _v2), 6);
        let _v3 = table::borrow_mut<string::String, Aggregator>(&mut _v1.inner, _v2);
        let _v4 = &mut (&mut _v3.cex_price).price;
        *_v4 = p1;
        let _v5 = &mut (&mut _v3.cex_price).exponent;
        *_v5 = p3;
        let _v6 = &mut (&mut _v3.cex_price).neg;
        *_v6 = p2;
        let _v7 = timestamp::now_seconds();
        let _v8 = &mut (&mut _v3.cex_price).last_update_time;
        *_v8 = _v7;
    }
    public fun get_price(p0: &string::String): (u64, u64)
        acquires PriceStore
    {
        if (!exists<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41)) {
            let _v0 = error::not_found(1);
            abort _v0
        };
        let _v1 = borrow_global_mut<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41);
        let _v2 = &_v1.inner;
        let _v3 = *p0;
        assert!(table::contains<string::String, Aggregator>(_v2, _v3), 6);
        let _v4 = &mut _v1.inner;
        let _v5 = *p0;
        let _v6 = table::borrow_mut<string::String, Aggregator>(_v4, _v5);
        let _v7 = pyth::get_stale_price_threshold_secs();
        let _v8 = *&_v6.max_age;
        let _v9 = math_1::min_u64(_v7, _v8);
        let _v10 = *&(&_v6.pyth_price).state;
        'l0: loop {
            'l2: loop {
                let _v11;
                let _v12;
                let _v13;
                let _v14;
                'l1: loop {
                    let _v15;
                    let _v16;
                    loop {
                        if (_v10) {
                            let _v17 = timestamp::now_seconds();
                            let _v18 = *&(&_v6.pyth_price).last_update_time;
                            if (!(abs_diff(_v17, _v18) >= _v9)) break 'l0;
                            _v15 = pyth::get_price_unsafe(price_identifier::from_byte_vec(*&(&_v6.pyth_price).identifier));
                            _v16 = price::get_timestamp(&_v15);
                            if (abs_diff(timestamp::now_seconds(), _v16) < _v9) break
                        };
                        if (*&(&_v6.switchboard_price).state) {
                            let (_v19,_v20,_v21) = math::unpack(aggregator::latest_value(*&(&_v6.switchboard_price).addr));
                            _v12 = _v21;
                            _v14 = _v20;
                            _v11 = _v19;
                            _v13 = aggregator::latest_round_timestamp(*&(&_v6.switchboard_price).addr);
                            let _v22 = abs_diff(timestamp::now_seconds(), _v13);
                            let _v23 = *&_v6.max_age;
                            if (_v22 < _v23) break 'l1
                        };
                        assert!(*&(&_v6.cex_price).state, 10);
                        let _v24 = timestamp::now_seconds();
                        let _v25 = *&(&_v6.cex_price).last_update_time;
                        let _v26 = abs_diff(_v24, _v25);
                        let _v27 = *&_v6.max_age;
                        if (_v26 < _v27) break 'l2;
                        abort 9
                    };
                    let _v28 = price::get_price(&_v15);
                    let _v29 = &mut (&mut _v6.pyth_price).price;
                    *_v29 = _v28;
                    let _v30 = price::get_expo(&_v15);
                    let _v31 = &mut (&mut _v6.pyth_price).exponent;
                    *_v31 = _v30;
                    let _v32 = &mut (&mut _v6.pyth_price).last_update_time;
                    *_v32 = _v16;
                    let _v33 = price::get_price(&_v15);
                    let _v34 = i64::get_magnitude_if_positive(&_v33);
                    let _v35 = price::get_expo(&_v15);
                    let _v36 = i64::get_magnitude_if_negative(&_v35);
                    let _v37 = (*&_v6.decimal) as u64;
                    let _v38 = _v36 + _v37;
                    return (_v34, _v38)
                };
                let _v39 = _v11 as u64;
                let _v40 = &mut (&mut _v6.switchboard_price).price;
                *_v40 = _v39;
                let _v41 = &mut (&mut _v6.switchboard_price).exponent;
                *_v41 = _v14;
                let _v42 = &mut (&mut _v6.switchboard_price).neg;
                *_v42 = _v12;
                let _v43 = &mut (&mut _v6.switchboard_price).last_update_time;
                *_v43 = _v13;
                let _v44 = *&(&_v6.switchboard_price).price;
                let _v45 = *&(&_v6.switchboard_price).exponent;
                let _v46 = *&_v6.decimal;
                let _v47 = (_v45 + _v46) as u64;
                return (_v44, _v47)
            };
            let _v48 = *&(&_v6.cex_price).price;
            let _v49 = *&(&_v6.cex_price).exponent;
            let _v50 = *&_v6.decimal;
            let _v51 = (_v49 + _v50) as u64;
            return (_v48, _v51)
        };
        let _v52 = i64::get_magnitude_if_positive(&(&_v6.pyth_price).price);
        let _v53 = i64::get_magnitude_if_negative(&(&_v6.pyth_price).exponent);
        let _v54 = (*&_v6.decimal) as u64;
        let _v55 = _v53 + _v54;
        (_v52, _v55)
    }
    public fun get_prices(p0: address, p1: string::String): Aggregator
        acquires PriceStore
    {
        if (!exists<PriceStore>(p0)) {
            let _v0 = error::not_found(1);
            abort _v0
        };
        *table::borrow<string::String, Aggregator>(&borrow_global<PriceStore>(p0).inner, p1)
    }
    public entry fun init(p0: &signer) {
        verify_account(p0);
        if (!!exists<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41)) {
            let _v0 = error::already_exists(3);
            abort _v0
        };
        let _v1 = PriceStore{inner: table::new<string::String, Aggregator>()};
        move_to<PriceStore>(p0, _v1);
    }
    fun modify_max_age<T0>(p0: u64)
        acquires PriceStore
    {
        if (!exists<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41)) {
            let _v0 = error::not_found(1);
            abort _v0
        };
        let _v1 = borrow_global_mut<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41);
        let _v2 = type_info::type_name<T0>();
        assert!(table::contains<string::String, Aggregator>(&_v1.inner, _v2), 6);
        let _v3 = &mut table::borrow_mut<string::String, Aggregator>(&mut _v1.inner, _v2).max_age;
        *_v3 = p0;
    }
    fun modify_price_id<T0>(p0: PriceId, p1: vector<u8>)
        acquires PriceStore
    {
        if (!exists<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41)) {
            let _v0 = error::not_found(1);
            abort _v0
        };
        let _v1 = borrow_global_mut<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41);
        let _v2 = type_info::type_name<T0>();
        assert!(table::contains<string::String, Aggregator>(&_v1.inner, _v2), 6);
        let _v3 = table::borrow_mut<string::String, Aggregator>(&mut _v1.inner, _v2);
        if (p1 == vector[80u8, 89u8, 84u8, 72u8]) {
            let _v4 = *&(&p0).identifier;
            let _v5 = &mut (&mut _v3.pyth_price).identifier;
            *_v5 = _v4
        } else if (p1 == vector[83u8, 87u8, 73u8, 84u8, 67u8, 72u8, 66u8, 79u8, 65u8, 82u8, 68u8]) {
            let _v6 = *&(&p0).addr;
            let _v7 = &mut (&mut _v3.switchboard_price).addr;
            *_v7 = _v6
        };
    }
    public entry fun modify_pyth_identifier<T0>(p0: &signer, p1: vector<u8>)
        acquires PriceStore
    {
        verify_account(p0);
        let _v0 = signer::address_of(p0);
        modify_price_id<T0>(PriceId{identifier: p1, addr: _v0}, vector[80u8, 89u8, 84u8, 72u8]);
    }
    public entry fun modify_switchboard_addr<T0>(p0: &signer, p1: address)
        acquires PriceStore
    {
        verify_account(p0);
        modify_price_id<T0>(PriceId{identifier: 0x1::vector::empty<u8>(), addr: p1}, vector[83u8, 87u8, 73u8, 84u8, 67u8, 72u8, 66u8, 79u8, 65u8, 82u8, 68u8]);
    }
    public entry fun update_cex_state<T0>(p0: &signer, p1: bool)
        acquires PriceStore
    {
        verify_account(p0);
        update_state<T0>(vector[68u8, 69u8, 88u8], p1);
    }
    public entry fun update_pyth_state<T0>(p0: &signer, p1: bool)
        acquires PriceStore
    {
        verify_account(p0);
        update_state<T0>(vector[80u8, 89u8, 84u8, 72u8], p1);
    }
    fun update_state<T0>(p0: vector<u8>, p1: bool)
        acquires PriceStore
    {
        if (!exists<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41)) {
            let _v0 = error::not_found(1);
            abort _v0
        };
        let _v1 = borrow_global_mut<PriceStore>(@0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41);
        let _v2 = type_info::type_name<T0>();
        assert!(table::contains<string::String, Aggregator>(&_v1.inner, _v2), 6);
        let _v3 = table::borrow_mut<string::String, Aggregator>(&mut _v1.inner, _v2);
        if (p0 == vector[68u8, 69u8, 88u8]) {
            let _v4 = &mut (&mut _v3.cex_price).state;
            *_v4 = p1
        } else if (p0 == vector[80u8, 89u8, 84u8, 72u8]) {
            let _v5 = &mut (&mut _v3.pyth_price).state;
            *_v5 = p1
        } else if (p0 == vector[83u8, 87u8, 73u8, 84u8, 67u8, 72u8, 66u8, 79u8, 65u8, 82u8, 68u8]) {
            if (*&(&_v3.switchboard_price).addr == @0x10) abort 11 else {
                let _v6 = &mut (&mut _v3.switchboard_price).state;
                *_v6 = p1
            }};
    }
    public entry fun update_switchboard_state<T0>(p0: &signer, p1: bool)
        acquires PriceStore
    {
        verify_account(p0);
        update_state<T0>(vector[83u8, 87u8, 73u8, 84u8, 67u8, 72u8, 66u8, 79u8, 65u8, 82u8, 68u8], p1);
    }
    fun verify_account(p0: &signer) {
        if (!(signer::address_of(p0) == @0xad1c729dd7e0e87a1983df3c51d5745a6367237cf930ccba8f76ddeab184e41)) {
            let _v0 = error::permission_denied(2);
            abort _v0
        };
    }
}
