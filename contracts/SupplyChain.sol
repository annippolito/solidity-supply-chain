pragma solidity >=0.4.21 <0.6.0;

//A contract to manage a Supply Chain
contract SupplyChain {
    uint32 public product_id = 0;
    uint32 public participant_id = 0;
    uint32 public owner_id = 0;

    struct product {
        string modelNumber;
        string partNumber;
        string serialNumber;
        address productOwnerAddress;
        uint32 cost;
        uint32 manifacturedTimestamp;
    }

    mapping(uint32 => product) public products; //list of products

    struct participant {
        string username;
        string password;
        string participantType; //Manufacturer, Supplyer, Consumer
        address participantAddress;
    }

    mapping(uint32 => participant) public participants; //list of participants

    //The ownership is the relation between a product and a participant
    struct ownership {
        uint32 productId;
        uint32 ownerId;
        uint32 txTimestamp; // transaction timestamp
        address productOwnerAddress;
    }

    //this mapping is for what products currently an owner has ?
    mapping(uint32 => ownership) public ownerships; //map ownership by owner

    //this mapping is for look at the ownership history of a specific product
    mapping(uint32 => uint32[]) public productTrack; //map ownership by productId

    event TransferOwnership(uint32 indexed productId);

    //add a participant into the list giving the next id
    function addParticipant(
        string memory _username,
        string memory _password,
        address _participantAddress,
        string memory _participantType
    ) public returns (uint32) {
        uint32 userId = participant_id++;
        participants[userId].username = _username;
        participants[userId].password = _password;
        participants[userId].participantAddress = _participantAddress;
        participants[userId].participantType = _participantType;

        return userId;
    }

    //retrieve the participant by id
    function getParticipant(uint32 _participantId) public view returns (string memory, address, string memory) {
        return (
            participants[_participantId].username,
            participants[_participantId].participantAddress,
            participants[_participantId].participantType
        );
    }

    //add a new product only if the owner is a Manufaturer
    function addProduct(
        uint32 _ownerId,
        string memory _modelNumber,
        string memory _partNumber,
        string memory _serialNumber,
        uint32 _cost
    ) public returns (uint32) {
        require(
            keccak256(abi.encodePacked(participants[_ownerId].participantType)) == keccak256("Manufacturer"),
            "Only a Manufacturer can add products"
        );

        uint32 productId = product_id++;

        products[productId].modelNumber = _modelNumber;
        products[productId].partNumber = _partNumber;
        products[productId].serialNumber = _serialNumber;
        products[productId].cost = _cost;
        products[productId].productOwnerAddress = participants[_ownerId].participantAddress;
        products[productId].manifacturedTimestamp = uint32(now);

        return productId;
    }

    //retrieve the product by id
    function getProduct(uint32 _productId)
        public
        view
        returns (string memory, string memory, string memory, address, uint32, uint32)
    {
        return (
            products[_productId].modelNumber,
            products[_productId].partNumber,
            products[_productId].serialNumber,
            products[_productId].productOwnerAddress,
            products[_productId].cost,
            products[_productId].manifacturedTimestamp
        );
    }

    /*
        Moves a product along the supply chain from one owner to another
        Only the owner of the product can tranfer the ownership.
        Possible switches:
            manufacturer -> supplyer
            supplier -> supplier
            supplier -> consumer
    */
    function transferOwnershipToNewOwner(uint32 _ownerIdFrom, uint32 _ownerIdTo, uint32 _productId)
        public
        onlyOwner(_productId)
        allowedTypeSwitchesOnership(participants[_ownerIdFrom], participants[_ownerIdTo])
        returns (bool)
    {
        participant memory ownerTo = participants[_ownerIdTo];
        uint32 ownershipId = owner_id++;

        ownerships[ownershipId].productId = _productId;
        ownerships[ownershipId].productOwnerAddress = ownerTo.participantAddress;
        ownerships[ownershipId].ownerId = _ownerIdTo;
        ownerships[ownershipId].txTimestamp = uint32(now);
        products[_productId].productOwnerAddress = ownerTo.participantAddress;
        productTrack[_productId].push(ownershipId);
        emit TransferOwnership(_productId);

        return (true);
    }

    //return the product tracking -> list of all the owners that the product had in the supply chain
    function getProvenance(uint32 _productId) external view returns (uint32[] memory) {
        return productTrack[_productId];
    }

    //return the current ownership for a given ownershipId
    function getOwnership(uint32 _ownershipId) public view returns (uint32, uint32, address, uint32) {
        ownership memory o = ownerships[_ownershipId];

        return (o.productId, o.ownerId, o.productOwnerAddress, o.txTimestamp);
    }

    /*
        Validates that the participant is authoriszed within this supply chain.
        (Really simple authentication to not to use in production environment).
    */
    function authenticateParticipant(uint32 _uid, string memory _uname, string memory _pass, string memory _utype)
        public
        view
        returns (bool)
    {
        if (keccak256(abi.encodePacked(participants[_uid].participantType)) == keccak256(abi.encodePacked(_utype))) {
            if (keccak256(abi.encodePacked(participants[_uid].username)) == keccak256(abi.encodePacked(_uname))) {
                if (keccak256(abi.encodePacked(participants[_uid].password)) == keccak256(abi.encodePacked(_pass))) {
                    return (true);
                }
            }
        }

        return (false);
    }

    //MODIFIERS

    // require the sender is the current products's owner
    modifier onlyOwner(uint32 _productId) {
        require(
            msg.sender == products[_productId].productOwnerAddress,
            string(abi.encodePacked(msg.sender, " is not the product owner"))
        );
        _;
    }

    /*
        require types to change ownership from -> to:

        manufacturer -> supplyer
        supplier -> supplier
        supplier -> consumer
    */
    modifier allowedTypeSwitchesOnership(participant memory ownerFrom, participant memory ownerTo) {
        bool fromManufacturerToSupplier = keccak256(abi.encodePacked(ownerFrom.participantType))
            == keccak256("Manufacturer") && keccak256(abi.encodePacked(ownerTo.participantType)) == keccak256("Supplier");

        bool fromSupplierToSupplier = keccak256(abi.encodePacked(ownerFrom.participantType)) == keccak256("Supplier")
            && keccak256(abi.encodePacked(ownerTo.participantType)) == keccak256("Supplier");

        bool fromSupplierToConsumer = keccak256(abi.encodePacked(ownerFrom.participantType)) == keccak256("Supplier")
            && keccak256(abi.encodePacked(ownerTo.participantType)) == keccak256("Consumer");

        require(
            fromManufacturerToSupplier || fromSupplierToSupplier || fromSupplierToConsumer,
            string(
                abi.encodePacked(
                    "cannot transfer ownership between ", ownerFrom.participantType, " and ", ownerTo.participantType
                )
            )
        );
        _;
    }
}
