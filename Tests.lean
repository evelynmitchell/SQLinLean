-- Test runner for SQLinLean
import SQLinLean
import Tests.TestHelpers
import Tests.LexerTests
import Tests.ParserTests
import Tests.LexerTestsExtended
import Tests.ParserTestsExtended

open SQLinLean.Tests.Lexer
open SQLinLean.Tests.LexerExtended
open SQLinLean.Tests.Parser
open SQLinLean.Tests.ParserExtended

def main : IO Unit := do
  IO.println "╔═══════════════════════════════════════╗"
  IO.println "║   SQLinLean Test Suite                ║"
  IO.println "║   (Including tests from sqlglot)      ║"
  IO.println "╚═══════════════════════════════════════╝"
  IO.println ""

  runLexerTests
  runExtendedLexerTests
  runParserTests
  runExtendedParserTests
  
  IO.println "╔═══════════════════════════════════════╗"
  IO.println "║   Test Suite Complete                 ║"
  IO.println "╚═══════════════════════════════════════╝"
