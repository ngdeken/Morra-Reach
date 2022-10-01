import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib(process.env);

const startingBalance = stdlib.parseCurrency(100);
const accAdam = await stdlib.newTestAccount(startingBalance);
const accBeta = await stdlib.newTestAccount(startingBalance);

const fmt = (x) => stdlib.formatCurrency(x, 4);
const getBalance = async (who) => fmt(await stdlib.balanceOf(who));
const beforeAdam = await getBalance(accAdam);
const beforeBeta = await getBalance(accBeta);

const ctcAdam = accAdam.contract(backend);
const ctcBeta = accBeta.contract(backend, ctcAdam.getInfo());

const FINGER = [0, 1, 2, 3, 4, 5];
const GUESS = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
const OUTCOME = ['Beta wins', 'Draw', 'Adam wins'];
const Player = (Who) => ({
    ...stdlib.hasRandom,
    getFinger: async () => {
        const finger = Math.floor(Math.random() * 6);
        console.log(`${Who} played ${FINGER[finger]} fingers`);
        return finger;
    },
    getGuess: async (finger) => {
        const guess = Math.floor(Math.random() * 6) + FINGER[finger];
        if ( Math.random() <= 0.01 ){
            for ( let i = 0; i < 10; i++ ){
                console.log(` ${Who} takes their sweet time sending it back...`);
                await stdlib.wait(1);
            }
        }
        console.log(`${Who} guessed ${GUESS[guess]} fingers`);
        return guess;
    },
    seeSum: (sum) => {
        console.log(`Sum of fingers: ${sum}`);
        console.log(`-------------------------`);
    },
    seeOutcome: (outcome) => {
        console.log(`${Who} saw outcome ${OUTCOME[outcome]}`);
    },
    informTimeout: () => {
        console.log(`${Who} observed a timeout`);
    },
});

await Promise.all([
    backend.Adam(ctcAdam, {
        ...Player('Adam'),
        wager: stdlib.parseCurrency(5),
    }),
    backend.Beta(ctcBeta, {
        ...Player('Beta'),
        acceptWager: (amt) => {
            console.log(`Beta accepts the wager of ${fmt(amt)}.`);
        }
    }),
]);

const afterAdam = await getBalance(accAdam);
const afterBeta = await getBalance(accBeta);

console.log(`Adam went from ${beforeAdam} to ${afterAdam}.`);
console.log(`Beta went from ${beforeBeta} to ${afterBeta}.`);
