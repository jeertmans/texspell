use clap::{load_yaml, App};
// In the future:
// We can generate auto-completion files with: https://docs.rs/clap_generate/3.0.0-beta.2/clap_generate/fn.generate.html

mod server;
use crate::server::Server;
use annotate_snippets::snippet::*;
use annotate_snippets::display_list::{DisplayList, FormatOptions};
use yansi_term::Colour;
use subprocess::Exec;

#[tokio::main]
async fn main() {
    let yaml = load_yaml!("cli.yaml");

    let matches = App::from(yaml).get_matches();
    let s = server::LanguagueToolServer::new("http://localhost:8081");

    if let Some(ref matches) = matches.subcommand_matches("languages") {
        if let Ok(langs) = s.get_languages().await {
            let width = match langs.iter().map(|lang| lang.code.chars().count()).max() {
                Some(width) => width,
                None => 0,
            };
            for lang in langs {
                println!(
                    "{:width$}: {}",
                    lang.code,
                    Colour::Red.paint(&lang.name),
                    width = width
                );
            }
        }
        return ();
    } else if let Some(file) = matches.value_of("INPUT") {
        println!("{}", file);
        if let Ok(v) = Exec::shell(format!("detex {}", file)).capture() {
            let text = v.stdout_str();
            let ftext = std::fs::read_to_string(file).expect("ERREUR :(");
            println!("{}", text);
            let source = text.clone();
            let params = [("text", text), ("language", "en-US".to_string())];
            let resp = s.check(params).await;
            match resp {
                Ok(a) => {
                    println!("Ok with: {:#?}", a);
                    let snippet = Snippet {
                        title: Some(Annotation {
                            label: Some("texspell found some error(s)"),
                            id: None,
                            annotation_type: AnnotationType::Error,
                        }),
                        footer: vec![],
                        slices: a
                            .iter()
                            .map(|m| Slice {
                                source: &ftext,
                                line_start: 52,
                                origin: Some("lol.tex"),
                                fold: true,
                                annotations: vec![
                                    SourceAnnotation {
                                        label: &m.message,
                                        annotation_type: AnnotationType::Error,
                                        range: (m.offset, m.offset + m.length),
                                    },
                                ],
                            })
                            .collect(),
                        opt: FormatOptions {
                            color: true,
                            ..Default::default()
                        },
                    };
                    let dl = DisplayList::from(snippet);
                    println!("{}", dl);

                }
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
