// [Previous test content remains, adding new tests...]

Clarinet.test({
    name: "Ensure schema versioning works correctly",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        // Create initial schema
        let block = chain.mineBlock([
            Tx.contractCall('data-forge', 'create-schema', [
                types.ascii("VersionedSchema"),
                types.list([types.ascii("field1")]),
                types.list([types.ascii("text")]),
                types.list([types.bool(true)])
            ], deployer.address)
        ]);
        
        const initialSchemaId = block.receipts[0].result.expectOk().expectUint(1);
        
        // Create new version
        block = chain.mineBlock([
            Tx.contractCall('data-forge', 'create-schema-version', [
                types.uint(initialSchemaId),
                types.list([types.ascii("field1"), types.ascii("field2")]),
                types.list([types.ascii("text"), types.ascii("number")]),
                types.list([types.bool(true), types.bool(false)])
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
    }
});

// [Additional tests for batch operations and queries...]
