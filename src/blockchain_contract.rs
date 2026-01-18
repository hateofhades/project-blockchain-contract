#![no_std]

#[allow(unused_imports)]
use multiversx_sc::imports::*;
use multiversx_sc::proxy_imports::*;

#[type_abi]
#[derive(NestedEncode, NestedDecode, PartialEq)]
pub enum Status {
    PROPOSED,
    APPROVED,
    REJECTED,
}

#[type_abi]
#[derive(TopEncode, TopDecode, NestedEncode, NestedDecode)]
pub struct Slot<M: ManagedTypeApi> {
    pub version: ManagedBuffer<M>,
    pub hash: ManagedBuffer<M>,
    pub url: ManagedBuffer<M>,
    pub status: Status,
    pub approvals: ManagedVec<M, ManagedAddress<M>>,
    pub creator: ManagedAddress<M>,
}

/// An empty contract. To be used as a template when starting a new contract from scratch.
#[multiversx_sc::contract]
pub trait BlockchainContract {
    #[init]
    fn init(&self) {}

    #[upgrade]
    fn upgrade(&self) {}

    // events
    #[event("set_required_approvals")]
    fn set_required_approvals_event(&self, #[indexed] approvals: &u32);

    #[event("add_admin")]
    fn add_admin_event(&self, #[indexed] admin: &ManagedAddress);

    #[event("remove_admin")]
    fn remove_admin_event(&self, #[indexed] admin: &ManagedAddress);

    #[event("reject_release")]
    fn reject_release_event(&self, #[indexed] version: &ManagedBuffer);

    #[event("approve_release")]
    fn approve_release_event(&self, #[indexed] version: &ManagedBuffer);

    #[event("propose_release")]
    fn propose_release_event(&self, #[indexed] version: &ManagedBuffer);

    // endpoints
    #[endpoint(getRelease)]
    fn get_release(&self, version: ManagedBuffer) -> Slot<Self::Api> {
        self.slots().get(&version.into()).unwrap_or_else(|| {
            sc_panic!("Version not found");
        })
    }

    #[endpoint(proposeRelease)]
    fn propose_release(&self, version: ManagedBuffer, hash: ManagedBuffer, url: ManagedBuffer) {
        let caller = self.blockchain().get_caller();

        if self.admins().contains(&caller) == false
            && caller != self.blockchain().get_owner_address()
        {
            sc_panic!("Only admins and owner can propose releases");
        }

        if self.slots().contains_key(&version.clone()) {
            sc_panic!("Version already proposed");
        }

        let slot = Slot {
            version: version.clone(),
            hash: hash.clone(),
            url: url.clone(),
            status: Status::PROPOSED,
            approvals: ManagedVec::new(),
            creator: caller,
        };

        self.slots().insert(version.clone(), slot);
        self.propose_release_event(&version);
    }

    #[endpoint(approveRelease)]
    fn approve_release(&self, version: ManagedBuffer) {
        let caller = self.blockchain().get_caller();

        if self.admins().contains(&caller) == false
            && caller != self.blockchain().get_owner_address()
        {
            sc_panic!("Only admins and owner can approve releases");
        }

        let mut slot = self.slots().get(&version.clone()).unwrap_or_else(|| {
            sc_panic!("Version not found");
        });

        if slot.status != Status::PROPOSED {
            sc_panic!("Only proposed releases can be approved");
        }

        if slot.approvals.contains(&caller) || slot.creator == caller {
            sc_panic!("You have already approved this release");
        }

        slot.approvals.push(caller);

        if slot.approvals.len() as u32 >= self.required_approvals().get() {
            slot.status = Status::APPROVED;
        }

        self.slots().insert(version.clone(), slot);
        self.approve_release_event(&version);
    }

    #[endpoint(rejectRelease)]
    fn reject_release(&self, version: ManagedBuffer) {
        let caller = self.blockchain().get_caller();

        if self.admins().contains(&caller) == false
            && caller != self.blockchain().get_owner_address()
        {
            sc_panic!("Only admins and owner can reject releases");
        }

        let mut slot = self.slots().get(&version.clone()).unwrap_or_else(|| {
            sc_panic!("Version not found");
        });

        if slot.status != Status::PROPOSED {
            sc_panic!("Only proposed releases can be rejected");
        }

        slot.status = Status::REJECTED;

        self.slots().insert(version.clone(), slot);
        self.reject_release_event(&version);
    }

    #[only_owner]
    #[endpoint(setRequiredApprovals)]
    fn set_required_approvals(&self, approvals: u32) {
        self.required_approvals().set(approvals.clone());
        self.set_required_approvals_event(&approvals);
    }

    #[only_owner]
    #[endpoint(addAdmin)]
    fn add_admin(&self, admin: ManagedAddress) {
        self.admins().insert(admin.clone());
        self.add_admin_event(&admin);
    }

    #[only_owner]
    #[endpoint(removeAdmin)]
    fn remove_admin(&self, admin: ManagedAddress) {
        self.admins().remove(&admin);
        self.remove_admin_event(&admin);
    }

    // storage mappers

    // Address of the people that can upload and approve firmware
    #[view(getAdmins)]
    #[storage_mapper("admins")]
    fn admins(&self) -> SetMapper<ManagedAddress>;

    // required approvals
    #[view(getRequiredApprovals)]
    #[storage_mapper("required_approvals")]
    fn required_approvals(&self) -> SingleValueMapper<u32>;

    // firmware slots
    #[view(getSlots)]
    #[storage_mapper("slots")]
    fn slots(&self) -> MapMapper<ManagedBuffer, Slot<Self::Api>>;
}
