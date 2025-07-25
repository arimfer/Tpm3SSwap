// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity >0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyTOKENB is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("MyTOKENB", "MTKB")
        Ownable(initialOwner)
    {
            _mint(initialOwner, 1000000 *(10**decimals()));
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}