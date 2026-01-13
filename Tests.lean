-- Test runner for SQLinLean
import SQLinLean
import Tests.LexerTests
import Tests.ParserTests
import Tests.LexerTestsExtended
import Tests.ParserTestsExtended

open SQLinLean.Tests

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
