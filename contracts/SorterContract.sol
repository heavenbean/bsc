// SPDX-License-Identifier: MIT
pragma solidity ^0.6.4;

contract SorterContract {
    function getValidators() public virtual pure returns(address[] memory) {
        address[] memory consensusAddrs = new address[](3);
        consensusAddrs[0] = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
        consensusAddrs[1] = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
        consensusAddrs[2] = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
        return consensusAddrs;
    }
}