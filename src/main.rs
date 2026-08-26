//! Native PenDesk launcher.
//! The QML scene owns presentation; Rust owns mutable desktop state and actions.

pub mod desktop_state;

use cxx_qt::casting::Upcast;
use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QQmlEngine, QUrl};
use std::pin::Pin;

fn main() {
    let mut application = QGuiApplication::new();
    let mut engine = QQmlApplicationEngine::new();

    if let Some(engine) = engine.as_mut() {
        engine.load(&QUrl::from("qrc:/qt/qml/org/pendesk/desktop/qml/Main.qml"));
    }

    if let Some(engine) = engine.as_mut() {
        let engine: Pin<&mut QQmlEngine> = engine.upcast_pin();
        engine
            .on_quit(|_| println!("PenDesk QML session requested shutdown."))
            .release();
    }

    if let Some(application) = application.as_mut() {
        application.exec();
    }
}
