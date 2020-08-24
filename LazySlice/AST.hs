module LazySlice.AST where

data Expr
    = App Expr Expr
    | Hole
    | Lam String Expr
    | Pi String Expr Expr
    | Sigma String Expr Expr
    | Univ
    | Var String
    deriving Show

data Decl
    = Declare String Expr
    | Define String Expr
    deriving Show

data Module = Module [Decl]