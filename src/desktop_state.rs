//! Rust-owned state exposed to QML as a generated QObject.
//! Keep persistence, X11 services, files, and tablet integrations behind this boundary.

use core::pin::Pin;
use cxx_qt_lib::QString;

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(QString, workspace)]
        #[qproperty(QString, selected_tool)]
        #[qproperty(bool, palm_rest)]
        #[qproperty(i32, committed_strokes)]
        type DesktopState = super::DesktopStateRust;

        #[qinvokable]
        #[cxx_name = "activateWorkspace"]
        fn activate_workspace(self: Pin<&mut Self>, workspace: &QString);

        #[qinvokable]
        #[cxx_name = "selectTool"]
        fn select_tool(self: Pin<&mut Self>, tool: &QString);

        #[qinvokable]
        #[cxx_name = "togglePalmRest"]
        fn toggle_palm_rest(self: Pin<&mut Self>);

        #[qinvokable]
        #[cxx_name = "commitPreviewStroke"]
        fn commit_preview_stroke(self: Pin<&mut Self>, sample_count: i32);
    }
}

pub struct DesktopStateRust {
    workspace: QString,
    selected_tool: QString,
    palm_rest: bool,
    committed_strokes: i32,
}

impl Default for DesktopStateRust {
    fn default() -> Self {
        Self {
            workspace: QString::from(
                match std::env::var("PENDESK_START_WORKSPACE").as_deref() {
                    Ok("browse") => "browse",
                    Ok("worksheets") => "worksheets",
                    Ok("clipart") => "clipart",
                    _ => "daily",
                },
            ),
            selected_tool: QString::from("pen"),
            palm_rest: true,
            committed_strokes: 0,
        }
    }
}

impl qobject::DesktopState {
    fn activate_workspace(mut self: Pin<&mut Self>, workspace: &QString) {
        self.as_mut().set_workspace(workspace.clone());
        println!("Workspace changed to {workspace}");
    }

    fn select_tool(mut self: Pin<&mut Self>, tool: &QString) {
        self.as_mut().set_selected_tool(tool.clone());
        println!("Stylus tool selected: {tool}");
    }

    fn toggle_palm_rest(mut self: Pin<&mut Self>) {
        let next = !*self.palm_rest();
        self.as_mut().set_palm_rest(next);
        println!("Palm rest: {next}");
    }

    fn commit_preview_stroke(mut self: Pin<&mut Self>, sample_count: i32) {
        let committed = *self.committed_strokes() + 1;
        self.as_mut().set_committed_strokes(committed);
        println!("Committed preview stroke {committed} with {sample_count} samples.");
    }
}
