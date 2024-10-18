pub struct Clock {
    pub slot_duration_ms: u64,
    pub genesis_time: u64,
    pub epoch_length_slots: u64,
}

impl Clock {
    pub fn epoch_of(&self, slot: i64) -> i64 {
        if slot == 0 {
            return -1;
        } else if slot < 0 {
            return -2;
        } else {
            return (slot - 1) / (self.epoch_length_slots as i64);
        }
    }

    pub fn epoch_range(&self, epoch: i64) -> (i64, i64) {
        if epoch == -1 {
            return (0, 0);
        } else if epoch < -1 {
            return (-1, -1);
        } else {
            return (
                epoch * (self.epoch_length_slots as i64),
                (epoch + 1) * (self.epoch_length_slots as i64),
            );
        }
    }
}
