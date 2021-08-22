use clap::{App, load_yaml};
// In the future:
// We can generate auto-completion files with: https://docs.rs/clap_generate/3.0.0-beta.2/clap_generate/fn.generate.html

mod server;
use crate::server::Server;

#[tokio::main]
async fn main() {
    let yaml = load_yaml!("cli.yaml");
    let matches = App::from(yaml).get_matches();
    println!("Hello, world!");
    let s = server::LanguagueToolServer::new("http://localhost:8081");
    let params = [("text", "je suis trè beau et je pense que le jour est arrivée.\n le plus bea truc est là"), ("language", "fr")];
    println!("A");
    let resp = s.check(params).await;
    match resp {
        Ok(a) => println!("Ok with: {:#?}", a),
        Err(e) => println!("Error with: {:#?}", e),
    };
    println!("B");
    //s.get_languages();
    //request_text("url", [(1, 1)]);
}
