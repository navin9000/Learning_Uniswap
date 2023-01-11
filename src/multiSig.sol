//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

///@title  multi Signature Wallet creation
///@author naveen pulamarasetti
///@notice creating a 3-5 multisig wallet for transfer of funds
///@custom:experimental this is an experimental model

contract MultiSig {
    uint256 public noOfConfirmations;
    address[] public owners;
    uint256 public minConfirmations = 3;
    uint256 public index = 1;

    //mapping(address => true/false)
    mapping(address => bool) public isOwner;
    //mapping(owner => index) to query the details of proposal by owner
    mapping(address => uint256) public ownerProposalIndex;
    //mapping(index => mapping(owner => true/false))proposalConfirmations
    mapping(uint256 => mapping(address => bool)) public proposalConfirmations;

    //events
    ///@notice proposalTransation Event
    event PropsalTransactionEvent(address, address, uint256, uint256);

    ///@notice confirmationTranaction event
    event ConfirmationTransactionEvent(address, uint256);

    ///@notice executionTransaction event
    event ExecutionTransactionEvent();

    ///@notice revokeProposalTransaction event
    event RevokePropsalTransactionEvent();

    //modifiers
    modifier onlyOwner() {
        require(isOwner[msg.sender], "you are not owner");
        _;
    }

    ///@notice which is a array of transactions proposals, each transaction is maintained at single index
    struct Transactions {
        address to;
        uint256 value;
        bool executed;
        uint256 numConfirmations;
    }
    Transactions[] public transactions;

    constructor(address[] memory _owners, uint256 _noOfconfirmations) {
        //recommanded way
        owners = _owners;
        noOfConfirmations = _noOfconfirmations;

        for (uint256 i = 0; i < owners.length; ++i) {
            require(!isOwner[_owners[i]], "aleardy existing owner");
            owners[i] = _owners[i];
            isOwner[_owners[i]] = true;
        }
        ///intial to 0
        transactions.push(
            Transactions({
                to: address(0),
                value: 0,
                executed: false,
                numConfirmations: 0
            })
        );
    }

    receive() external payable {}

    fallback() external payable {}

    ///@notice deposting ether to the contract by anyone
    function depositeFunds() public payable {}

    ///@notice propose a transaction  to confirm by other peers and execute by the caller
    ///@dev only the authorized people can call the function
    ///@param _to to whom the owner want to send funds
    ///@param _value the amount of ether owner want to send
    ///@custom:event proposalTransactionEvent is emitted at the end
    function proposalTransaction(address _to, uint256 _value) public onlyOwner {
        require(_to != address(0) && _value > 0, "arguments failed");
        uint256 _txIndex = index;
        ownerProposalIndex[msg.sender] = _txIndex;
        transactions.push(
            Transactions({
                to: _to,
                value: _value,
                executed: false,
                numConfirmations: 0
            })
        );

        index += 1;

        emit PropsalTransactionEvent(msg.sender, _to, _txIndex, _value);
    }

    ///@notice to get the owner proposal index, to easily access the structre elements
    ///@dev only owners can call this function
    ///@param _owner to get the specific transaction request of owner
    ///@param _index which returns the index of the transaction request
    function ownerProposalIndexShow(
        address _owner
    ) public view onlyOwner returns (uint256 _index) {
        _index = ownerProposalIndex[_owner];
    }

    ///@notice confirming the proposal by the peers
    ///@param _owner address of the owner to find a specific transaction
    function confirmProposalTransaction(address _owner) public onlyOwner {
        uint256 _index = ownerProposalIndexShow(_owner);
        // require(msg.sender == _owner, "you cannot approve by youself");
        require(_index < owners.length, "index out of bounds");
        require(!proposalConfirmations[_index][msg.sender], "aleardy approved");
        require(transactions[_index].to != address(0), "revoked proposal");

        transactions[_index].numConfirmations += 1;
        uint256 confirmations = transactions[_index].numConfirmations;
        proposalConfirmations[_index][msg.sender] = true;

        emit ConfirmationTransactionEvent(msg.sender, confirmations);
    }

    ///@notice executing proposed Transaction
    function executePoposalTransaction() public {
        uint256 _index = ownerProposalIndexShow(msg.sender);
        require(
            transactions[_index].numConfirmations >= minConfirmations,
            "confirmations need"
        );

        uint256 val = transactions[index].value;
        require(transactions[index].executed, "aleardy executed");
        require(val <= address(this).balance, "insufficient balance");
        payable(transactions[index].to).transfer(transactions[index].value);
    }

    ///@notice revoking the proposal of Transaction by the owner of requested transaction
    ///@dev deleted the transaction proposal from transactions array, i.e rested its values.
    function revokeProposalTransaction() public onlyOwner {
        uint256 _index = ownerProposalIndex[msg.sender];
        require(
            transactions[_index].to != address(0),
            "you didn't proposed any transaction"
        );
        require(
            !transactions[_index].executed,
            "aleardy executed you cant revoke"
        );
        delete transactions[_index];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
