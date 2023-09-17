# solidity-supply-chain
My first solidity supply chain

A supply chain built on the etherium blockchain to manage steps ongoing between all the participants.
With the blockchain you can track the provenance of each product and see who were the owners at each step from the manufacturer to the consumers.

## Participants: 
*Manufaturer*, *Supplier*, *Consumer*

- Manufacturer: is the only one can add a new product on the chain.
- Supplier: will became owner in intermediate steps to support the delivery.
- Consumer: is the final customer, where the supply chain ends, so he can't tranfer ownership.

## Rules for transfer ownership beetween participants:
- manufacturer -> supplyer
- supplier -> supplier
- supplier -> consumer

## Api:
- getProvenance() -> return the product tracking
- transferOwnershipToNewOwner() -> only the owwner can transfer ownership following the mentioned rules
- getOwnership() -> return the current ownership
- addProduct() -> add new product to the chain
- getProduct() -> return product details
- addParticipant() -> add new actor
- getParticipant() -> return participant details
