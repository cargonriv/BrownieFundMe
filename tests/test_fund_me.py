from scripts.deploy import deploy_fund_me
from scripts.help import LOCAL_BLOCKCHAIN_ENVIRONMENTS, get_account
from brownie import network, accounts, exceptions
import pytest


def test_fund_and_withdraw():
    account = get_account()
    fund_me = deploy_fund_me()
    entrance_fee = fund_me.getEntranceFee() + 100

    fund_txn = fund_me.fund({"from": account, "value": entrance_fee})
    fund_txn.wait(1)
    assert fund_me.addressToAmountFunded(account.address) == entrance_fee

    withdraw_txn = fund_me.withdraw({"from": account})
    withdraw_txn.wait(1)
    assert fund_me.addressToAmountFunded(account.address) == 0


def test_only_owner_withdraw():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for LOCAL TESTING")
    account = get_account()
    fund_me = deploy_fund_me()
    bad_actor = accounts.add()
    fund_me.withdraw({"from": bad_actor})
    with pytest.raises(exceptions.VirtualMachineError):
        fund_me.withdraw({"from": account})
