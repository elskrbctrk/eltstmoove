module 0x3c1d4a86594d681ff7e5d5a233965daeabdc6a15fe5672ceeda5260038857183::math {
    public fun min_u64(p0: u64, p1: u64): u64 {
        let _v0;
        if (p0 < p1) _v0 = p0 else _v0 = p1;
        _v0
    }
    public fun mul_div(p0: u64, p1: u64, p2: u64): u64 {
        assert!(p2 != 0, 2000);
        let _v0 = p0 as u128;
        let _v1 = p1 as u128;
        let _v2 = _v0 * _v1;
        let _v3 = p2 as u128;
        (_v2 / _v3) as u64
    }
    public fun mul_div_u128(p0: u128, p1: u128, p2: u128): u64 {
        assert!(p2 != 0u128, 2000);
        (p0 * p1 / p2) as u64
    }
    public fun mul_to_u128(p0: u64, p1: u64): u128 {
        let _v0 = p0 as u128;
        let _v1 = p1 as u128;
        _v0 * _v1
    }
    public fun overflow_add(p0: u128, p1: u128): u128 {
        let _v0 = MAX_U128 - p1;
        let _v1 = _v0 < p0;
        loop {
            if (_v1) return p0 - _v0 - 1u128 else {
                _v0 = MAX_U128 - p0;
                if (!(_v0 < p1)) break
            };
            return p1 - _v0 - 1u128
        };
        p0 + p1
    }
    public fun pow_10(p0: u8): u64 {
        let _v0 = 1;
        let _v1 = 0u8;
        while (_v1 < p0) {
            _v0 = _v0 * 10;
            _v1 = _v1 + 1u8
        };
        _v0
    }
    public fun sqrt(p0: u128): u64 {
        let _v0;
        if (p0 < 4u128) {
            let _v1;
            if (p0 == 0u128) _v1 = 0 else _v1 = 1;
            _v0 = _v1
        } else {
            let _v2 = p0;
            let _v3 = p0 / 2u128 + 1u128;
            while (_v3 < _v2) {
                _v2 = _v3;
                _v3 = (p0 / _v3 + _v3) / 2u128
            };
            _v0 = _v2 as u64
        };
        _v0
    }
}
