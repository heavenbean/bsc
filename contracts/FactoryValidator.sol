// SPDX-License-Identifier: MIT
pragma solidity ^0.6.4;

/**
 * Copyright (c) 2016-2019 zOS Global Limited
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
* A contract to automatically forward Coin to main address and create the payment event
*/
contract FactoryValidator {

    using SafeMath for uint256;

    struct Validator {
        address consensusAddress;
        address payable feeAddress;
        uint256 votingPower;

        uint256 incoming;
        bool jailed;
    }

    mapping(address =>uint256) public currentValidatorSetMap;
    Validator[] validatorSet;
    Validator[] currentValidatorSet;
    uint256 public totalInComing;
    uint256 constant public DUSTY_INCOMING = 1e17;

    uint32 public constant CODE_OK = 0;
    uint256 public numOfJailed;
    uint256 public numOfValidator;

    // for future governance
    address public SuperAdminAddr; // super admin can change any external addresses
    address public ValidatorManager; // future Validator management contract
    address public ValidatorSorter; // future Validator sorting contract
    
    event validatorDeposit(address indexed validator, uint256 amount);
    event deprecatedDeposit(address indexed validator, uint256 amount);
    event validatorEmptyJailed(address indexed validator);
    event validatorJailed(address indexed validator);
    event validatorAdded(address indexed validator);
    event validatorReplaced(address oldValidator, address newValidator);
    event payReward(address validator, uint256 amount);
    
    event ownerChanged(address newAdmin);
    event validatorManagerChanged(address newManager);
    event validatorSorterChanged(address newSorter);

    modifier onlySuperAdmin() {
        require(msg.sender == SuperAdminAddr || msg.sender == ValidatorManager);
        _;
    }

    constructor() public {
        SuperAdminAddr = msg.sender;

        Validator memory val;
        val.consensusAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        val.feeAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        val.votingPower = 1000;
        currentValidatorSet.push(val);
        currentValidatorSetMap[val.consensusAddress] = 1;
        numOfValidator = 1;
    }

    function deposit(address valAddr) external payable {
        require(msg.value > 0, 'Deposit value too small');

        uint256 value = msg.value;
        uint256 index = currentValidatorSetMap[valAddr];
        if (index>0) {
        Validator storage validator = currentValidatorSet[index-1];
        if (validator.jailed) {
            emit deprecatedDeposit(valAddr,value);
        } else {
            totalInComing = totalInComing.add(value);
            validator.incoming = validator.incoming.add(value);
            emit validatorDeposit(valAddr,value);
        }
        } else {
        // get incoming from deprecated validator;
        emit deprecatedDeposit(valAddr,value);
        }
    }

    function jailValidator(address consensusAddress) external onlySuperAdmin() returns (uint32) {
        uint256 index = currentValidatorSetMap[consensusAddress];
        if (index==0 || currentValidatorSet[index-1].jailed) {
            emit validatorEmptyJailed(consensusAddress);
            return CODE_OK;
        }
        uint n = currentValidatorSet.length;
        bool shouldKeep = (numOfJailed >= n-1);
        // will not jail if it is the last valid validator
        if (shouldKeep) {
            emit validatorEmptyJailed(consensusAddress);
            return CODE_OK;
        }
        numOfJailed ++;
        currentValidatorSet[index-1].jailed = true;
        emit validatorJailed(consensusAddress);
        return CODE_OK;
    }

    function getValidators() external view returns(address[] memory) {
        if (ValidatorSorter != address(0x0)) {
            return SorterContract(ValidatorSorter).getValidators();
        }
        
        uint n = currentValidatorSet.length;
        uint valid = 0;
        for (uint i = 0;i<n;i++) {
            if (!currentValidatorSet[i].jailed) {
                valid ++;
            }
        }

        address[] memory consensusAddrs = new address[](valid);
        valid = 0;
        for (uint i = 0;i<n;i++) {
            if (!currentValidatorSet[i].jailed) {
                consensusAddrs[valid] = currentValidatorSet[i].consensusAddress;
                valid ++;
            }
        }
        return consensusAddrs;
    }
    
    function addValidator(address consensusAddress, address payable feeAddress, uint256 votingPower) public onlySuperAdmin() returns(uint256 index) {
        require(currentValidatorSetMap[consensusAddress] == 0, 'This validator is exists!');

        Validator memory val;
        val.consensusAddress = consensusAddress;
        val.feeAddress = feeAddress;
        val.votingPower = votingPower;
        currentValidatorSet.push(val);
        currentValidatorSetMap[val.consensusAddress] = numOfValidator + 1;
        numOfValidator = numOfValidator + 1;
        
        emit validatorAdded(consensusAddress);
        return numOfValidator - 1;
    }
    
    function replaceValidator(address consensusAddress, address payable feeAddress, uint256 votingPower, uint256 index) public onlySuperAdmin() {
        require(currentValidatorSet[index].consensusAddress != address(0x0), 'This validator is replaced!');
        require(currentValidatorSetMap[consensusAddress] == 0, 'This validator is exists!');
        
        // TODO: pay reward to old validator
        // TODO: reset incoming, jailed value
        
        // reset currentValidatorSetMap
        address oldValidator = currentValidatorSet[index].consensusAddress;
        currentValidatorSetMap[oldValidator] = 0;
        
        Validator memory val;
        val.consensusAddress = consensusAddress;
        val.feeAddress = feeAddress;
        val.votingPower = votingPower;
        currentValidatorSet[index] = val;
        currentValidatorSetMap[val.consensusAddress] = index + 1;
        
        emit validatorReplaced(oldValidator, val.consensusAddress);
    }

    function getIncoming(address validator)external view returns(uint256) {
        uint256 index = currentValidatorSetMap[validator];
        if (index<=0) {
            return 0;
        }
        return currentValidatorSet[index-1].incoming;
    }

    function withdraw(address validator, uint256 amount) public returns(uint256 remaining) {
        uint256 index = currentValidatorSetMap[validator];
        uint256 incoming = currentValidatorSet[index-1].incoming;
        
        require(currentValidatorSet[index-1].feeAddress == msg.sender, 'This must be called from feeAddress');
        require(incoming >= DUSTY_INCOMING, 'Incoming too small!');
        require(incoming >= amount, 'Insufficient balance!');

        currentValidatorSet[index-1].feeAddress.transfer(amount);
        incoming = incoming.sub(amount);
        currentValidatorSet[index-1].incoming = incoming;

        emit payReward(validator, amount);

        return incoming;
    }
    
    function changeSuperAdmin(address newAdmin) public onlySuperAdmin() {
        SuperAdminAddr = newAdmin;
        emit ownerChanged(newAdmin);
    }
    
    function changeValidatorManager(address newAddr) public onlySuperAdmin() {
        ValidatorManager = newAddr;
        emit validatorManagerChanged(newAddr);
    }
    
    function changeValidatorSorter(address newAddr) public onlySuperAdmin() {
        ValidatorSorter = newAddr;
        emit validatorSorterChanged(newAddr);
    }
}

abstract contract SorterContract {
    function getValidators() public virtual view returns(address[] memory);
}