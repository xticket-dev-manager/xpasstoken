// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Abstract contract defining basic ERC20 functionalities
abstract contract ERC20Basic {
    // Function to get the total supply of tokens
    function totalSupply() public view virtual returns (uint256);

    // Function to get the balance of a specific address
    function balanceOf(address who) public view virtual returns (uint256);

    // Function to transfer tokens from msg.sender to another address
    function transfer(address to, uint256 value) public virtual returns (bool);

    // Event emitted when tokens are transferred
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// Basic implementation of the ERC20Basic contract
contract BasicToken is ERC20Basic {
    // Mapping from address to token balance
    mapping(address => uint256) balances;

    // Total supply of tokens
    uint256 totalSupply_;

    // Function to get the total supply of tokens
    function totalSupply() public view virtual override returns (uint256) {
        return totalSupply_;
    }

    // Function to transfer tokens from msg.sender to another address
    function transfer(address _to, uint256 _value) public virtual override returns (bool) {
        require(_to != address(0), "Invalid to");
        uint256 senderBalance = balances[msg.sender];
        require(_value <= senderBalance, "No balance");

        balances[msg.sender] = senderBalance - _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    // Function to get the balance of a specific address
    function balanceOf(address _owner) public view virtual override returns (uint256 balance) {
        return balances[_owner];
    }
}

// Contract for managing ownership of the token
contract Ownable {
    address public owner;

    // Event emitted when ownership is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Constructor sets the initial owner to the msg.sender
    constructor() {
        owner = msg.sender;
    }

    // Modifier to check if msg.sender is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Function to transfer ownership to a new address
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// Extension of BasicToken with burn functionality
contract BurnableToken is BasicToken {
    // Event emitted when tokens are burned
    event Burn(address indexed burner, uint256 value);

    // Function to burn tokens from msg.sender's balance
    function burn(uint256 _value) public virtual {
        uint256 accountBalance = balances[msg.sender];
        require(_value <= accountBalance, "No balance");

        balances[msg.sender] = accountBalance - _value;
        totalSupply_ -= _value;

        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }
}

// Abstract contract extending ERC20Basic with additional functionalities
abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view virtual returns (uint256);
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    function approve(address spender, uint256 value) public virtual returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Standard implementation of the ERC20 token
contract StandardToken is ERC20, BasicToken {
    // Mapping from owner to spender to allowance amount
    mapping(address => mapping(address => uint256)) internal allowed;

    // Function to transfer tokens from one address to another using allowance
    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {
        require(_to != address(0), "Invalid to");
        uint256 fromBalance = balances[_from];
        uint256 allowanceValue = allowed[_from][msg.sender];
        require(_value <= fromBalance, "No balance");
        require(_value <= allowanceValue, "No allowance");

        balances[_from] = fromBalance - _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] = allowanceValue - _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    // Function to approve an allowance for a spender
    function approve(address _spender, uint256 _value) public virtual override returns (bool) {
        require(_spender != address(0), "Invalid spender address"); // Check if the spender address is zero
        require(allowed[msg.sender][_spender] == 0 || _value == 0, "Use increase/decreaseAllowance");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Function to increase the allowance for a spender
    function increaseAllowance(address _spender, uint256 _addedValue) public virtual override returns (bool) {
        uint256 newAllowance = allowed[msg.sender][_spender] + _addedValue;
        allowed[msg.sender][_spender] = newAllowance;
        emit Approval(msg.sender, _spender, newAllowance);
        return true;
    }

    // Function to decrease the allowance for a spender
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual override returns (bool) {
        uint256 currentAllowance = allowed[msg.sender][_spender];
        require(currentAllowance >= _subtractedValue, "Below zero allowance");
        uint256 newAllowance = currentAllowance - _subtractedValue;
        allowed[msg.sender][_spender] = newAllowance;
        emit Approval(msg.sender, _spender, newAllowance);
        return true;
    }

    // Function to get the allowance of a spender for a specific owner
    function allowance(address _owner, address _spender) public view virtual override returns (uint256) {
        return allowed[_owner][_spender];
    }
}

// The main token contract implementing all functionalities
contract XPASSToken is StandardToken, BurnableToken, Ownable {
    string public constant symbol = "XPASS";
    string public constant name = "X-PASS";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * (10 ** uint256(decimals)); 

    address public adminAddr;

    bool public transferEnabled;

    // Mapping to keep track of locked accounts
    mapping(address => uint256) private lockedAccounts;

    // Modifier to check if transfers are allowed
    modifier onlyWhenTransferAllowed() {
        require(transferEnabled == true || msg.sender == adminAddr, "No transfers");
        _;
    }

    // Modifier to check if the destination address is valid
    modifier onlyValidDestination(address to) {
        require(to != address(0) && to != address(this) && to != owner && to != adminAddr, "Invalid dest");
        _;
    }

    // Modifier to check if the amount is allowed considering locked balance
    modifier onlyAllowedAmount(address from, uint256 amount) {
        require(balances[from] - amount >= lockedAccounts[from], "Exceeds locked");
        _;
    }

    // Constructor setting initial supply and enabling transfers
    constructor() {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
        adminAddr = msg.sender;
        transferEnabled = true;
    }

    // Event emitted when transfers are enabled
    event TransferEnabled();

    // Event emitted when transfers are disabled
    event TransferDisabled();

    // Event emitted when admin address is changed
    event AdminAddrChanged(address indexed previousAdminAddr, address indexed newAdminAddr);

    // Function to enable transfers
    function enableTransfer() external onlyOwner {
        transferEnabled = true;
        emit TransferEnabled();
    }

    // Function to disable transfers
    function disableTransfer() external onlyOwner {
        transferEnabled = false;
        emit TransferDisabled();
    }

    // Overriding transfer function with additional checks
    function transfer(address to, uint256 value)
        public
        override(BasicToken, ERC20Basic)
        onlyWhenTransferAllowed
        onlyValidDestination(to)
        onlyAllowedAmount(msg.sender, value)
        returns (bool)
    {
        return super.transfer(to, value);
    }

    // Overriding transferFrom function with additional checks
    function transferFrom(address from, address to, uint256 value)
        public
        override(StandardToken)
        onlyWhenTransferAllowed
        onlyValidDestination(to)
        onlyAllowedAmount(from, value)
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }

    // Overriding burn function to allow only owner to burn tokens when transfers are enabled
    function burn(uint256 value) public override onlyOwner {
        require(transferEnabled, "No burns");
        super.burn(value);
    }

    // Event emitted when an account is locked
    event AccountLocked(address indexed addr, uint256 amount);

    // Event emitted when an account is unlocked
    event AccountUnlocked(address indexed addr);

    // Function to lock an account with a specified amount
    function lockAccount(address addr, uint256 amount)
        external
        onlyOwner
        onlyValidDestination(addr)
    {
        require(amount > 0, "Invalid amount");
        lockedAccounts[addr] = amount;
        emit AccountLocked(addr, amount);
    }

    // Function to unlock an account
    function unlockAccount(address addr)
        external
        onlyOwner
        onlyValidDestination(addr)
    {
        lockedAccounts[addr] = 0;
        emit AccountUnlocked(addr);
    }

    // Function to change the admin address
    function changeAdminAddr(address newAdminAddr) external onlyOwner {
        require(newAdminAddr != address(0), "Invalid admin");
        address oldAdminAddr = adminAddr;
        adminAddr = newAdminAddr;
        emit AdminAddrChanged(oldAdminAddr, newAdminAddr);
    }  
}