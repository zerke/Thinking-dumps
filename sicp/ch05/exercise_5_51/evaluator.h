#ifndef _EVALUATOR_H_
#define _EVALUATOR_H_

#define SMALL_BUFFER_SIZE 512

// syntax related functions
int isLetter(char);
int isSpecialInitial(char);
int isPeculiarIdentifierInitial(char);
int isSpecialSubsequent(char);
int isInitial(char);
int isSubsequent(char);

// representing tokens
typedef enum {
    tok_eof,
    tok_lparen,
    tok_rparen,
    tok_quote,
    tok_true,
    tok_false,
    tok_string,
    tok_symbol,
    tok_integer
} TokenTag;

typedef union {
    char *string_content;
    char *symbol_name;
    long int integer_content;
} TokenFields;

typedef struct {
    TokenTag tag;
    TokenFields fields;
} Token;

// functions related to tokens
Token *mkTokenEof(void);
Token *mkTokenLParen(void);
Token *mkTokenRParen(void);
Token *mkTokenQuote(void);
Token *mkTokenTrue(void);
Token *mkTokenFalse(void);
Token *mkTokenString(const char*);
Token *mkTokenSymbol(const char*);
Token *mkTokenInteger(long int);

#endif
