import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { PrompterBar } from "./PrompterBar.js";
import "./styles/prompter.css";

const container = document.getElementById("root");

if (!container) {
  throw new Error("Missing #root element for prompter window");
}

createRoot(container).render(
  <StrictMode>
    <PrompterBar />
  </StrictMode>,
);
