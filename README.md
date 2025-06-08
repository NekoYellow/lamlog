# ProInferre

**ProInferre** is a Prolog-like logic programming language implemented in Racket. It supports facts, rules, and queries based on term unification and backward chaining resolution. ProInferre can be used interactively via a REPL or execute a script containing logical clauses and queries.

## Features

- First-order terms: atoms, variables, and compound terms
- Facts and rules (Horn clauses)
- Query resolution using unification
- Simple substitution-based inference engine
- Knowledge base manipulation: `assertz`, `retract`, `list`
- Script execution and interactive REPL mode
- Pretty-printed query results

## Installation

1. Make sure [Racket](https://racket-lang.org/) is installed.
2. Clone this repository.
3. Run from the terminal:

```bash
racket proinf.rkt -f samples/your_script_file
```

## Usage

### REPL

Start an interactive session:

```bash
racket proinf.rkt
```

### Script Mode

Run a script file:

```bash
racket proinf.rkt -f samples/family
```

### Sample Script

```prolog
;; Facts
assertz((parent alice bob)).
assertz((parent bob carol)).

;; Rules
assertz(((grandparent X Y) :- (parent X Z) (parent Z Y))).

;; Query (interactive)
(grandparent alice Y)
```

### Output

```
ProInf REPL. Enter queries like: (grandparent X carol)
?- (grandparent alice Y)
Y = carol
```

## File Structure

* `proinf-core.rkt`: Core logic (terms, unification, resolution)
* `proinf-repl.rkt`: REPL loop
* `proinf-script.rkt`: Script file runner
* `proinf.rkt`: Main entry point
* `samples/`: Sample logic programs
