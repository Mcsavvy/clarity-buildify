import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create new development project",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('buildify-token', 'create-project', [
                types.uint(1000), // total supply
                types.uint(100)   // price per token
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        // Verify project details
        let projectBlock = chain.mineBlock([
            Tx.contractCall('buildify-token', 'get-project', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        const project = projectBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(project['total-supply'], types.uint(1000));
        assertEquals(project['price-per-token'], types.uint(100));
    }
});

Clarinet.test({
    name: "Can invest in project",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const investor = accounts.get('wallet_1')!;
        
        // First create project
        let block = chain.mineBlock([
            Tx.contractCall('buildify-token', 'create-project', [
                types.uint(1000),
                types.uint(100)
            ], deployer.address)
        ]);
        
        // Then invest
        let investBlock = chain.mineBlock([
            Tx.contractCall('buildify-token', 'invest-in-project', [
                types.uint(1),    // project id
                types.uint(10)    // token amount
            ], investor.address)
        ]);
        
        investBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify investment
        let investmentBlock = chain.mineBlock([
            Tx.contractCall('buildify-token', 'get-investment', [
                types.uint(1),
                types.principal(investor.address)
            ], deployer.address)
        ]);
        
        const investment = investmentBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(investment['amount'], types.uint(10));
    }
});

Clarinet.test({
    name: "Can distribute profits",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        // Create project
        let block = chain.mineBlock([
            Tx.contractCall('buildify-token', 'create-project', [
                types.uint(1000),
                types.uint(100)
            ], deployer.address)
        ]);
        
        // Distribute profits
        let profitBlock = chain.mineBlock([
            Tx.contractCall('buildify-token', 'distribute-profits', [
                types.uint(1),    // project id
                types.uint(5)     // amount per token
            ], deployer.address)
        ]);
        
        profitBlock.receipts[0].result.expectOk().expectBool(true);
    }
});