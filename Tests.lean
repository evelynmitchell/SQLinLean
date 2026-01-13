-- Test runner for SQLinLean
import SQLinLean
import Tests.LexerTests
import Tests.ParserTests

open SQLinLean.Tests

def main : IO Unit := do
  IO.println "╔═══════════════════════════════════════╗"
  IO.println "║   SQLinLean Test Suite                ║"
  IO.println "╚═══════════════════════════════════════╝"
  IO.println ""
  
  runLexerTests
  runParserTests
  
  IO.println "╔═══════════════════════════════════════╗"
  IO.println "║   Test Suite Complete                 ║"
  IO.println "╚═══════════════════════════════════════╝"
