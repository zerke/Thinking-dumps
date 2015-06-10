#include "Common.h"

#ifndef _JAVEV_SEXP_H_
#define _JAVEV_SEXP_H_

typedef enum {
    sexpSymbol,
    sexpString,
    sexpInteger,
    sexpBool,
    sexpNil,
    sexpPair,
} SExpTag;

// for breaking circular definition,
// make compiler aware of it.
struct SExp;

typedef struct {
    struct SExp *car;
    struct SExp *cdr;
} PairContent;

typedef union {
    char *symbolName;
    char *stringContent;
    long integerContent;
    char truthValue;
    PairContent pairContent;
} SExpFields;

typedef struct SExp {
    SExpTag tag;
    SExpFields fields;
} SExp;

SExp *newSymbol(const char *);
SExp *newString(const char *);
SExp *newInteger(long);
SExp *newBool(char);
SExp *newNil();
SExp *newPair(SExp *, SExp *);
void freeSExp(SExp *);
void printSExp(FILE *, SExp *);

#endif