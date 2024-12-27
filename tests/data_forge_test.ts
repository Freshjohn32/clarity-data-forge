import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensure that owner can create schemas",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('data-forge', 'create-schema', [
                types.ascii("TestSchema"),
                types.list([types.ascii("field1"), types.ascii("field2")])
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        let schemaBlock = chain.mineBlock([
            Tx.contractCall('data-forge', 'get-schema', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        const schema = schemaBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(schema['name'].value, "TestSchema");
    }
});

Clarinet.test({
    name: "Ensure that permissions control data access",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // Create schema
        let block = chain.mineBlock([
            Tx.contractCall('data-forge', 'create-schema', [
                types.ascii("TestSchema"),
                types.list([types.ascii("field1")])
            ], deployer.address)
        ]);
        
        const schemaId = block.receipts[0].result.expectOk().expectUint(1);
        
        // Set permissions
        block = chain.mineBlock([
            Tx.contractCall('data-forge', 'set-permissions', [
                types.uint(schemaId),
                types.principal(user1.address),
                types.bool(true),
                types.bool(true)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Create entry
        block = chain.mineBlock([
            Tx.contractCall('data-forge', 'create-entry', [
                types.uint(schemaId),
                types.list([types.utf8("test-data")])
            ], user1.address)
        ]);
        
        block.receipts[0].result.expectOk();
    }
});