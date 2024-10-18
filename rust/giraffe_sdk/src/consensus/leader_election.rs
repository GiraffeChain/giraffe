use std::ops::Neg;

use crate::consensus::rho::rho_test_hash;
use num_bigint::{BigInt, Sign};
use num_rational::BigRational;
use num_traits::Signed;

fn r0() -> BigRational {
    BigRational::from_integer(BigInt::from(0))
}
fn r1() -> BigRational {
    BigRational::from_integer(BigInt::from(1))
}

pub fn get_threshold(
    vrf_amplitude: BigRational,
    relative_stake: BigRational,
    slot_diff: u64,
) -> BigRational {
    let difficulty_curve = vrf_amplitude * BigInt::from(slot_diff);
    if difficulty_curve == r1() {
        return difficulty_curve;
    } else {
        let coefficient = log1p(r1().neg() * difficulty_curve);
        let result = exp(coefficient * relative_stake);
        return r1() - result;
    }
}

pub fn is_eligible(threshold: BigRational, rho: Vec<u8>) -> bool {
    let rth = rho_test_hash(rho);
    let test = BigRational::new(
        BigInt::from_bytes_be(Sign::Plus, &rth),
        BigInt::from(2).pow(512),
    );
    threshold > test
}

fn log1p(x: BigRational) -> BigRational {
    let a = |j: u32| match j {
        0 => r0(),
        1 => x.clone(),
        _ => {
            BigRational::new(BigInt::from(j) - 1, BigInt::from(1))
                * BigRational::new(BigInt::from(j) - 1, BigInt::from(1))
                * x.clone()
        }
    };
    let b = |j: u32| match j {
        0 => r0(),
        1 => r1(),
        _ => {
            BigRational::from_integer(BigInt::from(j))
                - BigRational::from_integer(BigInt::from(j) - 1) * x.clone()
        }
    };
    lentz(LENTZ_PRECISION_LOG1P, a, b)
}

fn exp(x: BigRational) -> BigRational {
    if x == r0() {
        return r1();
    } else {
        let a = |j: u32| match j {
            0 => r0(),
            1 => r1(),
            2 => x.clone().neg(),
            _ => BigRational::from_integer(BigInt::from(-(j as i32) + 2)) * x.clone(),
        };
        let b = |j: u32| match j {
            0 => r0(),
            1 => r1(),
            _ => BigRational::from_integer(BigInt::from((j as i32) - 1)) + x.clone(),
        };
        return lentz(LENTZ_PRECISION_EXP, a, b);
    }
}

const LENTZ_PRECISION_LOG1P: u32 = 8;
const LENTZ_PRECISION_EXP: u32 = 38;
const LENTZ_ITERATIONS: u32 = 10000;

pub fn lentz<FA, FB>(precision: u32, a: FA, b: FB) -> BigRational
where
    FA: Fn(u32) -> BigRational,
    FB: Fn(u32) -> BigRational,
{
    let big_factor = BigInt::from(10).pow(precision + 10);
    let tiny_factor = BigRational::new(BigInt::from(1), big_factor);
    let truncation_error = BigRational::new(BigInt::from(1), BigInt::from(1).pow(precision + 1));
    let mut fj = if b(0) == r0() {
        tiny_factor.clone()
    } else {
        b(0)
    };
    let mut cj = fj.clone();
    let mut dj = r0();
    let mut deltaj = r1();
    let mut error = true;

    for j in 1..LENTZ_ITERATIONS {
        dj = b(j) + a(j) * dj;
        if dj == r0() {
            dj = tiny_factor.clone();
        }
        cj = b(j) + a(j) / cj;
        if cj == r0() {
            cj = tiny_factor.clone();
        }
        dj = dj.recip();
        deltaj = cj.clone() * dj.clone();
        fj = fj.clone() * deltaj.clone();
        if j > 1 {
            error = (deltaj.clone() - r1()).abs() > truncation_error;
        }
        if !error {
            break;
        }
    }

    if fj.denom() < &BigInt::ZERO {
        fj = BigRational::new(-fj.numer().clone(), -fj.denom().clone());
    }

    fj
}
