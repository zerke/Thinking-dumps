## Defining Words

* Words to Factor is like functions / procedures to many other programming languages.
* To declare a word, one should write down its stack effect and give the code for the word.
* Stack effects can take some arbitrary names, but they are not used in the code of the word.
It is preferred to follow some convensions of naming (e.g. `str`, `obj`, `seq` ... ).

## Vocabularies

* Use `IN: <vname>` to define a vocabulary. Vocabularires work like modules or packages in
other programming languages.

* `USE: <vname>` can be used to import vocabularies one at a time
* `USING: <vname1> <vname2> ... ;` imports multiple vocabularies.

## Scripting

* To begin scripting in factor, one should setup `.factor-roots` file in his home directory.
  The file contains a list of loading paths.
  To run scripts in this repo, you should append one line to your `.factor-roots` file that
  looks like: `/path/to/thinking-dumps/seven-more-languages/ch02-factor`

* Note that `MAIN: <word>` accepts a word that has stack effect `( -- )`,
  and use it as an entry point to the program. If you do `MAIN: word1 word2`,
  it actually means `MAIN: word1` and then `word2`.
  Therefore in this case `word2` is a top level code, which executes before entering entry
  point. (This could be confusing)

* Use `IN: <vocab-name>` to specify the name of the vocabulary, note that the name needs to match
  the directory, for example, vocabulary name `day-2.do-easy.strings` should match directory
  `day-2/do-easy/strings/strings.factor`, I feel it is kind of verbose but you need to have a directory
  called `strings` and a file with basename `strings`.
  `foo.tests` seems to be an exception of this rule: there you put `foo-tests.factor` under
  the same directory of `foo.factor` but use `IN: foo.tests`.
  To see the full detail of this, search "Vocabulary loader" from Factor's builtin documents.

* For now I think the easiest way to script in Factor is to just define and use words on top level.
  As defining a new word to serve as `MAIN` just adds up boilerplate and does nothing really useful.

* Unlike working with the Listener, you need to explicitly import all necessary vocabularies.
  I personally think this could become annoying ... hope there are features that re-export multiple
  vocabularies as one

## Testing

* Use `unit-test` from `tools.test` to create unit tests
* Seems like there are some magics behind `test`: from the book we know calling `test` to
  consume `"examples"` on the stack actually performs all unit tests prefixed with `examples`.
  Let's don't investigate too much, just use the code in the book as a templete for now.

## Notes regarding exercises

* `call` can invoke quotations whose stack effect can be inferred at compile time
  while if we have some quotations pushed to the stack at runtime, we need runtime stack
  effect checkings so need to use `call(` instead. Check builtin document about `call` and `call(`
  note that `call(` looks odd and to use it you should write something like `call( stack -- effect )`.
  That is, surround stack effect descriptions by `call(` and `)`

* `find` is actually one valid implementation of `find-first`, examine its stack effect
  to get an idea about what your stack effect of `find-first` should look like.
  Note that those ellipsis doesn't seem to be necessary.
