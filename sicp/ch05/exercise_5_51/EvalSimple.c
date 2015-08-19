// an simple expression is one of the following:
// * self-evaluating expression
// * variable
// * quoted expression
// * lambda expression
// I guess they are "simple" in terms of
// the complexity of implementation.

#include "EvalSimple.h"
#include "FunctionObject.h"
#include "PointerManager.h"

// for simplicity, case-insensitive comparison
// is NOT implemented
char isSymbol(const char *symbol, const SExp *p) {
    return sexpSymbol == p->tag
        && 0 == strcmp(symbol, p->fields.symbolName);
}

char isSelfEvaluating(const SExp *p) {
    switch (p->tag) {
    case sexpInteger:
    case sexpString:
    case sexpBool:
        return 1;
    default:
        return 0;
    }
}

const SExp *evSelfEval(const SExp *exp, Environment *env) {
    // suppressing warning
    (void)env;
    return exp;
}

SExpHandler selfEvaluatingHandler = {
    isSelfEvaluating,
    evSelfEval };

char isVariable(const SExp *p) {
    return sexpSymbol == p->tag;
}

const SExp *evVariable(const SExp* exp, Environment *env) {
    const char *keyword = exp->fields.symbolName;
    FrameEntry *result = envLookup(env,keyword);

    // returns NULL on failure
    return result ? result->val : NULL;
}

SExpHandler variableHandler = {
    isVariable,
    evVariable
};

char isQuoted(const SExp *p) {
    return sexpPair == p->tag
        && isSymbol("quote", p->fields.pairContent.car);
}

const SExp *evQuoted(const SExp *exp, Environment *env) {
    (void)env;
    return sexpCadr(exp);
}

SExpHandler quotedHandler = {
    isQuoted,
    evQuoted
};

char isLambda(const SExp *p) {
    return sexpPair == p->tag
        && isSymbol("lambda", p->fields.pairContent.car);
}

const SExp *evLambda(const SExp *exp, Environment *env) {
    // (lambda (x y z) x x z)
    // * lambda-parameters: (x y z) -- cadr gives the parameters
    // * lambda-body: (x x z)       -- cddr gives the body
    SExp *cdr = sexpCdr(exp);
    SExp *lamParam = sexpCar(cdr);
    SExp *lamBody = sexpCdr(cdr);

    FuncObj *fo = newCompoundFunc(lamParam, lamBody, env);

    // the lambda object is allocated at runtime, and is supposed
    // to be freed when its wrapping SExp is freed.
    SExp *result = newFuncObject(fo);
    pointerManagerRegisterCustom(result,(PFreeCallback)freeSExpRec);
    return result;
}

SExpHandler lambdaHandler = {
    isLambda,
    evLambda
};
