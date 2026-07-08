# MySQL-like Lexical & Syntactic Analyzer

A lightweight compiler front-end built with Flex and Bison that performs lexical and syntactic analysis on a subset of the MySQL language. This project was developed as part of my computer engineering coursework at CEID, University of Patras.

Features
- Lexical Analysis (Flex): Tokenizes SQL components including keywords (`SELECT`, `CREATE`, `JOIN`, etc.), identifiers, literals, and operators.
- Syntactic Analysis (Bison): Implements Backus-Naur Form (BNF) grammar rules to validate query structures and program blocks.
- Error Handling: Features robust syntax error detection with precise token recognition and line numbering for effective debugging.

Tech Stack & Concepts
- Flex (Lexical Analyzer Generator)
- Bison (Parser Generator / LALR Parser)
- C (Core implementation language)
- Theory: Automata Theory, Formal Languages, Context-Free Grammars (CFG)

Project Structure
- `lexer.l` - Flex specification file for tokenizing.
- `parser.y` - Bison specification file for grammar and parsing rules.
