# ProInferre

**ProInferre** is a Prolog-like logic programming language implemented in Racket. It supports facts, rules, and queries based on term unification and backward chaining resolution. ProInferre can be used interactively via a REPL or execute a script containing logical clauses and queries.

## Features

- Script execution and interactive REPL mode
- First-order terms: atoms, variables, and compound terms
- Facts and rules (Horn clauses)
- Query resolution using unification
- Simple substitution-based inference engine
- Knowledge base manipulation (REPL): `assertz`, `retract`, `list`
- Pretty-printed query results

## Installation

1. Make sure [Racket](https://racket-lang.org/) is installed.
2. Clone this repository.
3. Run from the terminal:

```sh
racket proinf.rkt -f samples/script_file
```

## Usage

### Script Mode

#### Syntax

The script file should contain a sequence of ProInferre commands, each on a separate line.

Each line is either one of the following:
- A fact: `(<relation> <atom1> <atom2> ...).`.
- A rule: `(<new-fact> :- <fact1> <fact2> ...).`.
- A query: `(<relation> <param1> <param2> ...)?`, in which `<param>` is either a variable (`var`) or a constant (`atom`).
- A comment: `;; <comment>`.
- A blank line.

There are certain restrictions of the naming of variables and constants:
- Variables must start with a lowercase letter.
- Constants must be a single uppercase letter.

Run a script file:

```sh
racket proinf.rkt -f samples/script_file
```

A REPL will start afterwards with the knowledge base loaded from the script. To avoid this, use the `-t` or `--test` flag:

```sh
racket proinf.rkt -f samples/script_file -t
```

#### Example

To get familiar with the syntax, let's look at the `ancestor` script:

```
;; Facts
(parent alice bob).
(parent bob carol).
(parent carol dave).

;; Rules
((ancestor X Y) :- (parent X Y)).
((ancestor X Y) :- (parent X Z) (ancestor Z Y)).

;; Queries
(ancestor alice dave)?
(ancestor dave alice)?
(ancestor bob X)?
```

This script defines a rule for determining if one person is an ancestor of another. It contains facts and queries to test the `ancestor` rule.
- `(parent alice bob).` is a fact that Alice is the parent of Bob.
- `(ancestor X Y) :- (parent X Y)).` is a rule that if X is the parent of Y, then X is an ancestor of Y.
- `(ancestor X Y) :- (parent X Z) (ancestor Z Y)).` is another rule that if X is the parent of Z and Z is an ancestor of Y, then X is an ancestor of Y. Combined, these two rules form a chain that can be used to determine if one person is an ancestor of another.
- `(ancestor alice dave)?` is a query that asks if Alice is an ancestor of Dave.
- `(ancestor bob X)?` is a query that asks if Bob is an ancestor of any person.

The facts and rules together form a knowledge base. The query will be answered in two aspects:
1. Whether the query can be inferred from the knowledge base (`true`) or not (`false`).
2. The inferred facts matching the query.

Therefore, the output of the script will be:
```sh
$ racket proinf.rkt -f samples/ancestor -t
true.
(ancestor alice dave)
false.
true.
(ancestor bob carol)
(ancestor bob dave)
Executed 10 of 10 lines from samples/ancestor
```

### REPL

REPL allows you to interactively manipulate and query the knowledge base.

Start an interactive session with `racket proinf.rkt` and you will see the following prompt:

```sh
$ racket proinf.rkt
ProInf REPL. Enter queries like: (grandparent X carol)?
To add a fact: assertz((parent alice bob)).
To add a rule: assertz(((grandparent X Y) :- (parent X Z) (parent Z Y))).
To remove a clause: retract((parent alice bob)).
To list all clauses: list.
To exit: exit.

?-
```

## File Structure

* `proinf-core.rkt`: Core logic (terms, unification, resolution)
* `proinf-repl.rkt`: REPL loop
* `proinf-script.rkt`: Script file runner
* `proinf.rkt`: Main entry point
* `samples/`: Sample logic programs
