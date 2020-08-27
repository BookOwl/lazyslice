{-# LANGUAGE FlexibleContexts, FunctionalDependencies, GeneralizedNewtypeDeriving #-}
module LazySlice.Syntax where

import Control.Monad.Trans.Reader (Reader)
import Data.Map (Map)

-- | http://www.cse.chalmers.se/~abela/msfp08.pdf is a good guide.
--  http://www.davidchristiansen.dk/tutorials/nbe/ presents similar code in Racket.

data Module = Module
    { decls :: [Decl] }
    deriving Show

data Decl
    = Data String [(String, Term)]
    | Declare String Term
    | Define String Term
    deriving Show

data Pattern
    = ConPat String [Pattern]
    | VarPat Int

-- | https://jesper.sikanda.be/files/elaborating-dependent-copattern-matching.pdf
data CaseTree
    = Leaf Term
    | Intro Int CaseTree -- ^ Introduce next parameter
    | Split Int [(String, Maybe [Int], CaseTree)]
    -- var, ^ (C, var1..varN, rhs)

data Term
    = App Term Term
    | Cont Int -- ^ Continuations use a separate De Bruijn index from the variables, counted inside-out by the effect handlers.
    | Def String -- ^ A global definition.
    | Lam (Maybe Term) Term
    | Pair Term Term
    | Pi Term Term
    | Raise String
    | Sigma Term Term
    | Triv
    | Try Term
    | Unit
    | Universe
    | Var Int -- ^ A variable is a De Bruijn index (which counts from the inside-out).
    deriving Show

data Def = Term Term | Head Head | Undef

data Table = Table
    { datacons :: Map String ([Val], String, [Val]) -- ^ (Telescope, Typecon, Type arguments)
    , datatypes :: Map String [(String, [Val], [Val])]
    , defs :: Map String (Whnf, Def) }

type ContTy = (Reader (Table, Int)) (Either String Whnf)

data Head
    = DataCon String
    | FreeVar Int
    | TypeCon String
    deriving (Eq, Show)

-- | Weak head normal forms.
data Whnf
    = WCont (Either String Whnf -> ContTy)
    | WNeu Head [Val] -- head, spine
    | WLam (Maybe Val) Abs
    | WPair Val Val
    | WPi Val Abs
    | WSigma Val Abs
    | WTriv
    | WUnit
    | WUniverse

instance Show Whnf where
    show (WCont _) = "<cont>"
    show (WNeu hd spine) =
        "(" ++ show hd ++ " " ++ show spine ++ ")"
    show (WLam m a) =
        "(lam " ++ show m ++ " " ++ show a ++ ")"
    show (WPair a b) =
        "(tuple " ++ show a ++ " " ++ show b ++ ")"
    show (WPi a b) =
        "(pi " ++ show a ++ " " ++ show b ++ ")"
    show (WSigma a b) =
        "(sigma " ++ show a ++ " " ++ show b ++ ")"
    show WTriv = "trivial"
    show WUnit = "unit"
    show WUniverse = "type"

-- | The environment of values.
type Env = [Binding]

-- | The environment of continuations.
type Conts = [Either String Whnf -> ContTy]

data Binding
    = Val Val
    | Free Int -- ^ A free variable is not a De Bruijn index, and it counts from the outside in.
    deriving Show

-- | A handler catches an effect.
type Handler = String -> Maybe Term

data Val = Clos Env Conts Handler Term

instance Show Val where
    show (Clos env _ _ term) =
        "(clos " ++ show env ++ " " ++ show term ++ ")"

data Abs = Abs Env Term

instance Show Abs where
    show (Abs env term) =
        "(abstr " ++ show env ++ " " ++ show term ++ ")"
