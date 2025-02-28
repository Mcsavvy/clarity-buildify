import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create new development project with valid parameters",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('buildify-token', 'create-project', [
                types.uint(1000),
                types.uint(100)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        let projectBlock = chain.mineBlock([
            Tx.contractCall('buildify-token', 'get-project', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        const project = projectBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(project['total-supply'], types.uint(1000));
        assertEquals(project['available-supply'], types.uint(1000));
        assertEquals(project['price-per-token'], types.uint(100));
    }
});

Clarinet.test({
    name: "Cannot create project with zero supply or price",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('buildify-token', 'create-project', [
                types.uint(0),
                types.uint(100)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(104);
    }
});

Clarinet.test({
    name: "Can invest in project with sufficient supply",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const investor = accounts.get('wallet_1')!;
        
        chain.mineBlock([
            Tx.contractCall('buildify-token', 'create-project', [
                types.uint(1000),
                types.uint(100)
            ], deployer.address)
        ]);
        
        let investBlock = chain.mineBlock([
            Tx.contractCall('buildify-token', 'invest-in-project', [
                types.uint(1),
                types.uint(10)
            ], investor.address)
        ]);
        
        investBlock.receipts[0].result.expectOk().expectBool(true);
        
        let projectBlock = chain.mineBlock([
            Tx.contractCall('buildify-token', 'get-project', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        const project = projectBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(project['available-supply'], types.uint(990));
    }
});

Clarinet.test({
    name: "Cannot invest more than available supply",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const investor = accounts.get('wallet_1')!;
        
        chain.mineBlock([
            Tx.contractCall('buildify-token', 'create-project', [
                types.uint(1000),
                types.uint(100)
            ], deployer.address)
        ]);
        
        let investBlock = chain.mineBlock([
            Tx.contractCall('buildify-token', 'invest-in-project', [
                types.uint(1),
                types.uint(1001)
            ], investor.address)
        ]);
        
        investBlock.receipts[0].result.expectErr().expectUint(103);
    }
});
