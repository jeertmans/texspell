use clap::{load_yaml, App};
// In the future:
// We can generate auto-completion files with: https://docs.rs/clap_generate/3.0.0-beta.2/clap_generate/fn.generate.html

mod server;
use crate::server::Server;
use subprocess::Exec;

#[tokio::main]
async fn main() {
    let yaml = load_yaml!("cli.yaml");

    let matches = App::from(yaml).get_matches();
    let s = server::LanguagueToolServer::new("http://localhost:8081");

    if let Some(ref matches) = matches.subcommand_matches("languages") {
        if let Ok(langs) = s.get_languages().await {
            for lang in langs {
                println!("{}: {}", lang.code, lang.name);
            }
        }
        return ();
    } else if let Some(file) = matches.value_of("INPUT") {
        println!("{}", file);
        if let Ok(v) = Exec::shell(format!("detex {}", file)).capture() {
            let text = v.stdout_str();
            println!("{}", text);
            let params = [("text", text), ("language", "en-US".to_string())];
            let resp = s.check(params).await;
            match resp {
                Ok(a) => println!("Ok with: {:#?}", a),
                Err(e) => println!("Error with: {:#?}", e),
            };
        }
    }

    let params = [
        (
            "text",
            "je suis trè beau et je pense que le jour est arrivée.\n le plus bea truc est là",
        ),
        ("language", "fr"),
    ];
    /*
    println!("A");
    let resp = s.check(params).await;
    match resp {
        Ok(a) => println!("Ok with: {:#?}", a),
        Err(e) => println!("Error with: {:#?}", e),
    };
    println!("B");
    let resp = s.get_languages().await;
    match resp {
        Ok(a) => println!("Ok with: {:#?}", a),
        Err(e) => println!("Error with: {:#?}", e),
    };
    //request_text("url", [(1, 1)]);
    */
}
