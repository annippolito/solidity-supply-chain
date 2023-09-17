const SupplyChain = artifacts.require("SupplyChain");

contract('SupplyChain', async accounts => {
  it("should create a Participant", async () => {
    let instance = await SupplyChain.deployed();
    let participantId = await instance.addParticipant("A", "passA", "0x8B2Ada7b12E8bDac3a80Ed35458B46FcE652d582", "Manufacturer");
    let participant = await instance.participants(0);
    assert.equal("A", participant[0]);
    assert.equal("Manufacturer", participant[2]);

    participantId = await instance.addParticipant("B", "passB", "0xd295d0BF5Fb583219CB7b8AB1a3F3f5E218D0442", "Supplier");
    participant = await instance.participants(1);
    assert.equal("B", participant[0]);
    assert.equal("Supplier", participant[2]);

    participantId = await instance.addParticipant("C", "passC", "0x9c4c246bca58D3b821bFFdbdB88D60E8E2727E84", "Consumer");
    participant = await instance.participants(2);
    assert.equal("C", participant[0]);
    assert.equal("Consumer", participant[2]);
  });

  it("should return Participant details", async () => {
    let instance = await SupplyChain.deployed();
    let participantDetails = await instance.getParticipant(0);
    assert.equal("A", participantDetails[0]);
    assert.equal("Manufacturer", participantDetails[2]);

    instance = await SupplyChain.deployed();
    participantDetails = await instance.getParticipant(1);
    assert.equal("B", participantDetails[0]);
    assert.equal("Supplier", participantDetails[2]);

    instance = await SupplyChain.deployed();
    participantDetails = await instance.getParticipant(2);
    assert.equal("C", participantDetails[0]);
    assert.equal("Consumer", participantDetails[2]);

    instance = await SupplyChain.deployed();
    participantDetails = await instance.getParticipant(3);
    assert.equal("", participantDetails[0]);
    assert.equal("", participantDetails[2]);

  });

  it("should return empty details for a not found Participant", async () => {
    instance = await SupplyChain.deployed();
    let emptyParticipantDetails = await instance.getParticipant(3);

    assert.equal(emptyParticipantDetails[0], "");
    assert.equal(emptyParticipantDetails[2], "");
  });

  it("should create a Product", async () => {
    instance = await SupplyChain.deployed();
    let product = await instance.addProduct(0, "ABC", "100", "123", 11);
    let createdProduct = await instance.getProduct(0);

    assert.equal("ABC", createdProduct[0]);
    assert.equal("100", createdProduct[1]);
    assert.equal("123", createdProduct[2]);
  });

  it("should create a Product", async () => {
    instance = await SupplyChain.deployed();
    let product = await instance.addProduct(0, "ABC", "100", "123", 11);
    let createdProduct = await instance.getProduct(0);

    assert.equal("ABC", createdProduct[0]);
    assert.equal("100", createdProduct[1]);
    assert.equal("123", createdProduct[2]);
  });

  it("should raise an error when a Supplier attempt to create a Product", async () => {
    instance = await SupplyChain.deployed();
    let supplierOwnerId = 1;
    try {
      await instance.addProduct(supplierOwnerId, "DEF", "200", "444", 100);
      assert.fail("Product creation should fail");
    } catch (error) {
      assert.include(error.message, "Only a Manufacturer can add products");
    }
  });

  it("should raise an error when a Consumer attempt to create a Product", async () => {
    instance = await SupplyChain.deployed();
    let consumerOwnerId = 2;
    try {
      await instance.addProduct(consumerOwnerId, "DEF", "200", "444", 100);
      assert.fail("Product creation should fail");
    } catch (error) {
      assert.include(error.message, "Only a Manufacturer can add products");
    }
  });

  it("should transfer ownership to another participant", async () => {
    instance = await SupplyChain.deployed();
    let ownerId = 0;
    let newOwnerId = 1;
    let productId = 0;

    let success = await instance.transferOwnershipToNewOwner(ownerId, newOwnerId, productId, { from: '0x8B2Ada7b12E8bDac3a80Ed35458B46FcE652d582' });

    assert.ok(true, success);
  });

});
