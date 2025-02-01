import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensure that owner can create schemas with validation rules",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('data-forge', 'create-schema', [
                types.ascii("TestSchema"),
                types.list([types.ascii("email"), types.ascii("age")]),
                types.list([types.ascii("email"), types.ascii("number")]),
                types.list([types.bool(true), types.bool(false)])
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
    name: "Ensure data validation rules are enforced",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // Create schema with validation
        let block = chain.mineBlock([
            Tx.contractCall('data-forge', 'create-schema', [
                types.ascii("ValidatedSchema"),
                types.list([types.ascii("email"), types.ascii("age")]),
                types.list([types.ascii("email"), types.ascii("number")]),
                types.list([types.bool(true), types.bool(true)])
            ], deployer.address)
        ]);
        
        const schemaId = block.receipts[0].result.expectOk().expectUint(1);
        
        // Set permissions
        block = chain.mineBlock([
            Tx.contractCall('data-forge', 'set-permissions', [
                types.uint(schemaId),
                types.principal(user1.address),
                types.bool(true),
                types.bool(true),
                types.bool(false)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Test invalid email
        block = chain.mineBlock([
            Tx.contractCall('data-forge', 'create-entry', [
                types.uint(schemaId),
                types.list([types.utf8("invalid"), types.utf8("25")])
            ], user1.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(103);
        
        // Test valid data
        block = chain.mineBlock([
            Tx.contractCall('data-forge', 'create-entry', [
                types.uint(schemaId),
                types.list([types.utf8("test@example.com"), types.utf8("25")])
            ], user1.address)
        ]);
        
        block.receipts[0].result.expectOk();
    }
});

Clarinet.test({
    name: "Ensure entry verification works correctly",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const verifier = accounts.get('wallet_2')!;
        
        // Create schema
        let block = chain.mineBlock([
            Tx.contractCall('data-forge', 'create-schema', [
                types.ascii("VerifiedSchema"),
                types.list([types.ascii("field1")]),
                types.list([types.ascii("text")]),
                types.list([types.bool(true)])
            ], deployer.address)
        ]);
        
        const schemaId = block.receipts[0].result.expectOk().expectUint(1);
        
        // Set permissions for verifier
        block = chain.mineBlock([
            Tx.contractCall('data-forge', 'set-permissions', [
                types.uint(schemaId),
                types.principal(verifier.address),
                types.bool(true),
                types.bool(false),
                types.bool(true)
            ], deployer.address)
        ]);
        
        // Create entry
        block = chain.mineBlock([
            Tx.contractCall('data-forge', 'create-entry', [
                types.uint(schemaId),
                types.list([types.utf8("test-data")])
            ], deployer.address)
        ]);
        
        const entryId = block.receipts[0].result.expectOk().expectUint(1);
        
        // Verify entry
        block = chain.mineBlock([
            Tx.contractCall('data-forge', 'verify-entry', [
                types.uint(schemaId),
                types.uint(entryId)
            ], verifier.address)
        ]);
        
        block.receipts[0].result.expectOk();
    }
});
