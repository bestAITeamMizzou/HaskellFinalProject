{-# OPTIONS_GHC -fwarn-missing-signatures #-}
{-# OPTIONS_GHC -fno-warn-tabs #-}
module Final where

import Prelude hiding (LT, GT, EQ)
import System.IO
import Base
import Data.Maybe
import Data.List
import Operators
import RecursiveFunctionsAST
import RecursiveFunctionsParse
import Test.Hspec
import Control.Exception (evaluate, AsyncException(..))
-- Uncomment the following if you choose to do Problem 3.
{-
import System.Environment
import System.Directory (doesFileExist)
import System.Process
import System.Exit
import System.Console.Haskeline
--        ^^ This requires installing haskeline: cabal update && cabal install haskeline
-}

--
-- The parsing function, parseExp :: String -> Exp, is defined for you.
--

facvar   = parseExp ("var fac = function(n) { if (n==0) 1 else n * fac(n-1) };" ++
                   "fac(5)")

facrec   = parseExp ("rec fac = function(n) { if (n==0) 1 else n * fac(n-1) };" ++
                   "fac(5)")

exp1     = parseExp "var a = 3; var b = 8; var a = b, b = a; a + b"
exp2     = parseExp "var a = 3; var b = 8; var a = b; var b = a; a + b"
exp3     = parseExp "var a = 2, b = 7; (var m = 5 * a, n = b - 1; a * n + b / m) + a"
exp4     = parseExp "var a = 2, b = 7; (var m = 5 * a, n = m - 1; a * n + b / m) + a"         
-- N.b.,                                                  ^^^ is a free occurence of m (by Rule 2)

-----------------
-- The evaluation function for the recursive function language.
-----------------

eval :: Exp -> Env -> Value
eval (Literal v) env                = v
eval (Unary op a) env               = unary  op (eval a env)
eval (Binary op a b) env            = binary op (eval a env) (eval b env)
eval (If a b c) env                 = let BoolV test = eval a env
                                      in if test then  eval b env else eval c env
eval (Variable x) env               = fromJust x (lookup x env)
  where fromJust x (Just v)         = v
        fromJust x Nothing          = errorWithoutStackTrace ("Variable " ++ x ++ " unbound!")
eval (Function x body) env          = ClosureV x body env
-----------------------------------------------------------------
eval (Declare [(x,exp)] body) env   = eval body newEnv         -- This clause needs to be changed.
    where newEnv = (x, eval exp env) : env                       
--pattern matching for list of tuples found at https://stackoverflow.com/a/20251280
eval (Declare ((x,exp):xs) body) env = eval body newEnv--(Declare xs body) newEnv
    where newEnv = (go ((x, exp):xs) env []) ++ env
            where go ((y,nExp):[]) oldEnv tempEnv = (y, eval nExp oldEnv) : tempEnv --errorWithoutStackTrace("1 - oEnv: " ++ show(oldEnv) ++ "\ntEnv: " ++ show(tempEnv) ++ "\n")
                  go ((y,nExp):ys) oldEnv tempEnv = go ys oldEnv ((y, eval nExp oldEnv) : tempEnv)
                  go [] oldEnv tempEnv            = errorWithoutStackTrace("How'd this happen?\nEnv: " ++ show(oldEnv))
    {--where newEnv = (boundScopeEnv ((x, exp):xs) env) ++ env    --
            where boundScopeEnv [] env = []
                  boundScopeEnv ((x, exp):exps) env = (x, eval exp env):(boundScopeEnv exps env)--}
-----------------------------------------------------------------
eval (RecDeclare x exp body) env    = eval body newEnv
  where newEnv = (x, eval exp newEnv) : env
eval (Call fun arg) env = eval body newEnv
  where ClosureV x body closeEnv    = eval fun env
        newEnv = (x, eval arg env) : closeEnv

-- Use this function to run your eval solution.
execute :: Exp -> Value
execute exp = eval exp []
-- Example usage: execute exp1

{-

Hint: it may help to remember that:
   map :: (a -> b) -> [a] -> [b]
   concat :: [[a]] -> [a]
when doing the Declare case.

-}

freeByRule1 :: [String] -> Exp -> [String]
freeByRule1 = undefined

freeByRule2 :: [String] -> Exp -> [String]
freeByRule2 = undefined

---- Problem 3.

repl :: IO ()
repl = do
         putStr "RecFun> "
         iline <- getLine
         process iline

process :: String -> IO ()
process "quit" = return ()
process iline  = do
  putStrLn (show v ++ "\n")
  repl
   where e = parseExp iline
         v = eval e []


------------------------------------
--          Testing               --
------------------------------------

test_probs :: IO()
test_probs = do
  test_prob1

test_prob1 :: IO()
test_prob1 = hspec $ do
  describe "eval Declare..." $ do
    context "when provided with a list containing single declaration and a body" $ do
      it "returns a Value" $ do
        execute exp2 `shouldBe` IntV 16
    context "when provided with a list containing multiple declarations and a body" $ do
      it "returns a Value" $ do
        execute exp1 `shouldBe` IntV 11
      it "returns a Value" $ do
        execute exp3 `shouldBe` IntV 14
    context "when provided with a Declaration expression containing free variables" $ do
      it "throws an exception" $ do
        evaluate(execute exp4) `shouldThrow` anyException