use niri_ipc::{Request, Response, socket::Socket};

fn main() {
    let mut socket = Socket::connect().expect("failed to connect to niri socket");

    let Ok(Response::FocusedWindow(active)) = socket
        .send(Request::FocusedWindow)
        .expect("failed to send Windows request to niri")
    else {
        panic!("unexpected response from niri, should be Outputs");
    };

    dbg!(&active);
}
