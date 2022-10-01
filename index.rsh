'reach 0.1';

const [ isFinger, ZERO, ONE, TWO, THREE, FOUR, FIVE ] = makeEnum(6);
const [ isGuess, ZEROG, ONEG, TWOG, THREEG, FOURG, FIVEG, SIXG, SEVENG, EIGHTG, NINEG, TENG ] = makeEnum(11);
const [ isOutcome, B_WINS, DRAW, A_WINS ] = makeEnum(3);


const winner = (fingerAdam, fingerBeta, guessAdam, guessBeta) => {
    const sumAB = fingerAdam + fingerBeta;
    if ( guessAdam == guessBeta )
    {
        const coutcome = DRAW;
        return coutcome;
    }   else if( (sumAB) == guessAdam ){
        const coutcome = A_WINS;
        return coutcome;
    }   else if( (sumAB) == guessBeta ){
        const coutcome = B_WINS;
        return coutcome;
    }   else{
        const coutcome = DRAW;
        return coutcome;
    }
};

assert(winner(ZERO, FIVE, ONEG, FIVEG) == B_WINS);
assert(winner(FIVE, ZERO, FIVEG, ONEG) == A_WINS);
assert(winner(ONE, TWO, FOURG, FIVEG) == DRAW);
assert(winner(FIVE, FIVE, FIVEG, FIVEG) == DRAW);

forall(UInt, fingerAdam =>
    forall(UInt, fingerBeta =>
        forall(UInt, guessAdam =>
            forall(UInt, guessBeta =>
                assert(isOutcome(winner(fingerAdam, fingerBeta, guessAdam, guessBeta)))))));

forall(UInt, (fingerAdam) => 
    forall(UInt, (fingerBeta) =>
        forall(UInt, (guess) =>
            assert(winner(fingerAdam, fingerBeta, guess, guess) == DRAW))));


const Player = {
    ...hasRandom,
    getFinger: Fun([] ,UInt),
    getGuess: Fun([UInt], UInt),
    seeSum : Fun([UInt], Null),
    seeOutcome: Fun([UInt], Null),
    informTimeout: Fun([], Null),
};

const deadline = 20;

export const main = Reach.App(() => {
    const Adam = Participant('Adam', {
        ...Player,
        wager: UInt,
        
    });
    const Beta = Participant('Beta', {
        ...Player,
        acceptWager: Fun([UInt], Null),
    });
    init();

    const informTimeout = () => {
        each([Adam, Beta], () => {
            interact.informTimeout();
        });
    };

    Adam.only(() => {
        const wager = declassify(interact.wager);
    });
    Adam.publish(wager)
        .pay(wager);
    
    commit();

    Beta.only(() => {
        interact.acceptWager(wager);
    });
    Beta.pay(wager)
        .timeout(relativeTime(deadline), () => closeTo(Adam, informTimeout));

    var outcome = DRAW;
    invariant(balance() == 2 * wager && isOutcome(outcome) );
    while ( outcome == DRAW ){
        commit();
        Adam.only(() => {
            const _fingerAdam = interact.getFinger();
            const _guessAdam = interact.getGuess(_fingerAdam);
            const [_commitAdam, _saltAdam] = makeCommitment(interact, _fingerAdam);
            const commitAdam = declassify(_commitAdam);
            const [_commitAdamG, _saltAdamG] = makeCommitment(interact, _guessAdam);
            const commitAdamG = declassify(_commitAdamG);
            
    });

        Adam.publish(commitAdam)
            .timeout(relativeTime(deadline), () => closeTo(Beta, informTimeout));
        commit();

        Adam.publish(commitAdamG)
            .timeout(relativeTime(deadline), () => closeTo(Beta, informTimeout));
        commit();

        unknowable(Beta, Adam(_fingerAdam, _saltAdam));
        unknowable(Beta, Adam(_guessAdam, _saltAdamG));

        Beta.only(() => {
            const _fingerBeta = interact.getFinger();
            const _guessBeta = (interact.getGuess(_fingerBeta));
            const fingerBeta = declassify(_fingerBeta);
            const guessBeta = declassify(_guessBeta);
        });

        Beta.publish(fingerBeta)
            .timeout(relativeTime(deadline), () => closeTo(Adam, informTimeout));
        commit();
        Beta.publish(guessBeta)
            .timeout(relativeTime(deadline), () => closeTo(Adam, informTimeout));
        commit();

        Adam.only(() => {
            const [saltAdam, fingerAdam] = declassify([_saltAdam, _fingerAdam]);
            const [saltAdamG, guessAdam] = declassify([_saltAdamG, _guessAdam]);
        });

        Adam.publish(saltAdam, fingerAdam)
            .timeout(relativeTime(deadline), () => closeTo(Adam, informTimeout));
        checkCommitment(commitAdam, saltAdam, fingerAdam);
        commit();

        Adam.publish(saltAdamG, guessAdam)
            .timeout(relativeTime(deadline), () => closeTo(Adam, informTimeout));
        checkCommitment(commitAdamG, saltAdamG, guessAdam);
        
        commit();

        Adam.only(() => {
            const sum = fingerAdam + fingerBeta;
            interact.seeSum(sum);
        });

        Adam.publish(sum)
            .timeout(relativeTime(deadline), () => closeTo(Adam, informTimeout));

        outcome = winner(fingerAdam, fingerBeta, guessAdam, guessBeta);
        continue;
    }
       
    assert( outcome == A_WINS || outcome == B_WINS );
    transfer(2 * wager).to(outcome == A_WINS ? Adam : Beta);
    commit();

    each([Adam, Beta], () => {
        interact.seeOutcome(outcome);
    });

});
