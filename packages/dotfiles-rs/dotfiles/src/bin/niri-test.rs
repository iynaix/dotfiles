use niri_ipc::{Request, Response, socket::Socket};

fn main() {
    let Ok(Response::Outputs(monitors)) = Socket::connect()
        .expect("failed to connect to niri socket")
        .send(Request::Outputs)
        .expect("failed to send Outputs request to niri")
    else {
        panic!("unexpected response from niri, should be Outputs");
    };
}
