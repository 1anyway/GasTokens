// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IGasToken.sol";
import "./libs/GasLib.sol";
import {console} from "forge-std/console.sol";

// ERC20Mintable
// ERC20Burnable
// ERC20Taxable
// ERC20Redistributable

contract GasToken is IGasToken, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant TAX_FEE = 4;
    uint256 public constant DENOMINATOR = 100;

    string private _name = "GasToken";
    string private _symbol = "GAS";
    uint256 private _totalSupply = 1_000_000_000 * 10 ** 18;

    uint256 private _effectiveTotal;

    GasLib.uq112x112 private _earningFactor; // global earning factor
    mapping(address => uint256) private _balances; // effective balance
    mapping(address => GasLib.uq112x112) private _snapshots; // earning factor snapshots
    mapping(address => mapping(address => uint256)) private _allowances;

    EnumerableSet.AddressSet private _isExcluded; // excluded from tax

    receive() external payable {}

    constructor() {
        _balances[_msgSender()] = _totalSupply;
        _effectiveTotal = _totalSupply;
        _earningFactor = GasLib.fraction(1, 1);
    }

    // uq112x112 x = GasLib.fraction(37, 13); // 37 / 13
    // uq112x112 y = GasLib.fraction(91, 23); // 91 / 23
    // uq112x112 z1 = GasLib.muluq(x, y); // 37 * 91 / (13 * 23)
    // uq112x112 z2 = GasLib.divuq(x, y); // (37 / 13) / (91 / 23)
    // uint256 z3 = GasLib.mulu(z1, 10 ** 18); // 37 * 91 / (13 * 23) * 10 ** 18

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function getEffectiveTotal() external view override returns (uint256) {
        return _effectiveTotal;
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        if (_isExcluded.contains(account)) return _balances[account];
        return _getEffectiveBalance(account);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function includeAccount(address account) public override onlyOwner {
        require(_isExcluded.contains(account), "Already included");
        _isExcluded.remove(account);
        _snapshots[account] = _earningFactor;
        _effectiveTotal += _getEffectiveBalance(account); // TODO: check, before or after snapshot?
    }

    function excludeAccount(address account) public override onlyOwner {
        require(!_isExcluded.contains(account), "Already excluded");
        _isExcluded.add(account);
        uint256 balance = _getEffectiveBalance(account);
        _balances[account] = balance;
        _effectiveTotal -= balance;
        _snapshots[account] = _earningFactor;
    }

    function getEarningFactor() external view override returns (uint256) {
        return GasLib.mulu(_earningFactor, 10 ** decimals());
    }

    function getSnapshot(
        address account
    ) external view override returns (uint256) {
        return GasLib.mulu(_snapshots[account], 10 ** decimals());
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from address(0)");
        require(recipient != address(0), "ERC20: transfer to address(0)");

        bool taxless = _checkTaxless(sender, recipient);
        uint256 fromBalance = _getEffectiveBalance(sender);
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[sender] = fromBalance - amount;
        _updateSnapshot(sender);
        // 1. with tax
        // 2. without tax
        if (taxless) {
            _balances[recipient] = _getEffectiveBalance(recipient) + amount;
        } else {
            _balances[recipient] =
                _getEffectiveBalance(recipient) +
                _takeTax(amount);
        }
        _updateSnapshot(recipient);

        _updateEffectiveTotal(sender, recipient, amount);

        if (!taxless) _updateEarningFactor(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _takeTax(uint256 amount) private pure returns (uint256) {
        return (amount * (DENOMINATOR - TAX_FEE)) / DENOMINATOR;
    }

    function _updateSnapshot(address account) private {
        if (!_isExcluded.contains(account)) {
            _snapshots[account] = _earningFactor;
        }
    }

    function _updateEarningFactor(uint256 _amount) private {
        uint256 _taxFee = (_amount * TAX_FEE) / DENOMINATOR;
        GasLib.uq112x112 memory factor = _getFactor(_taxFee);
        _earningFactor = GasLib.muluq(_earningFactor, factor);
    }

    function _checkTaxless(
        address sender,
        address recipient
    ) private view returns (bool) {
        bool flag1 = _isExcluded.contains(sender);
        bool flag2 = _isExcluded.contains(recipient);
        return flag1 || flag2;
    }

    function _updateEffectiveTotal(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        bool flag1 = _isExcluded.contains(sender);
        bool flag2 = _isExcluded.contains(recipient);

        if (flag1 && !flag2) {
            _effectiveTotal += amount;
        }

        if (!flag1 && flag2) {
            _effectiveTotal -= amount;
        }
    }

    function _getEffectiveBalance(address addr) private view returns (uint256) {
        uint256 balance = _balances[addr];
        GasLib.uq112x112 memory lastEarningFactor = _snapshots[addr];
        if (lastEarningFactor._x == 0) return balance;
        console.log("balance");
        if (lastEarningFactor._x == _earningFactor._x) return balance;
        console.log("c");
        GasLib.uq112x112 memory newEarningFactor = GasLib.divuq(
            _earningFactor,
            lastEarningFactor
        );
        return GasLib.mulu(newEarningFactor, balance);
    }

    // Factor m = T / (T - f)
    function _getFactor(
        uint256 _taxFee
    ) private view returns (GasLib.uq112x112 memory) {
        uint256 total = _effectiveTotal; // T in the paper
        return GasLib.fraction(total, total - _taxFee);
    }
}