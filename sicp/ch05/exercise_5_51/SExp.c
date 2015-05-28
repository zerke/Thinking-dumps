#include "Common.h"
#include "Util.h"
#include "SExp.h"

// statically allocated objects,
// which are intended for sharing
// (to reduce runtime-allocation overhead)
SExp nilExp =
    {sexpNil, {0}};
// use `!!val` to limit the index to be one of {0,1},
// in which 0 stands for false and 1 stands for true.
SExp boolExps[2] = {
    {sexpBool, {.truthValue = 0}},
    {sexpBool, {.truthValue = 1}},
};

// internal use only, allocate and assign tag
// caller is responsible for finishing the object creation
SExp *allocWithTag(SExpTag t) {
    SExp *p = calloc(1,sizeof(SExp));
    p->tag = t;
    return p;
}

SExp *newSymbol(const char *name) {
    SExp *p = allocWithTag(sexpSymbol);
    p->fields.symbolName = allocCopyString(name);
    return p;
}

SExp *newString(const char *content) {
    SExp *p = allocWithTag(sexpString);
    p->fields.stringContent = allocCopyString(content);
    return p;
}

SExp *newInteger(long val) {
    SExp *p = allocWithTag(sexpInteger);
    p->fields.integerContent = val;
    return p;
}

SExp *newBool(char val) {
    return &boolExps[!!val];
}

// optimization: nil is assigned in static space
// so that it can be shared.
SExp *newNil() {
    return &nilExp;
}

SExp *newPair(SExp *car, SExp *cdr) {
    SExp *p = allocWithTag(sexpPair);
    p->fields.pairContent.car = car;
    p->fields.pairContent.cdr = cdr;
    return p;
}

void freeSExp(SExp *p) {
    if (!p) return;
    switch (p->tag) {
    case sexpInteger:
        break;
    case sexpSymbol:
        free(p->fields.symbolName);
        break;
    case sexpString:
        free(p->fields.stringContent);
        break;
    case sexpPair:
        freeSExp(p->fields.pairContent.car);
        freeSExp(p->fields.pairContent.cdr);
        break;
    // special cases for statically allocated objects
    case sexpNil:
        assert(p == &nilExp
               /* nil should never be allocated at run time
                */);
        return;
    case sexpBool:
        assert(p == &boolExps[0] || p == &boolExps[1]
               /* boolExp should never be allocated at run time
                */);
        return;
    }
    memset(p,0x00,sizeof(SExp));
    free(p);
}

void printPairR(FILE *f, SExp *p) {
    switch (p->tag) {
    case sexpNil:
        fputc(')', f); return;
    case sexpPair:
        fputc(' ', f);
        printSExp(f,p->fields.pairContent.car);
        printPairR(f,p->fields.pairContent.cdr);
        return;
    default:
        // TODO:
        // since for now we don't have a parser for
        // parsing improper list,
        // this part of the implementation is unconfirmed.
        fputs(" . ", f);
        printSExp(f,p);
        fputc(')', f);
        return;
    }
}

void printPairL(FILE *f, SExp *p) {
    assert(p && p->tag == sexpPair
           /* the second argument should be
            * a valid object of sexpPair
            */);
    fputc('(',f);
    printSExp(f,p->fields.pairContent.car);
    printPairR(f,p->fields.pairContent.cdr);
}

void printSExp(FILE *f, SExp *p) {
    switch (p->tag) {
    case sexpSymbol:
        // in case '%' gets accidentally handled...
        fprintf(f, "%s", p->fields.symbolName);
        break;
    case sexpString:
        fprintf(f,"\"%s\"", p->fields.stringContent);
        break;
    case sexpInteger:
        fprintf(f,"%ld", p->fields.integerContent);
        break;
    case sexpBool:
        fprintf(f,p->fields.truthValue? "#t": "#f");
        break;
    case sexpNil:
        fprintf(f, "()");
        break;
    case sexpPair:
        printPairL(f,p);
        break;
    }
}
