use logos::Logos;

#[derive(Logos, Debug, PartialEq)]
pub enum Token {

    #[token(r"\begin")]
    Begin,

    #[token(r"\end")]
    End,

    #[token("{")]
    LeftCurlyBrace,
    
    #[token("}")]
    RightCurlyBrace,

    #[token(r"\n")]
    EndLine,

    #[token(r"\")]
    Backslash,


    #[token("%")]
    Percent,

    #[error]
    Error,
}
