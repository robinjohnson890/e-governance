pragma solidity ^0.4.24;

// Base contract that can be destroyed by owner.
import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";


contract ImageRegister is Destructible {

    struct Image {
        string ipfsHash;        // IPFS hash
        string title;           // Image title
        string description;     // Image description
        string tags;            // Image tags in comma separated format
        uint256 uploadedOn;     // Uploaded timestamp
    }

    // Maps owner to their images
    mapping (address => Image[]) public ownerToImages;

    // Used by Circuit Breaker pattern to switch contract on / off
    bool private stopped = false;

    event LogImageUploaded(
        address indexed _owner,
        string _ipfsHash,
        string _title,
        string _description,
        string _tags,
        uint256 _uploadedOn
    );

    event LogEmergencyStop(
        address indexed _owner,
        bool _stop
    );


    modifier stopInEmergency {
        require(!stopped);
        _;
    }

    function() public {}


    function uploadImage(
        string _ipfsHash,
        string _title,
        string _description,
        string _tags
    ) public stopInEmergency returns (bool _success) {

        require(bytes(_ipfsHash).length == 46);
        require(bytes(_title).length > 0 && bytes(_title).length <= 256);
        require(bytes(_description).length < 1024);
        require(bytes(_tags).length > 0 && bytes(_tags).length <= 256);

        uint256 uploadedOn = now;
        Image memory image = Image(
            _ipfsHash,
            _title,
            _description,
            _tags,
            uploadedOn
        );

        ownerToImages[msg.sender].push(image);

        emit LogImageUploaded(
            msg.sender,
            _ipfsHash,
            _title,
            _description,
            _tags,
            uploadedOn
        );

        _success = true;
    }


    function getImageCount(address _owner)
        public view
        stopInEmergency
        returns (uint256)
    {
        require(_owner != 0x0);
        return ownerToImages[_owner].length;
    }


    function getImage(address _owner, uint8 _index)
        public stopInEmergency view returns (
        string _ipfsHash,
        string _title,
        string _description,
        string _tags,
        uint256 _uploadedOn
    ) {

        require(_owner != 0x0);
        require(_index >= 0 && _index <= 2**8 - 1);
        require(ownerToImages[_owner].length > 0);

        Image storage image = ownerToImages[_owner][_index];

        return (
            image.ipfsHash,
            image.title,
            image.description,
            image.tags,
            image.uploadedOn
        );
    }

    function emergencyStop(bool _stop) public onlyOwner {
        stopped = _stop;
        emit LogEmergencyStop(owner, _stop);
    }
}
