use clap::{App, load_yaml};
// In the future:
// We can generate auto-completion files with: https://docs.rs/clap_generate/3.0.0-beta.2/clap_generate/fn.generate.html

fn main() {
    let yaml = load_yaml!("cli.yaml");
    let matches = App::from(yaml).get_matches();
    println!("Hello, world!");
}
