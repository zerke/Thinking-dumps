#ifndef _JAVEV_EVALSETDEFINE_H_
#define _JAVEV_EVALSETDEFINE_H_

#include "Machine.h"
#include "EvalSimple.h"

char isAssignment(const SExp *);
const SExp *evAssignment(const SExp *, Environment *);
char isDefinition(const SExp *);
const SExp *evDefinition(const SExp *, Environment *);

SExpHandler assignmentHandler;
SExpHandler definitionHandler;

#endif