use std::future::Future;
use std::pin::Pin;

use crate::codecs::BlockHeaderExt;
use crate::consensus::rho::rho;
use crate::models;

pub struct ChainSelectionConfig {
    pub k_lookback: u64,
    pub s_window: u64,
}

pub async fn chain_selection<Fetch>(
    config: &ChainSelectionConfig,
    header_x: &models::BlockHeader,
    header_y: &models::BlockHeader,
    common_ancestor: &models::BlockHeader,
    fetch_x: Fetch,
    fetch_y: Fetch,
) -> ChainSelectionOutcome
where
    Fetch: Fn(u64) -> Pin<Box<dyn Future<Output = Option<models::BlockHeader>>>>,
{
    if header_y.id() == common_ancestor.id() {
        return ChainSelectionOutcome::StandardX;
    } else if header_x.id() == common_ancestor.id() {
        return ChainSelectionOutcome::StandardY;
    } else if header_x.height - common_ancestor.height <= config.k_lookback
        && header_y.height - common_ancestor.height <= config.k_lookback
    {
        return chain_selection_standard(header_x, header_y);
    } else {
        return chain_selection_density(config, common_ancestor, fetch_x, fetch_y).await;
    }
}

fn chain_selection_standard(
    header_x: &models::BlockHeader,
    header_y: &models::BlockHeader,
) -> ChainSelectionOutcome {
    if header_x.height > header_y.height {
        return ChainSelectionOutcome::StandardX;
    } else if header_y.height > header_x.height {
        return ChainSelectionOutcome::StandardY;
    } else if header_x.slot > header_y.slot {
        return ChainSelectionOutcome::StandardY;
    } else if header_y.slot > header_x.slot {
        return ChainSelectionOutcome::StandardX;
    } else {
        let rho_x = rho(&header_x.staker_certificate.as_ref().unwrap().vrf_signature);
        let rho_y = rho(&header_y.staker_certificate.as_ref().unwrap().vrf_signature);
        for n in 0..rho_x.len() {
            if rho_x[n] > rho_y[n] {
                return ChainSelectionOutcome::StandardX;
            } else if rho_y[n] > rho_x[n] {
                return ChainSelectionOutcome::StandardY;
            }
        }
        panic!("VRF outputs are equal")
    }
}

async fn chain_selection_density<Fetch>(
    config: &ChainSelectionConfig,
    common_ancestor: &models::BlockHeader,
    fetch_x: Fetch,
    fetch_y: Fetch,
) -> ChainSelectionOutcome
where
    Fetch: Fn(u64) -> Pin<Box<dyn Future<Output = Option<models::BlockHeader>>>>,
{
    let mut x_boundary = common_ancestor.clone();
    loop {
        let f = fetch_x(x_boundary.height + 1).await;
        if let Some(n) = f {
            if n.slot - common_ancestor.slot >= config.s_window {
                break;
            }
            x_boundary = n;
        } else {
            break;
        }
    }
    if let Some(y) = fetch_y(x_boundary.height).await {
        if y.slot > x_boundary.slot {
            return ChainSelectionOutcome::DensityY;
        } else {
            return chain_selection_standard(&x_boundary, &y);
        }
    } else {
        return ChainSelectionOutcome::DensityX;
    }
}

pub enum ChainSelectionOutcome {
    StandardX,
    StandardY,
    DensityX,
    DensityY,
}
