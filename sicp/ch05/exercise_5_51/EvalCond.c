#include "Machine.h"

void evIf(const SExp *exp, Machine *m) {
    SExp *expPred = sexpCadr(exp);
    SExp *expRemaining = sexpCddr(exp);
    SExp *expConseq = sexpCar(expRemaining);
    SExp *expAlter = sexpCadr(expRemaining);

    evalDispatch(expPred,m);
    assert( regBool == m->val.tag );
    char val = m->val.data.truthValue;
    evalDispatch( val
                  ? expConseq
                  : expAlter, m);
}
