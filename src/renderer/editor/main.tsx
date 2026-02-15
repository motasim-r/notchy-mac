import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { EditorApp } from "./EditorApp.js";
import "./styles/editor.css";

const container = document.getElementById("root");

if (!container) {
  throw new Error("Missing #root element for editor window");
}

createRoot(container).render(
  <StrictMode>
    <EditorApp />
  </StrictMode>,
);
