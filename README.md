# ReentrancyDataset

### all_smart_contracts
All open-source smart contracts that we have collected.

### deduplicated_smart_contracts
The deduplicated smart contracts.

### reentrant_contracts
The reentrant contracts (code) with labels.

### tools_output
The output of analysis tools (oyente, mythril, securify1, securify2, smartian).

### contract_information.csv
The reentrant labels of deduplicated smart contracts.

In 'true positive' column:
```
1 means the contract is manually verified to true reentrant contract.
0 means the contract is manually verified to false reentrant contract.
N/A means the contract does not be successfully analyzed by any tool.
```

In the column of tools (oyente, mythril, securify1, securify2, smartian):
```
1 means the contract is reported to reentrant contract by the tool.
0 means the contract is not reported to reentrant contract by the tool.
N/A means the contract does not be successfully analyzed by the tool.
```