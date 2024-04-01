// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRegistry {
    // Errors
    error EntryAlreadyExistsError(bytes4);
    error EntryNonExistentError(bytes4);
    error EntryNotInChangeError(bytes4);
    error ChangeNotReadyError(uint256, uint256);
    error EmptyPrevAddrError(bytes4);
    error AlreadyInContractChangeError(bytes4);
    error AlreadyInWaitPeriodChangeError(bytes4);

    // Events
    event AddNewContract(address indexed sender, bytes4 id, address contractAddr, uint256 waitPeriod);
    event RevertToPreviousAddress(address indexed sender, bytes4 id, address currentAddr, address previousAddr);
    event StartContractChange(address indexed sender, bytes4 id, address currentAddr, address newContractAddr);
    event ApproveContractChange(address indexed sender, bytes4 id, address oldContractAddr, address newContractAddr);
    event CancelContractChange(address indexed sender, bytes4 id, address oldContractAddr, address currentAddr);
    event StartWaitPeriodChange(address indexed sender, bytes4 id, uint256 newWaitPeriod);
    event ApproveWaitPeriodChange(address indexed sender, bytes4 id, uint256 oldWaitTime, uint256 newWaitTime);
    event CancelWaitPeriodChange(address indexed sender, bytes4 id, uint256 oldWaitPeriod, uint256 currentWaitPeriod);

    event AddNewThirdPartyContract(address indexed sender, bytes4 id, address contractAddr);
    event EditThirdPartyContract(address indexed sender, bytes4 id, address oldContractAddr, address newContractAddr);

    // Functions
    function owner() external view returns (address);
    function getAddr(bytes4 _id) external view returns (address);
    function isVerifiedContract(bytes4 _id) external view returns (bool);
    function isVerifiedContract(address _addr) external view returns (bool);
    function isRegistered(bytes4 _id) external view returns (bool);
    function addNewContract(bytes4 _id, address _contractAddr, uint256 _waitPeriod) external returns (bytes4);
    function revertToPreviousAddress(bytes4 _id) external;
    function startContractChange(bytes4 _id, address _newContractAddr) external;
    function approveContractChange(bytes4 _id) external;
    function cancelContractChange(bytes4 _id) external;
    function startWaitPeriodChange(bytes4 _id, uint256 _newWaitPeriod) external;
    function approveWaitPeriodChange(bytes4 _id) external;
    function cancelWaitPeriodChange(bytes4 _id) external;
    function addNewThirdPartyContract(address _contractAddr) external returns (bytes4);
}
