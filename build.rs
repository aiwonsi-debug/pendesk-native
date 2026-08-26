use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    CxxQtBuilder::new_qml_module(
        QmlModule::new("org.pendesk.desktop")
            .qml_files(["qml/Main.qml", "qml/InkSurface.qml"]),
    )
    .qrc("resources.qrc")
    .qt_module("QuickControls2")
    .files(["src/desktop_state.rs"])
    .build();
}
