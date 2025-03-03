// Enhanced test suite
Clarinet.test({
    name: "Ensure data validation works correctly",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        // Test invalid field type
        let block = chain.mineBlock([
            Tx.contractCall('data-forge', 'create-schema', [
                types.ascii("InvalidSchema"),
                types.list([types.ascii("field1")]),
                types.list([types.ascii("invalid_type")]),
                types.list([types.bool(true)])
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectErr();
        
        // Test valid schema creation
        block = chain.mineBlock([
            Tx.contractCall('data-forge', 'create-schema', [
                types.ascii("ValidSchema"),
                types.list([types.ascii("field1")]),
                types.list([types.ascii("text")]),
                types.list([types.bool(true)])
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
    }
});

[Previous tests remain unchanged...]
